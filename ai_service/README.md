# AI Service

Run this service before using the doctor AI action:

```powershell
cd ai_service
python -m venv .venv
.\.venv\Scripts\pip install -r requirements.txt
.\.venv\Scripts\python app.py
```

`POST /predict` accepts the `HealthRecord` JSON sent by Java and returns `Normal`, `Pre-Diabetes`, and `Diabetes` probabilities. Put a trained `model.joblib` in this folder, or set `DIABETES_MODEL_PATH`; otherwise the service uses a conservative rule-based fallback.
