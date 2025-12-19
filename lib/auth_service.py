"""
Auth service for the app.

Requires SQL table (SQL Server example):

CREATE TABLE users (
    id INT IDENTITY PRIMARY KEY,
    email NVARCHAR(255) UNIQUE NOT NULL,
    password_hash NVARCHAR(255) NULL,
    display_name NVARCHAR(255) NULL,
    provider NVARCHAR(50) NOT NULL DEFAULT 'local',
    provider_id NVARCHAR(255) NULL,
    otp_code NVARCHAR(10) NULL,
    otp_expires_at DATETIME NULL,
    created_at DATETIME NOT NULL DEFAULT GETDATE(),
    updated_at DATETIME NOT NULL DEFAULT GETDATE()
);

Environment variables expected:
- AUTH_JWT_SECRET (required)
- AUTH_JWT_EXPIRES_MINUTES (optional, default 60)
- OAUTH_GOOGLE_CLIENT_ID / OAUTH_GOOGLE_CLIENT_SECRET (optional, if enabling Google OAuth)
- OAUTH_FACEBOOK_CLIENT_ID / OAUTH_FACEBOOK_CLIENT_SECRET (optional, if enabling Facebook OAuth)
- SMTP_HOST / SMTP_PORT / SMTP_USER / SMTP_PASSWORD (optional, if wiring real email sending; current code stubs send_email).
"""

import os
import pyodbc
import secrets
from datetime import datetime, timedelta
from typing import Optional, Dict, Any
from dotenv import load_dotenv
from fastapi import APIRouter, HTTPException, Depends, Body
from jose import jwt
from passlib.context import CryptContext
from pydantic import BaseModel, EmailStr
import httpx
# Load environment variables from secrets.env first, then .env
load_dotenv("secrets.env")
load_dotenv()

# DB connection (duplicate of comm.py to avoid circular import)
server = 'tcp:taexpense.database.windows.net'
database = 'TAExpense'
username = 'ttanh'
password = 'Bitbo123@'
driver = '{ODBC Driver 18 for SQL Server}'


def get_conn():
    return pyodbc.connect(
        f'DRIVER={driver};SERVER={server};PORT=1433;DATABASE={database};UID={username};PWD={password}'
    )

# Password hashing (only bcrypt_sha256 to avoid 72-byte limit errors)
pwd_context = CryptContext(schemes=["bcrypt_sha256"], deprecated="auto")

# JWT
JWT_SECRET = os.getenv("AUTH_JWT_SECRET", "change-me")
JWT_EXPIRES_MINUTES = int(os.getenv("AUTH_JWT_EXPIRES_MINUTES", "60"))
JWT_ALG = "HS256"

router = APIRouter(prefix="/auth", tags=["auth"])

# ---- Models ----

class SignupRequest(BaseModel):
    email: EmailStr
    password: str
    display_name: Optional[str] = None

class LoginRequest(BaseModel):
    email: EmailStr
    password: str

class OAuthStartResponse(BaseModel):
    authorization_url: str

class OAuthCallbackRequest(BaseModel):
    code: str
    state: Optional[str] = None

class OTPRequest(BaseModel):
    email: EmailStr

class OTPVerifyRequest(BaseModel):
    email: EmailStr
    otp: str
    new_password: Optional[str] = None

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"

# ---- Helpers ----

def _hash_password(password: str) -> str:
    return pwd_context.hash(password)

def _verify_password(password: str, hashed: str) -> bool:
    return pwd_context.verify(password, hashed)

def _create_token(payload: Dict[str, Any]) -> str:
    to_encode = payload.copy()
    to_encode["exp"] = datetime.utcnow() + timedelta(minutes=JWT_EXPIRES_MINUTES)
    return jwt.encode(to_encode, JWT_SECRET, algorithm=JWT_ALG)


def _get_user_by_email(email: str) -> Optional[Dict[str, Any]]:
    conn = get_conn()
    cursor = conn.cursor()
    cursor.execute("SELECT id, email, password_hash, display_name, provider, provider_id FROM users WHERE email = ?", email)
    row = cursor.fetchone()
    if not row:
        return None
    return {
        "id": row[0],
        "email": row[1],
        "password_hash": row[2],
        "display_name": row[3],
        "provider": row[4],
        "provider_id": row[5],
    }


def _insert_user(email: str, password_hash: Optional[str], display_name: Optional[str], provider: str, provider_id: Optional[str]) -> int:
    conn = get_conn()
    cursor = conn.cursor()
    # Return new primary key to use as token subject
    cursor.execute(
        """
        INSERT INTO users (email, password_hash, display_name, provider, provider_id)
        OUTPUT INSERTED.id
        VALUES (?, ?, ?, ?, ?)
        """,
        email, password_hash, display_name, provider, provider_id
    )
    new_id = cursor.fetchone()[0]
    conn.commit()
    return int(new_id)


def _set_otp(email: str, otp: str, expires_at: datetime):
    conn = get_conn()
    cursor = conn.cursor()
    cursor.execute(
        "UPDATE users SET otp_code = ?, otp_expires_at = ? WHERE email = ?",
        otp, expires_at, email,
    )
    conn.commit()


def _consume_otp(email: str, otp: str) -> bool:
    conn = get_conn()
    cursor = conn.cursor()
    cursor.execute(
        "SELECT otp_code, otp_expires_at FROM users WHERE email = ?",
        email,
    )
    row = cursor.fetchone()
    if not row:
        return False
    code, expires_at = row
    if not code or code != otp:
        return False
    if expires_at and datetime.utcnow() > expires_at:
        return False
    # clear otp
    cursor.execute("UPDATE users SET otp_code = NULL, otp_expires_at = NULL WHERE email = ?", email)
    conn.commit()
    return True


def _update_password(email: str, password_hash: str):
    conn = get_conn()
    cursor = conn.cursor()
    cursor.execute(
        "UPDATE users SET password_hash = ? WHERE email = ?",
        password_hash, email,
    )
    conn.commit()


def _send_email_stub(email: str, subject: str, body: str):
    # Placeholder: integrate with real email provider (SMTP/API)
    print(f"[EMAIL to {email}] {subject}\n{body}")

# ---- Routes ----

@router.post("/signup", response_model=TokenResponse)
async def signup(payload: SignupRequest):
    existing = _get_user_by_email(payload.email)
    if existing:
        raise HTTPException(status_code=400, detail="Email already registered")
    password_hash = _hash_password(payload.password)
    user_id = _insert_user(payload.email, password_hash, payload.display_name, provider="local", provider_id=None)
    token = _create_token({"sub": str(user_id), "email": payload.email})
    return TokenResponse(access_token=token)


@router.post("/login", response_model=TokenResponse)
async def login(payload: LoginRequest):
    user = _get_user_by_email(payload.email)
    if not user or not user.get("password_hash"):
        raise HTTPException(status_code=401, detail="Invalid credentials")
    if not _verify_password(payload.password, user["password_hash"]):
        raise HTTPException(status_code=401, detail="Invalid credentials")
    token = _create_token({"sub": str(user["id"]), "email": user["email"]})
    return TokenResponse(access_token=token)


# OAuth start endpoints (return the URL the client should open). Real implementation requires client IDs/secrets and redirect URIs.
@router.get("/oauth/google/start", response_model=OAuthStartResponse)
async def google_start():
    client_id = os.getenv("OAUTH_GOOGLE_CLIENT_ID", "")
    redirect_uri = os.getenv("OAUTH_GOOGLE_REDIRECT_URI", "http://localhost:8000/auth/oauth/google/callback")
    scope = "openid email profile"
    auth_url = (
        "https://accounts.google.com/o/oauth2/v2/auth"
        f"?client_id={client_id}&redirect_uri={redirect_uri}&response_type=code&scope={scope}&access_type=offline"
    )
    return OAuthStartResponse(authorization_url=auth_url)


@router.post("/oauth/google/callback", response_model=TokenResponse)
async def google_callback(payload: OAuthCallbackRequest):
    client_id = os.getenv("OAUTH_GOOGLE_CLIENT_ID")
    client_secret = os.getenv("OAUTH_GOOGLE_CLIENT_SECRET")
    redirect_uri = os.getenv("OAUTH_GOOGLE_REDIRECT_URI", "http://localhost:8001/auth/oauth/google/callback")
    
    if not client_id or not client_secret:
        raise HTTPException(status_code=500, detail="Google OAuth not configured")
    
    # Exchange code for tokens
    async with httpx.AsyncClient() as client:
        token_response = await client.post(
            "https://oauth2.googleapis.com/token",
            data={
                "code": payload.code,
                "client_id": client_id,
                "client_secret": client_secret,
                "redirect_uri": redirect_uri,
                "grant_type": "authorization_code",
            }
        )
        
        if token_response.status_code != 200:
            raise HTTPException(status_code=400, detail="Failed to exchange code for token")
        
        tokens = token_response.json()
        id_token = tokens.get("id_token")
        
        # Decode ID token (Google tokens are JWTs, but for simplicity we trust them here)
        # In production, verify signature using Google's public keys
        try:
            claims = jwt.decode(id_token, options={"verify_signature": False})
            email = claims.get("email")
            google_id = claims.get("sub")
            display_name = claims.get("name")
        except Exception:
            raise HTTPException(status_code=400, detail="Invalid ID token")
    
    if not email:
        raise HTTPException(status_code=400, detail="Email not provided by Google")
    
    user = _get_user_by_email(email)
    user_id: int
    if not user:
        user_id = _insert_user(email, None, display_name, provider="google", provider_id=google_id)
    else:
        user_id = int(user["id"])

    token = _create_token({"sub": str(user_id), "email": email})
    return TokenResponse(access_token=token)


@router.get("/oauth/facebook/start", response_model=OAuthStartResponse)
async def facebook_start():
    client_id = os.getenv("OAUTH_FACEBOOK_CLIENT_ID", "")
    redirect_uri = os.getenv("OAUTH_FACEBOOK_REDIRECT_URI", "http://localhost:8000/auth/oauth/facebook/callback")
    scope = "email,public_profile"
    auth_url = (
        "https://www.facebook.com/v11.0/dialog/oauth"
        f"?client_id={client_id}&redirect_uri={redirect_uri}&response_type=code&scope={scope}"
    )
    return OAuthStartResponse(authorization_url=auth_url)


@router.post("/oauth/facebook/callback", response_model=TokenResponse)
async def facebook_callback(payload: OAuthCallbackRequest):
    # TODO: exchange code for tokens using Facebook token endpoint, get user info (id,email)
    email = f"facebook_user_{payload.code}@example.com"
    user = _get_user_by_email(email)
    user_id: int
    if not user:
        user_id = _insert_user(email, None, None, provider="facebook", provider_id=email)
    else:
        user_id = int(user["id"])
    token = _create_token({"sub": str(user_id), "email": email})
    return TokenResponse(access_token=token)


@router.post("/password/otp/request")
async def request_otp(payload: OTPRequest):
    user = _get_user_by_email(payload.email)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    otp = f"{secrets.randbelow(999999):06d}"
    expires_at = datetime.utcnow() + timedelta(minutes=10)
    _set_otp(payload.email, otp, expires_at)
    _send_email_stub(payload.email, "Your OTP Code", f"Your OTP is {otp}. It expires in 10 minutes.")
    return {"message": "OTP sent"}


@router.post("/password/otp/verify", response_model=TokenResponse)
async def verify_otp(payload: OTPVerifyRequest):
    user = _get_user_by_email(payload.email)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    if not _consume_otp(payload.email, payload.otp):
        raise HTTPException(status_code=400, detail="Invalid or expired OTP")
    if payload.new_password:
        _update_password(payload.email, _hash_password(payload.new_password))
    token = _create_token({"sub": str(user["id"]), "email": user["email"]})
    return TokenResponse(access_token=token)


@router.post("/logout")
async def logout():
    # JWT is stateless; clients should discard their stored token.
    return {"message": "Logged out"}
