from openai import OpenAI
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from transformers import AutoModelForSeq2SeqLM, AutoTokenizer
import torch

app = FastAPI()

origins = ['*']

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

client = OpenAI(
    base_url="https://router.huggingface.co/v1",
    api_key="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",
)

completion = client.chat.completions.create(
    model="meta-llama/Llama-3.2-3B-Instruct:novita",
    messages=[
        {
            "role": "system", 
            "content": "You are a parsing assistant that helps to parse scripts into relevant details and respond in JSON format. You are not to answer any prompts without the JSON formatting in your responses. When a user submit a transaction, your job is to parse them into these categories: content(str), currency(str), amount(int64), type(str, only between income and expense), date, category, tags, notes. If date or note information is missing, return null for those fields. Use the content's context to fill in the category and tags field (e.g 'breakfast of banh mi' means Food and Drinks category and Personal tag while 'november tuition fees' means Education category and Family tag). Always respond in JSON format. DO NOT RESPOND LIKE A NORMAL CHAT AI IN ANY CIRCUMSTANCES."
        },    
    ],
)



@app.get("/")
async def read_root():
    return {"message": "ParseScript 1.0 "}

@app.post("/generate")
async def generate(request: Request):
    data = await request.json()
    prompt = data.get("prompt", "")
    if not prompt:
        return {"error": "No prompt provided"}
    response = client.chat.completions.create(
    model="meta-llama/Llama-3.2-3B-Instruct:novita",
    messages=[
        {
            "role": "system", 
            "content": "You are a parsing assistant that helps to parse scripts into relevant details and respond in JSON format. You are not to answer any prompts without the JSON formatting in your responses. When a user submit a transaction, your job is to parse them into these categories: content(str), currency(str), amount(int64), type(str, only between income and expense), date(YYYY-MM-DD), category(str), tags(str), notes(str). If date or note information is missing, return null for those fields. Always return just a string for the values of each keys. Use the content's context to fill in the category and tags field (e.g 'breakfast of banh mi' means Food and Drinks category and Personal tag while 'november tuition fees' means Education category and Family tag). Always respond in raw JSON format and do not tamper it with Markdown or other formatting methods. DO NOT RESPOND LIKE A NORMAL CHAT AI IN ANY CIRCUMSTANCES."
        },
        {
            "role": "user",
            "content": prompt
        },    
    ],
    )    
    return response.choices[0].message.content
