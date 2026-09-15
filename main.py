"""
FastAPI backend for the Energy Assistant app.

Endpoints:
  POST /predict          -> ML-based next-month bill prediction
  POST /assistant/ask    -> Gemini-powered explanation of bill trends

Run:
  pip install fastapi uvicorn scikit-learn numpy google-generativeai
  uvicorn main:app --reload --host 0.0.0.0 --port 8000

Point the Flutter app's BillService.backendBaseUrl / AiAssistantService
at this server's address (use http://10.0.2.2:8000 from an Android emulator).
"""

import os
from typing import List, Optional

import numpy as np
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from sklearn.linear_model import LinearRegression

app = FastAPI(title="Energy Assistant API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # tighten this in production
    allow_methods=["*"],
    allow_headers=["*"],
)


class BillIn(BaseModel):
    month: str
    previousBillAmount: float
    currentBillAmount: float
    unitsConsumed: Optional[float] = None
    predictedNextBill: Optional[float] = None


class PredictRequest(BaseModel):
    history: List[BillIn]
    current_bill: BillIn


class PredictResponse(BaseModel):
    predicted_bill: float


@app.post("/predict", response_model=PredictResponse)
def predict_bill(req: PredictRequest):
    """Simple linear regression over bill amounts vs. time index.
    Swap in a more sophisticated model (e.g. incorporating units_consumed,
    season, appliance data) as more data becomes available.
    """
    all_bills = req.history + [req.current_bill]
    amounts = [b.currentBillAmount for b in all_bills]

    if len(amounts) < 2:
        # not enough data — simple heuristic
        return PredictResponse(predicted_bill=round(amounts[-1] * 1.05, 2))

    X = np.arange(len(amounts)).reshape(-1, 1)
    y = np.array(amounts)

    model = LinearRegression()
    model.fit(X, y)

    next_index = np.array([[len(amounts)]])
    prediction = float(model.predict(next_index)[0])

    # keep prediction sane (never negative, cap wild swings)
    prediction = max(prediction, amounts[-1] * 0.5)
    return PredictResponse(predicted_bill=round(prediction, 2))


class AssistantRequest(BaseModel):
    question: str
    history: List[BillIn]


class AssistantResponse(BaseModel):
    answer: str


@app.post("/assistant/ask", response_model=AssistantResponse)
def ask_assistant(req: AssistantRequest):
    """Calls Gemini API with the user's bill history as context.
    Requires GEMINI_API_KEY environment variable.
    """
    history_text = "\n".join(
        f"{b.month}: previous ₹{b.previousBillAmount}, current ₹{b.currentBillAmount}"
        + (f", units {b.unitsConsumed}" if b.unitsConsumed else "")
        for b in req.history
    )

    prompt = (
        "You are an energy-saving assistant for an electricity bill app. "
        "Given this bill history:\n"
        f"{history_text}\n\n"
        f"Answer the user's question clearly and briefly, and include 1-2 "
        f"practical energy-saving tips. Question: {req.question}"
    )

    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        return AssistantResponse(
            answer="GEMINI_API_KEY not configured on the server. "
            "(This is a placeholder response — set the env var to enable real answers.)"
        )

    try:
        import google.generativeai as genai

        genai.configure(api_key=api_key)
        model = genai.GenerativeModel("gemini-1.5-flash")
        response = model.generate_content(prompt)
        return AssistantResponse(answer=response.text)
    except Exception as e:  # pragma: no cover
        return AssistantResponse(answer=f"Assistant error: {e}")


@app.get("/")
def health():
    return {"status": "ok"}
