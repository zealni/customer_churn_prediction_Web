# 🛠️ Cheat Sheet: Menjalankan Aplikasi & Pengecekan Port

### 1️⃣ Cara Cek Proses Yang Menggunakan Port 8000 (Backend)
Jika port 8000 sudah terpakai, cari dan matikan proses tersebut:

```powershell
# Temukan PID proses di port 8000
Get-NetTCPConnection -LocalPort 8000 | Select-Object LocalAddress, LocalPort, State, OwningProcess

# Lihat nama prosesnya
Get-Process -Id <PID>

# Matikan proses tersebut jika itu adalah server lama Anda
Stop-Process -Id <PID>
```

---

### 2️⃣ Cara Menjalankan Backend (FastAPI)
Buka terminal baru di root folder:

```powershell
# Pindah ke direktori backend
cd backend

# Aktifkan virtual environment
.\.venv\Scripts\activate

# Jalankan server FastAPI
python -m uvicorn main:app --host 127.0.0.1 --port 8000 --reload
```

*Alternatif paling cepat (jika port 8000 tetap terpakai):*
```powershell
python -m uvicorn main:app --host 127.0.0.1 --port 8001 --reload
```

---

### 3️⃣ Cara Menjalankan Frontend (Flutter Web)
Buka terminal baru di root folder:

```powershell
# Pindah ke direktori frontend
cd frontend

# Install packages
flutter pub get

# Jalankan aplikasi di Google Chrome
flutter run -d chrome
```