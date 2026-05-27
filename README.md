# 🎯 Customer Churn Prediction & Intelligence System

Sistem Prediksi Churn Pelanggan Telco yang ditenagai oleh Machine Learning (CatBoost & Sentence Transformers) dan visualisasi berbasis Flutter Web modern.

---

## 📂 Struktur Folder Baru

Proyek ini telah direstrukturisasi menjadi dua folder utama untuk memisahkan logika **Frontend** dan **Backend**:

```text
E:\PORTO WEB\ML1\
├── backend/                  ← REST API FastAPI, Jupyter Notebooks, & Model ML
│   ├── dataset/              ← Dataset Telco Churn
│   ├── models/               ← Pre-trained ML & NLP Models
│   ├── main.py               ← Entrypoint FastAPI Server
│   ├── database.py           ← Database SQLite & SQLAlchemy Models
│   ├── predictor.py          ← Core Predictor ML
│   └── ...                   
│
├── frontend/                 ← Aplikasi Dashboard Utama (Flutter Web)
│   ├── lib/                  ← Dart source code
│   ├── web/                  ← Web assets & index.html
│   └── ...                   
│
├── docker-compose.yml        ← Orkestrasi Docker container backend
├── .gitignore                ← Root-level Git ignore rules
├── QUICKSTART.md             ← Panduan instalasi dan deployment lengkap
├── RUN_NOW.md                ← Langkah cepat menjalankan aplikasi secara lokal
└── cara run.md               ← Panduan troubleshoot & commands
```

---

## 🚀 Panduan Cepat Menjalankan Aplikasi

Untuk memulai dengan cepat, silakan merujuk pada file panduan berikut:
1. **[RUN_NOW.md](file:///e:/PORTO%20WEB/ML1/RUN_NOW.md)** - Langkah cepat untuk menjalankan backend & frontend secara lokal.
2. **[cara run.md](file:///e:/PORTO%20WEB/ML1/cara%20run.md)** - Cheat-sheet terminal commands untuk pengecekan port dan troubleshooting.
3. **[QUICKSTART.md](file:///e:/PORTO%20WEB/ML1/QUICKSTART.md)** - Penjelasan arsitektur lengkap, endpoint API, dan cara deployment production.
