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

# === Load model ===
model_path = "lib/parseai/model"  # path to your local LLaMA3.2 weights
print("Loading model...")
tokenizer = AutoTokenizer.from_pretrained(model_path)
model = AutoModelForSeq2SeqLM.from_pretrained(
    model_path,
    device_map="auto",
    torch_dtype=torch.float16
)
model.eval()
print("Model loaded successfully.")

# === API Endpoint ===
@app.get("/")
async def read_root():
    return {"message": "ParseScript 1.0 "}

@app.post("/generate")
async def generate(request: Request):
    data = await request.json()
    prompt = data.get("prompt", "")
    if not prompt:
        return {"error": "No prompt provided"}

    # For encoder-decoder models (T5/Flan-T5) we must pass input_ids to the encoder
    inputs = tokenizer(prompt, return_tensors="pt")
    inputs = {k: v.to(model.device) for k, v in inputs.items()}

    # generation params
    max_new_tokens = int(data.get("max_new_tokens", 64))
    do_sample = bool(data.get("do_sample", False))
    temperature = float(data.get("temperature", 0.7))

    # Call generate with encoder inputs
    with torch.no_grad():
        outputs = model.generate(
            input_ids=inputs.get("input_ids"),
            attention_mask=inputs.get("attention_mask"),
            max_new_tokens=max_new_tokens,
            do_sample=do_sample,
            temperature=temperature,
            pad_token_id=tokenizer.eos_token_id,
            use_cache=True,
        )

    response = tokenizer.decode(outputs[0], skip_special_tokens=True)
    print("Generated response:", response)
    return {"response": response}
