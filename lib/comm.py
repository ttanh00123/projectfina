from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional
from datetime import date
import pyodbc
from lib.graphmaker import create_dash_app
from starlette.middleware.wsgi import WSGIMiddleware
from lib.auth_service import router as auth_router
app = FastAPI()

# Mount auth router
app.include_router(auth_router)

# Create and mount Dash app
dash_app = create_dash_app(prefix="/dashboard")  # Mount Dash app at /dashboard
app.mount("/dashboard", WSGIMiddleware(dash_app.server))


origins = ['*']

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Database connection
server = 'tcp:taexpense.database.windows.net'
database = 'TAExpense'
username = 'ttanh'
password = 'Bitbo123@'
driver = '{ODBC Driver 18 for SQL Server}'

def get_conn():
    return pyodbc.connect(
    f'DRIVER={driver};SERVER={server};PORT=1433;DATABASE={database};UID={username};PWD={password}'
)


class Transaction(BaseModel):
    content: str
    currency: str
    amount: float
    type: str
    date: Optional[str] = None
    category: str
    tags: str
    notes: Optional[str] = None
    user_id: int

@app.post("/addTransaction")
async def add_transaction(transaction: Transaction):
    try:
        conn = get_conn()
        cursor = conn.cursor()
        # Fill optional fields with defaults if missing
        tx_date = transaction.date
        if not tx_date:
            tx_date = date.today().isoformat()
        if tx_date == 'null':
            tx_date = date.today().isoformat()
        tx_notes = transaction.notes
        if tx_notes is None:
            tx_notes = 'None'

        print(transaction)
        cursor.execute('''
            INSERT INTO transactions (content, currency, amount, type, date, category, tags, notes, userid)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', transaction.content, transaction.currency, transaction.amount, transaction.type, tx_date, transaction.category, transaction.tags, tx_notes, transaction.user_id)
        conn.commit()
        return {"message": "Transaction added successfully"}
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/transactions")
async def get_transactions(user_id: int):
    try:
        conn = get_conn()
        cursor = conn.cursor()
        print(user_id)
        # Ensure the parameter is bound correctly
        cursor.execute('SELECT * FROM dbo.transactions WHERE userid = ?', (user_id,))
        rows = cursor.fetchall()
        transactions = []
        for row in rows:
            transactions.append({
                "id": row[0],
                "content": row[1],
                "currency": row[2],
                "amount": row[3],
                "type": row[4],
                "date": row[5],
                "category": row[6],
                "tags": row[7],
                "notes": row[8],
                "user_id": row[9] if len(row) > 9 else None
            })
        return transactions
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# Delete function to remove selected transaction
@app.delete("/deleteTransaction/{transaction_id}")
async def delete_transaction(transaction_id: int):
    try:
        conn = get_conn()
        cursor = conn.cursor()
        cursor.execute('DELETE FROM transactions WHERE id = ?', transaction_id)
        conn.commit()
        if cursor.rowcount == 0:
            raise HTTPException(status_code=404, detail="Transaction not found")
        return {"message": "Transaction deleted successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# Endpoint to serve Plotly figure as JSON
@app.get("/plotly-json")
async def get_plotly_json():
    return dash_app.plotly_fig.to_dict()

# Example additional endpoint (for demonstration)
@app.get("/health")
async def health_check():
    return {"status": "healthy"}

@app.get("/")
async def read_root():
    return {"message": "Welcome to the TA Expense API"}

