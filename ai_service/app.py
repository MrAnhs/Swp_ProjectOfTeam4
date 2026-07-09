from __future__ import annotations

import os
from typing import Dict, List

import joblib
import numpy as np
from flask import Flask, jsonify, request


FEATURES: List[str] = [
    "urea",
    "cr",
    "hba1c",
    "chol",
    "tg",
    "hdl",
    "ldl",
    "vldl",
    "bmi",
]

MODEL_PATH = os.environ.get(
    "DIABETES_MODEL_PATH",
    os.path.join(os.path.dirname(__file__), "model.joblib"),
)

app = Flask(__name__)
model = joblib.load(MODEL_PATH) if os.path.exists(MODEL_PATH) else None


def read_float(payload: Dict, key: str) -> float:
    value = payload.get(key, 0)
    if value in (None, ""):
        return 0.0
    return float(value)


def normalize_probabilities(raw: Dict[str, float]) -> Dict[str, float]:
    total = sum(max(value, 0.0) for value in raw.values())
    if total <= 0:
        return {"Normal": 0.34, "Pre-Diabetes": 0.33, "Diabetes": 0.33}
    return {key: round(max(value, 0.0) / total, 4) for key, value in raw.items()}


def fallback_predict(values: Dict[str, float]) -> Dict[str, float]:
    hba1c = values["hba1c"]
    bmi = values["bmi"]
    tg = values["tg"]
    hdl = values["hdl"]
    chol = values["chol"]

    diabetes_score = 0.15
    pre_score = 0.2
    normal_score = 0.65

    if hba1c >= 6.5:
        diabetes_score += 0.65
        normal_score -= 0.4
    elif hba1c >= 5.7:
        pre_score += 0.45
        normal_score -= 0.3

    if bmi >= 30:
        diabetes_score += 0.12
    elif bmi >= 25:
        pre_score += 0.1

    if tg >= 1.7:
        pre_score += 0.08
        diabetes_score += 0.06
    if hdl and hdl < 1.0:
        diabetes_score += 0.05
    if chol >= 5.2:
        pre_score += 0.05

    return normalize_probabilities(
        {
            "Normal": normal_score,
            "Pre-Diabetes": pre_score,
            "Diabetes": diabetes_score,
        }
    )


@app.get("/health")
def health():
    return jsonify({"status": "ok", "modelLoaded": model is not None})


@app.post("/predict")
def predict():
    payload = request.get_json(silent=True) or {}
    try:
        values = {feature: read_float(payload, feature) for feature in FEATURES}
    except (TypeError, ValueError) as exc:
        return jsonify({"status": "error", "message": f"Invalid numeric input: {exc}"}), 400

    if model is None:
        probabilities = fallback_predict(values)
        return jsonify(
            {
                "status": "success",
                "modelVersion": "fallback-rules-v1",
                "probabilities": probabilities,
            }
        )

    sample = np.array([[values[feature] for feature in FEATURES]], dtype=float)
    if not hasattr(model, "predict_proba"):
        return jsonify({"status": "error", "message": "Model does not support predict_proba"}), 500

    raw_probs = model.predict_proba(sample)[0]
    classes = [str(label) for label in getattr(model, "classes_", [])]
    probabilities = dict(zip(classes, [round(float(prob), 4) for prob in raw_probs]))

    return jsonify(
        {
            "status": "success",
            "modelVersion": os.path.basename(MODEL_PATH),
            "probabilities": {
                "Normal": probabilities.get("Normal", probabilities.get("0", 0.0)),
                "Pre-Diabetes": probabilities.get("Pre-Diabetes", probabilities.get("1", 0.0)),
                "Diabetes": probabilities.get("Diabetes", probabilities.get("2", 0.0)),
            },
        }
    )


if __name__ == "__main__":
    app.run(host="127.0.0.1", port=int(os.environ.get("PORT", "5000")))
