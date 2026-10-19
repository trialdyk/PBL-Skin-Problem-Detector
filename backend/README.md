# DermaScan Backend

Backend FastAPI untuk **DermaScan** — aplikasi Flutter yang membantu mengidentifikasi kondisi kulit wajah menggunakan computer vision.

Fondasi saat ini:
- Skeleton FastAPI + health check + router placeholder
- PostgreSQL + SQLAlchemy 2.0 + Alembic (tabel `users`)

## Stack

| Komponen | Teknologi |
|----------|-----------|
| Framework | FastAPI + Uvicorn |
| Bahasa | Python 3.10+ (disarankan 3.12) |
| Validasi / config | Pydantic v2 + pydantic-settings |
| Database | PostgreSQL (Docker) |
| ORM / migrasi | SQLAlchemy 2.0 + Alembic + psycopg3 |
| Testing | pytest + HTTPX |

## Prasyarat

Pastikan sudah terpasang:

1. **Python** 3.10 atau lebih baru  
2. **Git**  
3. **Docker Desktop** (Postgres development di port host **5434**)  
4. Opsional: Git Bash / WSL di Windows untuk menjalankan `./run.sh`

---

## Setup project (ikuti berurutan)

Panduan ini untuk anggota tim yang baru clone repository.

### 1. Clone repository

```bash
git clone <url-repo-ini>
cd PBL-Skin-Problem-Detector-BE
```

### 2. Buat & aktifkan virtual environment

**Windows (PowerShell):**

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
```

Kalau PowerShell menolak script, jalankan sekali:

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

**macOS / Linux:**

```bash
python3 -m venv .venv
source .venv/bin/activate
```

Prompt terminal biasanya berubah menjadi `(.venv)`.

### 3. Install dependencies

```bash
pip install -r requirements.txt
```

### 4. Siapkan file environment

**Windows (PowerShell):**

```powershell
Copy-Item .env.example .env
```

**macOS / Linux:**

```bash
cp .env.example .env
```

Edit `.env` lalu sesuaikan password Docker Postgres kamu:

```env
APP_NAME=DermaScan Backend
APP_ENV=development
DEBUG=true

DB_HOST=localhost
DB_USER=postgres
DB_PASSWORD=isi_password_docker_postgres_kamu
DB_NAME=dermascan
DB_PORT=5434
DB_SSL_MODE=disable
```

Catatan:
- File `.env` **tidak** di-commit ke Git.
- Pakai database khusus **`dermascan`** — jangan pakai database project lain.

### 5. Nyalakan PostgreSQL (Docker)

1. Buka **Docker Desktop** sampai status running.
2. Pastikan container Postgres kamu listen di port **5434**.
3. Buat database DermaScan (sekali saja):

```bash
psql -h localhost -p 5434 -U postgres -c "CREATE DATABASE dermascan;"
```

Kalau `psql` belum ada di PATH (Windows), contoh:

```powershell
& "C:\Program Files\PostgreSQL\18\bin\psql.exe" -h localhost -p 5434 -U postgres -c "CREATE DATABASE dermascan;"
```

Kalau muncul error `already exists`, database sudah ada — lanjut step berikutnya.

### 6. Jalankan migrasi database

Dari root project (virtualenv masih aktif):

```bash
alembic upgrade head
```

Cek status:

```bash
alembic current
```

Harus menampilkan revision head (contoh: `20260316_0001 (head)`).

### 7. Jalankan server

Pastikan virtualenv aktif, atau pakai `run.sh` (otomatis memakai `.venv` bila ada).

**Windows PowerShell (direkomendasikan):**

```powershell
.\.venv\Scripts\Activate.ps1
python -m uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

**macOS / Linux / Git Bash:**

```bash
chmod +x run.sh
./run.sh
```

### 8. Verifikasi

Buka di browser / terminal:

| Cek | URL / perintah |
|-----|----------------|
| Health | http://127.0.0.1:8000/health |
| Swagger docs | http://127.0.0.1:8000/docs |
| ReDoc | http://127.0.0.1:8000/redoc |
| Health via curl | `curl http://127.0.0.1:8000/health` |

Respons health yang diharapkan:

```json
{
  "status": "ok",
  "service": "dermascan-backend"
}
```

Jalankan test:

```bash
pytest
```

---

## Perintah berguna

Semua perintah di bawah dijalankan dari **root repository** dengan virtualenv aktif.

### Environment & dependencies

```bash
# aktifkan venv (Windows PowerShell)
.\.venv\Scripts\Activate.ps1

# aktifkan venv (macOS / Linux)
source .venv/bin/activate

# install / sync dependency
pip install -r requirements.txt
```

### Database (Alembic)

```bash
# terapkan semua migrasi
alembic upgrade head

# lihat revision yang sedang aktif
alembic current

# lihat riwayat migrasi
alembic history

# buat migrasi baru dari perubahan model
alembic revision --autogenerate -m "deskripsi_perubahan"

# rollback 1 langkah
alembic downgrade -1
```

### Menjalankan aplikasi

```bash
# aktifkan venv dulu (Windows PowerShell)
.\.venv\Scripts\Activate.ps1

# development server (pakai python dari venv yang aktif)
python -m uvicorn app.main:app --reload --host 127.0.0.1 --port 8000

# via script bash (otomatis pilih .venv bila ada)
./run.sh

# ganti port (run.sh)
PORT=8080 ./run.sh
```

### Testing

```bash
# semua test
pytest

# test verbose
pytest -v

# satu file test
pytest tests/test_main.py
pytest tests/test_database.py
```

### Cek cepat API

```bash
curl http://127.0.0.1:8000/health
curl http://127.0.0.1:8000/users/status
curl http://127.0.0.1:8000/items/status
```

---

## Struktur folder

```text
PBL-Skin-Problem-Detector-BE/
├── app/
│   ├── main.py              # Entry FastAPI + GET /health
│   ├── dependencies.py      # Depends (get_db)
│   ├── routers/             # Router API publik
│   ├── internal/            # Modul internal/admin (reserved)
│   ├── core/                # Config & security
│   ├── models/              # Model ORM (User)
│   ├── schemas/             # Schema Pydantic (reserved)
│   ├── services/            # Business logic (reserved)
│   └── db/
│       ├── database.py      # Engine, session, Base
│       └── migrations/      # Script Alembic
├── tests/
├── alembic.ini
├── .env                     # Lokal saja (jangan commit)
├── .env.example             # Template env untuk tim
├── requirements.txt
├── run.sh
└── README.md
```

| Path | Fungsi |
|------|--------|
| `app/main.py` | Buat app FastAPI, daftar router, endpoint `/health` |
| `app/core/config.py` | Settings dari environment / `.env` |
| `app/db/database.py` | Engine SQLAlchemy + session |
| `app/db/migrations/` | Migrasi Alembic |
| `app/models/` | Model ORM (`User` sudah ada) |
| `app/routers/` | Endpoint HTTP |
| `tests/` | Automated tests |

---

## Scope saat ini

**Sudah ada**
- Skeleton FastAPI
- Config terpusat (`.env`)
- Koneksi PostgreSQL + migrasi Alembic
- Tabel `users`
- Dependency `get_db`
- `GET /health` (tidak bergantung DB)
- Suite pytest

**Belum dikerjakan (deferred)**
- Register / login API
- JWT & password hashing
- Tabel analysis / images / results
- Cloudflare R2, upload gambar, inference ML
- Deploy production

## Troubleshooting singkat

| Masalah | Solusi |
|---------|--------|
| `connection refused` port 5434 | Nyalakan Docker Desktop + container Postgres |
| `database "dermascan" does not exist` | Jalankan `CREATE DATABASE dermascan;` |
| `password authentication failed` | Samakan `DB_PASSWORD` di `.env` dengan password container |
| `ModuleNotFoundError` | Aktifkan `.venv` lalu `pip install -r requirements.txt` |
| PowerShell: script disabled | `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned` |

## Next task yang disarankan

Scaffolding autentikasi (register/login + hashing password + JWT), dengan logic di `app/services/` dan router tetap tipis.
