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

Untuk `POST /ml/predict` (dan test ML) butuh paket inferensi tambahan:

```bash
pip install -r requirements-ml.txt
```

Isinya `ai-edge-litert` (runtime TFLite ringan ± 21 MB), `numpy`, dan
`pillow`. TensorFlow **tidak** diperlukan — `ml_service` hanya memakainya
sebagai fallback bila `ai_edge_litert` tidak tersedia.

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

Buat akun demo untuk login dari aplikasi (`pengguna@gmail.com` / `skinscan123`, sama dengan akun demo di mobile):

```bash
python -m app.db.seed
```

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

### Login dan daftar

`POST /auth/login` dan `POST /auth/register` mengembalikan JWT dan data user.
Akun demo dibuat dengan `python -m app.db.seed`.

```bash
curl -X POST http://127.0.0.1:8000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"pengguna@gmail.com","password":"skinscan123","accepted_terms":true,"accepted_privacy":true}'

curl -X POST http://127.0.0.1:8000/auth/register \
  -H "Content-Type: application/json" \
  -d '{"full_name":"Budi Santoso","email":"budi@gmail.com","password":"rahasia123","accepted_terms":true,"accepted_privacy":true}'
```

**Kontrak API** = [`openapi.json`](openapi.json) (regenerate: `python scripts/export_openapi.py`).
Swagger UI: http://127.0.0.1:8000/docs. Konteks mobile/env/keamanan: [docs/api.md](../docs/api.md).

---

## Struktur folder

```text
backend/
├── AGENTS.md                # Aturan struktur kode + cara menambah API
├── CLAUDE.md                # Mengimpor AGENTS.md untuk Claude Code
├── openapi.json             # Snapshot kontrak OpenAPI (jangan edit manual)
├── scripts/
│   └── export_openapi.py    # Tulis ulang openapi.json dari app.openapi()
├── app/
│   ├── main.py              # Entry FastAPI + GET /health
│   ├── dependencies.py      # Depends (get_db)
│   ├── routers/             # Router API publik (auth, users, items, ml)
│   ├── internal/            # Modul internal/admin (reserved)
│   ├── core/                # Config, hashing password, JWT
│   ├── ml/artifacts/        # Model TFLite + labels + meta (di-commit)
│   ├── models/              # Model ORM (User)
│   ├── schemas/             # Schema Pydantic request/response
│   ├── services/            # Business logic (+ ml_service.py)
│   └── db/
│       ├── database.py      # Engine, session, Base
│       ├── seed.py          # Akun demo (python -m app.db.seed)
│       └── migrations/      # Script Alembic
├── tests/
├── alembic.ini
├── .env                     # Lokal saja (jangan commit)
├── .env.example             # Template env untuk tim
├── requirements.txt
├── requirements-ml.txt      # Runtime inferensi (ai-edge-litert, numpy, pillow)
├── run.sh
└── README.md
```

| Path | Fungsi |
|------|--------|
| `app/main.py` | Buat app FastAPI, daftar router, endpoint `/health` |
| `app/core/config.py` | Settings dari environment / `.env` |
| `app/db/database.py` | Engine SQLAlchemy + session |
| `app/db/migrations/` | Migrasi Alembic |
| `app/ml/artifacts/` | `dermascan_custom_cnn.tflite`, `labels`, `meta.json` |
| `app/models/` | Model ORM (`User` sudah ada) |
| `app/routers/` | Endpoint HTTP |
| `app/schemas/` | Bentuk request/respons (Pydantic) |
| `app/services/` | Logika bisnis (tanpa HTTP), termasuk `ml_service.py` |
| `tests/` | Automated tests |

---

## Model ML (inferensi)

`POST /ml/predict` menjalankan CNN Fadillah Dama untuk memprediksi keparahan
jerawat dari 1–3 foto wajah.

| Hal | Nilai |
|---|---|
| Model | `app/ml/artifacts/dermascan_custom_cnn.tflite` (421 KB, di-commit) |
| Asal | `machine-learning/Fadillah-Dama/deep_learning/` |
| Input | `[1, 160, 160, 3]` float32, piksel **0–255** (normalisasi di dalam model) |
| Output | softmax 5 kelas `IGA0`–`IGA4` → GEA 0–4 (GEA 5 tak pernah muncul) |
| Runtime | `ai_edge_litert.interpreter`, fallback `tensorflow.lite` |
| Kode | `app/services/ml_service.py`, `app/routers/ml.py`, `app/schemas/ml.py` |
| Test | `tests/test_ml.py` (unit + endpoint; dilewati bila runtime tidak ada) |

Catatan penting:

- Jangan pre-scale piksel ke 0–1 — model sudah punya `Rescaling(1./255)`.
- Interpreter TFLite tidak thread-safe; akses dibungkus `threading.Lock`.
- Model **tidak** boleh ditaruh di `backend/models/` — `.gitignore` mengabaikan
  folder itu. Simpan di `app/ml/artifacts/`.
- Regenerate kontrak setelah mengubah router/schema:
  `python scripts/export_openapi.py`.
- `backend/tests/test_ml.py::test_predictions_are_stable_for_a_fixed_photo`
  mengunci hasil untuk gambar tetap; kalau angka bergeser, preprocessing berubah.

---

## Scope saat ini

**Sudah ada**
- Skeleton FastAPI
- Config terpusat (`.env`)
- Koneksi PostgreSQL + migrasi Alembic
- Tabel `users`
- Dependency `get_db` dan `get_current_user` (Bearer JWT)
- Publik: `GET /health`, `POST /auth/login`, `POST /auth/register`, `POST /auth/google`
- Protected: `GET /users/status`, `GET /items/status`, `POST /ml/predict`
  (Authorize di Swagger)
- Inferensi CNN TFLite: 1–3 foto → grade GEA (mean softmax), tanpa menyimpan foto
- Google Sign-In: `GOOGLE_CLIENT_ID` (Web client) di `.env`
- Suite pytest + snapshot `openapi.json`

**Belum dikerjakan (deferred)**
- Profil, refresh token, logout, verifikasi email, lupa kata sandi
- Rate limit login, CORS
- Tabel analysis / images / results
- Cloudflare R2, upload gambar, penyimpanan riwayat diagnosa
- Deploy production

## Troubleshooting singkat

| Masalah | Solusi |
|---------|--------|
| `connection refused` port 5434 | Nyalakan Docker Desktop + container Postgres |
| `database "dermascan" does not exist` | Jalankan `CREATE DATABASE dermascan;` |
| `password authentication failed` | Samakan `DB_PASSWORD` di `.env` dengan password container |
| `ModuleNotFoundError` | Aktifkan `.venv` lalu `pip install -r requirements.txt` |
| `/ml/predict` → `503` | `pip install -r requirements-ml.txt` (runtime inferensi belum ada) |
| Test ML di-skip | Runtime TFLite atau file model tidak ada di `app/ml/artifacts/` |
| PowerShell: script disabled | `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned` |

## Next task yang disarankan

Scaffolding autentikasi (register/login + hashing password + JWT), dengan logic di `app/services/` dan router tetap tipis.
