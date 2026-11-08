# AGENTS.md — Backend DermaScan

Panduan untuk developer dan AI agent yang mengubah kode di folder `backend/`.
Ikuti struktur dan langkah di sini supaya endpoint baru konsisten dengan yang
sudah ada.

## Sumber kebenaran dokumentasi API

| Prioritas | File / URL | Isi |
|---|---|---|
| **1 (kontrak)** | [`openapi.json`](openapi.json) | Path, method, schema request/response, status code, tag |
| **2 (UI)** | `/docs`, `/openapi.json` live | Sama dengan snapshot; harus sinkron |
| **3 (konteks)** | [`docs/api.md`](../docs/api.md) | Base URL mobile, mapping Flutter, env, catatan keamanan — **bukan** salinan field dari kode |

**Wajib untuk agent:**

- Baca / tulis kontrak API lewat `openapi.json` (atau regenerate lalu baca file itu).
- **Jangan** menyusun dokumentasi endpoint dengan menebak dari `routers/` / `schemas/` lalu menempelkannya ke markdown tanpa export OpenAPI.
- Setiap perubahan router, schema, `response_model`, `responses={...}`, `summary`, docstring operasi, atau `openapi_tags` di `main.py` **harus** diikuti:
  1. `python scripts/export_openapi.py`
  2. Sesuaikan `docs/api.md` hanya untuk konteks non-OpenAPI (mobile, keamanan, env) bila perlu
  3. `pytest tests/test_openapi.py` (atau `pytest` penuh) — test gagal jika snapshot stale

## Ringkasan

- FastAPI + Pydantic v2, SQLAlchemy 2.0 (gaya `Mapped[...]`), Alembic, PostgreSQL (psycopg3).
- Python 3.10+ (disarankan 3.12). Jangan pakai fitur yang baru ada di 3.11+ (mis. `datetime.UTC`).
- Dipanggil oleh aplikasi Flutter di `../mobile/`. Teks yang tampil ke pengguna
  berbahasa Indonesia; docstring dan komentar kode berbahasa Inggris.
- Sudah jadi: `GET /health`, `POST /auth/login`, `POST /auth/register`,
  `POST /auth/google` (**publik**); `GET /users/status`, `GET /items/status`
  (**protected**, Bearer JWT via `get_current_user`). `users`/`items` masih placeholder bisnis.
- Google: `GOOGLE_CLIENT_ID` (Web client) di `.env`; Flutter memakai `serverClientId` yang sama.
- Belum ada: profil (`/users/me`), verifikasi email, rate limit, CORS.

## Perintah

Jalankan dari folder `backend/` dengan virtualenv aktif.

```bash
python -m venv .venv
.venv\Scripts\Activate.ps1          # Windows PowerShell; macOS/Linux: source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env                # lalu isi DB_PASSWORD

alembic upgrade head                # butuh Postgres di port 5434 (Docker)
python -m app.db.seed               # akun demo pengguna@gmail.com / skinscan123
./run.sh                            # http://127.0.0.1:8000, Swagger di /docs

python scripts/export_openapi.py    # tulis ulang openapi.json dari app.openapi()
pytest                              # termasuk tests/test_openapi.py (snapshot harus cocok)
alembic upgrade head --sql          # cek migrasi tanpa database
```

## Struktur dan tanggung jawab

```
app/
├── main.py            # Buat FastAPI, include_router, openapi_tags, GET /health
├── dependencies.py    # get_db, get_current_user (Bearer JWT)
├── routers/           # Lapisan HTTP: 1 file per domain
├── schemas/           # Pydantic: bentuk request dan respons
├── services/          # Logika bisnis dan query database
├── models/            # ORM SQLAlchemy; diekspor di models/__init__.py
├── ml/artifacts/      # Model TFLite + labels + meta.json (bukan kode; di-commit)
├── core/              # config.py (Settings), security.py (hash password, JWT)
├── db/                # database.py (engine, session, Base), seed.py, migrations/
└── internal/          # Cadangan untuk endpoint admin; jangan dipakai dulu
tests/                 # pytest; satu file test per domain
```

Arah dependensi satu arah: `routers → services → models`. `routers` dan
`services` boleh memakai `schemas` dan `core`. Jangan sebaliknya.

| Lapisan | Boleh | Dilarang |
|---|---|---|
| `routers/` | Parse input lewat schema, panggil service, ubah hasil jadi respons, `raise HTTPException` dengan kode status dan pesan Indonesia | Query SQLAlchemy langsung, logika bisnis, hashing password |
| `services/` | Terima `db: Session` dan argumen biasa, query, aturan bisnis, kembalikan objek model atau `None`; untuk kegagalan yang perlu dibedakan, `raise` exception domain buatan sendiri (mis. `EmailAlreadyRegisteredError`) | Import dari `fastapi`, `HTTPException`, objek `Request`, `commit` tanpa alasan jelas |
| `schemas/` | Validasi dan bentuk JSON; `ConfigDict(from_attributes=True)` untuk respons dari ORM | Field `password_hash` atau rahasia lain di respons |
| `models/` | Kolom, relasi, indeks | Logika bisnis |

Satu file per domain di tiap lapisan, dengan nama yang sama:
`routers/auth.py`, `schemas/auth.py`, `services/auth_service.py`, `tests/test_auth.py`.

## Langkah menambah endpoint

Contoh acuan: `POST /auth/login` (`routers/auth.py`, `schemas/auth.py`,
`services/auth_service.py`, `tests/test_auth.py`).

1. **Tentukan kontrak dulu.** Method, path, field request/respons, dan kode
   status tiap kondisi. Jika dipakai app mobile, cocokkan nama field dan teks
   dengan layar terkait di `../mobile/lib/`. **Jangan** menulis tabel field ke
   `docs/api.md` sebagai sumber kontrak — kontrak akan muncul di OpenAPI setelah
   schema/router siap dan di-export.
2. **Schema** di `app/schemas/<domain>.py`.
   - Request: batasi dengan `Field(min_length=..., max_length=...)`; pakai
     `StrictBool` untuk flag persetujuan agar `"yes"`/`1` tidak lolos.
   - Respons: model terpisah dari request; jangan sertakan `password_hash`.
   - Untuk respons error (400, 401, 404, ...) pakai `ErrorResponse` dari `schemas/auth.py`
     (pindahkan ke modul bersama bila dipakai lebih dari satu domain).
3. **Model dan migrasi** hanya bila tabel atau kolom berubah.
   - Tambah model di `app/models/<nama>.py` dan **ekspor di `app/models/__init__.py`**
     (Alembic membaca model dari sana).
   - Buat migrasi: `alembic revision --autogenerate -m "deskripsi" --rev-id YYYYMMDD_NNNN`
     (mengikuti `20260316_0001`). Baca hasilnya sebelum dipakai; jangan percaya
     autogenerate begitu saja. Jangan mengubah migrasi yang sudah dipakai orang lain.
   - Pakai tipe generik SQLAlchemy di model (`Uuid`, `DateTime`) agar test
     SQLite tetap jalan. Tipe khusus Postgres boleh hanya di file migrasi.
4. **Service** di `app/services/<domain>_service.py`: fungsi biasa dengan
   `db: Session` sebagai argumen pertama. Kembalikan hasil atau `None`, atau
   `raise` exception domain; biarkan router yang memutuskan kode status. Untuk
   aturan keunikan, andalkan indeks unik database dan tangkap `IntegrityError`
   (lihat `register`), bukan pemeriksaan "cek dulu baru insert" yang bisa kalah balapan.
5. **Router** di `app/routers/<domain>.py`.
   - `router = APIRouter(prefix="/<domain>", tags=["<domain>"])`.
   - Handler tipis. Ambil sesi dengan `db: Session = Depends(get_db)` dari `app.dependencies`.
   - Anotasi tipe return dengan schema respons (itu yang menjadi `response_model`).
   - Tiap `HTTPException` yang bisa muncul dideklarasikan di `responses={kode: {"model": ErrorResponse, "description": ...}}`
     agar masuk ke OpenAPI/Swagger. Beri `summary`. Tulis docstring yang menjelaskan urutan pemeriksaan.
   - Pesan `detail` untuk pengguna berbahasa Indonesia dan boleh ditampilkan app apa adanya.
6. **Daftarkan** di `app/main.py`: `app.include_router(<domain>.router)`, lalu
   tambahkan tag-nya ke `openapi_tags`.
7. **Endpoint terlindungi** (butuh login). Pakai dependency yang sudah ada; jangan buat ulang:
   - `decode_access_token` di `core/security.py`, `get_current_user` di `dependencies.py`
     (`HTTPBearer`, header `Authorization: Bearer`, `401` + `WWW-Authenticate: Bearer`).
   - Pasang `dependencies=[Depends(get_current_user)]` di `APIRouter` domain, atau
     `Depends(get_current_user)` di handler bila butuh objek `User`.
   - Deklarasikan respons `401` dengan `ErrorResponse`. **Jangan** lindungi
     `/auth/login`, `/auth/register`, atau `/health`.
8. **Test** di `tests/test_<domain>.py` (lihat pola di `tests/test_auth.py`):
   - SQLite in-memory (`StaticPool`) dan `app.dependency_overrides[get_db]`, bukan Postgres sungguhan.
   - Uji jalur sukses, tiap kode error, dan validasi input (batas panjang, tipe salah).
   - Bersihkan override setelah test.
9. **Dokumentasi dari Swagger (wajib, jangan dilewati).**
   - Jalankan `python scripts/export_openapi.py` → memperbarui `openapi.json`.
   - Commit `openapi.json` bersama perubahan kode.
   - Perbarui `docs/api.md` **hanya** untuk konteks di luar OpenAPI (mapping mobile,
     env baru, catatan keamanan). Jangan menyalin ulang seluruh schema ke markdown.
   - Perbarui `README.md` bila langkah setup berubah.
   - Opsional: buka `/docs` untuk cek visual; sumber yang di-commit tetap `openapi.json`.
10. **Verifikasi sebelum commit**: `pytest` hijau (termasuk `tests/test_openapi.py`),
    `alembic upgrade head --sql` berhasil bila ada migrasi, dan `git status`
    menunjukkan `openapi.json` ikut berubah bila kontrak API berubah
    (lihat jebakan `.gitignore` di bawah).

## Aturan penting

- **Rahasia.** Jangan commit `.env`. Jangan log atau kembalikan kata sandi,
  hash, atau token. `JWT_SECRET_KEY` wajib diisi di luar `APP_ENV=development`.
- **Kata sandi** lewat `hash_password` / `verify_password` (Argon2) di `core/security.py`.
  Batas panjang 128 di schema.
- **Jangan bocorkan akun.** Login mengembalikan satu pesan yang sama untuk email
  tak terdaftar, kata sandi salah, dan akun nonaktif, dan tetap memverifikasi
  hash dummy agar waktunya mirip. Pertahankan pola ini di endpoint serupa.
- **Email disimpan huruf kecil.** Login mencari persis huruf kecil. Setiap kode
  yang menulis `users.email` harus menurunkan huruf dulu; lewat schema `Email`
  (`schemas/auth.py`) hal itu otomatis, jadi pakai tipe itu untuk field email baru.
- **Kata sandi saat daftar minimal 8 karakter, saat login 1 sampai 128.** Jangan
  samakan keduanya, atau akun lama dengan kata sandi pendek tidak bisa masuk.
- **Konfigurasi** lewat `Settings` di `core/config.py`, bukan `os.environ` langsung.
  Tambah variabel baru juga ke `.env.example` dan tabel konfigurasi di `docs/api.md`
  (env tidak masuk OpenAPI). `get_settings()` di-cache (`lru_cache`); di test buat
  `Settings(..., _env_file=None)` langsung.
- **OpenAPI stale = bug.** Jangan commit perubahan API tanpa `openapi.json` baru.
  Jangan edit `openapi.json` manual; selalu lewat `scripts/export_openapi.py`.
- **`DEBUG` bawaan `true`** dan menampilkan traceback penuh di respons `500`.
  Di server non-lokal set `DEBUG=false`.
- **Kontrak dengan app mobile.** Teks `detail` untuk `400`/`401` tampil ke pengguna
  dan nama field dipakai Flutter. Mengubahnya berarti mengubah `../mobile/` juga.
  `422` memakai format bawaan FastAPI (`detail` berupa list, pesan Inggris) dan tidak boleh ditampilkan langsung.
- **Google Sign-In.** `GOOGLE_CLIENT_ID` = Web client ID. Flutter `serverClientId`
  harus sama. Migrasi `20261105_0002` menambah `auth_provider` / `google_sub` dan
  membuat `password_hash` nullable. Setelah pull: `alembic upgrade head`.
- **Jangan melebarkan `.gitignore`.** Aturan `/models/` sengaja diberi `/` di depan.
  Versi tanpa `/` pernah menyembunyikan `app/models/` dari git dan merusak Alembic
  untuk semua orang. Setelah menambah folder baru, cek dengan `git status` atau `git check-ignore -v <path>`.
- **Gaya kode.** Type hint di semua fungsi, `X | None` bukan `Optional[X]`,
  docstring singkat di fungsi publik, tanpa komentar yang hanya mengulang kode.
- **Inferensi ML.** Model ada di `app/ml/artifacts/` (bukan `models/`, folder itu
  di-ignore). Kontrak model: input `[1,160,160,3]` float32 piksel **0–255**,
  output softmax 5 kelas `IGA0`–`IGA4`. Jangan menambah `/255` di service —
  `Rescaling` ada di dalam model. Interpreter TFLite tidak thread-safe: akses
  lewat `ml_service` (`threading.Lock`), jangan membuat `Interpreter` baru per
  request. Dependensi inferensi ada di `requirements-ml.txt` (bukan
  `requirements.txt`), dan `ai-edge-litert` diutamakan di atas TensorFlow.
  Setelah mengubah model/preprocessing, jalankan `pytest tests/test_ml.py`
  (golden test akan gagal bila preprocessing bergeser).
- **Sebelum menganggap selesai**, jalankan `pytest` dan baca hasilnya. Jangan
  klaim "sudah jalan" untuk hal yang butuh Postgres kalau Postgres tidak dinyalakan.

## Commit

Format: `tipe(lingkup) : deskripsi singkat`, mis. `feat(backend) : add login endpoint`.
Satu perubahan logis per commit. Jangan menambahkan baris `Co-Authored-By`.
