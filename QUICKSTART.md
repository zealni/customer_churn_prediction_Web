# 🎯 Churn Intelligence System — Quick Start & Deployment Guide

Dokumentasi lengkap untuk menjalankan server backend FastAPI (ML Predictor) dan frontend Flutter Web.

---

## 📋 Struktur File Terbaru

```text
E:\PORTO WEB\ML1\
├── backend/                           ← Backend python development
│   ├── dataset/                       ← Input raw data
│   │   └── telco_churn_with_all_feedback.csv
│   ├── models/                        ← Pre-trained ML & NLP models
│   │   ├── catboost_main_model.cbm    ← CatBoost Classifier
│   │   ├── sentiment_classifier.joblib← Sentiment Predictor (LogReg)
│   │   ├── embedding_pca.joblib       ← Dimensionality Compressor (PCA)
│   │   └── model_metadata.json        ← Config & metadata
│   ├── tests/                         ← Pytest files
│   ├── main.py                        ← FastAPI server entry point
│   ├── database.py                    ← SQLAlchemy & DB Models
│   ├── predictor.py                   ← Predictor class logic
│   ├── requirements.txt               ← Backend dependencies
│   ├── sample_batch.csv               ← Batch testing template
│   └── churn_predictions.db           ← SQLite database
│
├── frontend/                          ← Frontend Flutter Web app
│   ├── assets/                        ← Static assets & icons
│   ├── lib/                           ← Flutter application files
│   │   ├── main.dart                  ← Entry point aplikasi Flutter
│   │   ├── models/                    ← Client-side models
│   │   ├── services/                  ← ApiService & integrations
│   │   └── widgets/                   ← Components & widgets
│   └── pubspec.yaml                   ← Flutter dependencies
│
└── docker-compose.yml                 ← Compose configuration
```

---

## 🚀 Quick Start (Local Development)

### 1️⃣ Setup & Jalankan Backend FastAPI

Buka terminal di root folder proyek:

```bash
# Masuk ke direktori backend
cd backend

# Aktifkan virtual environment
.\.venv\Scripts\activate

# Install dependencies (jika diperlukan)
pip install -r requirements.txt

# Jalankan server
python main.py --reload
```

✅ Server backend Anda berjalan di: **`http://localhost:8000`**

### 2️⃣ Jalankan Frontend Flutter Web

Buka terminal baru di root folder proyek:

```bash
# Masuk ke direktori frontend
cd frontend

# Install package dependencies
flutter pub get

# Jalankan web application di browser Chrome
flutter run -d chrome
```

---

## 📡 API Endpoints (FastAPI)

### **1. GET** `/health`
Mengecek status kesehatan server dan pemuatan model.
```bash
curl http://localhost:8000/health
```

### **2. POST** `/predict`
Prediksi churn untuk 1 customer secara individual.
**Endpoint URL:** `http://localhost:8000/predict`

### **3. POST** `/predict_batch`
Batch prediction untuk data multiple customer sekaligus.
**Endpoint URL:** `http://localhost:8000/predict_batch`

---

## 🐳 Deployment (Production)

### **Menggunakan Docker Compose**
Dari root folder proyek (di mana `docker-compose.yml` berada), jalankan perintah:

```bash
# Build dan jalankan backend via Docker
docker-compose up --build -d
```

Docker akan otomatis mem-build image dari file `./backend/Dockerfile` dan me-mount volume `./backend/models` ke dalam container `/app/models` secara dinamis.

---

## 🧪 Testing

### Unit Test (ML Predictor)
Untuk memverifikasi modul predictor secara terpisah tanpa API overhead:

```bash
cd backend
.\.venv\Scripts\activate
python test_predictor.py
```
atau jika menggunakan Pytest:
```bash
pytest tests/
```
