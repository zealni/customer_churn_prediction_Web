# 🚀 IMMEDIATE EXECUTION STEPS (Restructured Project)

## STEP 1: Prepare Environment (5 min)

```powershell
# Buka terminal di root folder (E:\PORTO WEB\ML1)

# Pindah ke folder backend
cd backend

# Aktifkan virtual environment yang telah dipindahkan
.\.venv\Scripts\activate

# Pastikan dependencies terinstall dengan benar
pip install -r requirements.txt
```

---

## STEP 2: Start FastAPI Server (2 min)

```powershell
# Jalankan uvicorn server dari dalam folder backend
python main.py --reload
```

**Expected output:**
```text
🚀 Starting Churn Intelligence API Server...
   Host: 0.0.0.0
   Port: 8000
   Model Dir: models
   API Docs: http://0.0.0.0:8000/docs

INFO:     Uvicorn running on http://0.0.0.0:8000
INFO:     Application startup complete
```

✅ Server backend aktif dan siap menerima request!

---

## STEP 3: Test API (2 min)

**Buka terminal baru di root folder, lalu masuk ke folder backend:**

```powershell
cd backend
.\.venv\Scripts\activate
python test_api.py
```

**Expected output:**
```text
SUCCESS: 200
{
  "customer_id": "7590-VHVEG",
  "churn_probability": 0.5421,
  "churn_prediction": 1,
  "risk_tier": "MEDIUM",
  ...
}
```

✅ API berjalan dengan normal!

---

## STEP 4: Start Frontend Flutter Web (2 min)

**Buka terminal baru di root folder, lalu masuk ke folder frontend:**

```powershell
# Pindah ke folder frontend
cd frontend

# Ambil packages
flutter pub get

# Jalankan Flutter Web App di Chrome
flutter run -d chrome
```

Aplikasi web Flutter akan terbuka di Chrome dan otomatis terhubung ke FastAPI server di port `8000`!

---

## 📊 Expected Results per Risk Tier

| Risk Tier | Prob Range | Example | Action |
|-----------|-----------|---------|--------|
| 🟢 LOW | < 40% | Loyal, long-tenure, many services | Maintain relationship |
| 🟡 MEDIUM | 40-70% | New customer, month-to-month contract | Proactive outreach |
| 🔴 HIGH | ≥ 70% | Negative feedback, short tenure, high churn rate | Urgent callback |

---

## 📞 Troubleshooting

**Error: "Connection refused"**
```text
→ Pastikan server backend Anda di port 8000 masih berjalan di Terminal 1.
```

**Error: "Model not found"**
```text
→ Pastikan folder backend/models/ berisi file-file berikut:
   - catboost_main_model.cbm
   - sentiment_classifier.joblib
   - embedding_pca.joblib
   - model_metadata.json
```
