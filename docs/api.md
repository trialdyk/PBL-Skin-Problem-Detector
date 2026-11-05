# Dokumentasi API Backend

Backend DermaScan (FastAPI) ada di folder [`backend/`](../backend/).

## Sumber kontrak API (wajib)

**Kontrak request/response, path, status code, dan schema ada di:**

| Sumber | Lokasi |
|---|---|
| Snapshot OpenAPI (commit) | [`backend/openapi.json`](../backend/openapi.json) |
| Live Swagger UI | `http://127.0.0.1:8000/docs` |
| Live schema JSON | `http://127.0.0.1:8000/openapi.json` |
| ReDoc | `http://127.0.0.1:8000/redoc` |

Jangan menulis ulang field/endpoint di dokumen ini dengan menebak dari kode
Python. Setelah endpoint berubah:

```bash
cd backend
python scripts/export_openapi.py
pytest tests/test_openapi.py
```

File `openapi.json` yang di-commit harus sama dengan `app.openapi()`. Test
`tests/test_openapi.py` akan gagal kalau snapshot ketinggalan.

Dokumen ini **hanya** menyimpan konteks yang tidak muat di OpenAPI (base URL
mobile, mapping ke layar Flutter, catatan keamanan, env).

Cara menjalankan backend: [backend/README.md](../backend/README.md).
Cara menambah endpoint: [backend/AGENTS.md](../backend/AGENTS.md).

## Ringkasan

| Hal | Nilai |
|---|---|
| Base URL (lokal) | `http://127.0.0.1:8000` |
| Format | JSON (`Content-Type: application/json`) |
| Autentikasi | Bearer JWT dari `/auth/login` atau `/auth/register`. Di Swagger: tombol **Authorize** → isi token. |
| Publik | `POST /auth/login`, `POST /auth/register`, `GET /health` |
| Protected | Semua route lain (saat ini `/users/*`, `/items/*`) via `Authorization: Bearer <token>` |
| Aplikasi mobile | Belum memanggil API ini; login di app masih mock |

Base URL dari aplikasi mobile:

| Klien | Base URL |
|---|---|
| Emulator Android | `http://10.0.2.2:8000` |
| iOS Simulator | `http://127.0.0.1:8000` |
| Perangkat fisik | `http://<IP-laptop>:8000`, jalankan server dengan `--host 0.0.0.0` (`run.sh` hanya mengikat `127.0.0.1`) |

## Endpoint saat ini

Daftar resmi = kunci `paths` di `backend/openapi.json`. Saat export terakhir:

| Method | Path | Auth | Catatan |
|---|---|---|---|
| `POST` | `/auth/login` | Publik | JWT + user |
| `POST` | `/auth/register` | Publik | Akun baru + JWT |
| `GET` | `/health` | Publik | Tanpa database |
| `GET` | `/users/status` | Bearer | Placeholder |
| `GET` | `/items/status` | Bearer | Placeholder |

Tanpa header / token invalid / user nonaktif → `401` dengan
`detail`: `Sesi tidak valid atau sudah berakhir. Silakan masuk kembali.`
dan header `WWW-Authenticate: Bearer`.

Detail field, contoh schema, dan response error: buka `openapi.json` atau `/docs`.

Belum ada: profil (`/users/me`), refresh token, logout, verifikasi email, lupa
kata sandi, login Google, riwayat diagnosa, dan endpoint inferensi model.

## Mapping ke aplikasi mobile

Kolom login mengikuti alur di
`mobile/lib/presentation/screens/login_screen.dart` dan `AuthService.login`.

| Field OpenAPI (`LoginRequest`) | Asal di app |
|---|---|
| `email` | Kolom "Email" |
| `password` | Kolom "Kata Sandi" |
| `accepted_terms` / `accepted_privacy` | App mengirim `true` otomatis (teks S&K di UI, bukan checkbox terpisah) |

Checkbox "Ingat saya" hanya state lokal dan **tidak** dikirim ke API.

Pesan `detail` string pada `400`/`401`/`409` berbahasa Indonesia dan boleh
ditampilkan app apa adanya. Respons `422` memakai format bawaan FastAPI
(`detail` berupa list, pesan Inggris) — jangan tampilkan langsung ke pengguna.

Akun demo seed (development): `pengguna@gmail.com` / `skinscan123`.

## Konfigurasi yang memengaruhi API

Dibaca dari environment atau `backend/.env` (template: `backend/.env.example`).
Ini tidak muncul di OpenAPI.

| Variabel | Bawaan | Keterangan |
|---|---|---|
| `APP_ENV` | `development` | Di luar `development`, `JWT_SECRET_KEY` wajib diisi atau server gagal start. Seed demo menolak jalan di luar `development`. |
| `DEBUG` | `true` | **Bawaan `true` apa pun nilai `APP_ENV`.** Lihat "Respons 500". |
| `JWT_SECRET_KEY` | nilai dev tetap | Wajib diganti di luar development. Pakai ≥ 32 byte acak. |
| `JWT_ALGORITHM` | `HS256` | |
| `JWT_EXPIRE_MINUTES` | `1440` | Masa berlaku token; menentukan `expires_in`. |
| `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD`, `DB_NAME`, `DB_SSL_MODE` | `localhost`, `5434`, `postgres`, kosong, `dermascan`, `disable` | Koneksi PostgreSQL. |

## Respons 500

Tidak ada penanganan khusus untuk error server. Jika database tidak terjangkau
saat auth, hasilnya `500`. Dengan `DEBUG=true` (bawaan), body-nya adalah
**traceback Python lengkap** (`text/plain`), bukan JSON. Dengan `DEBUG=false`,
body-nya hanya `Internal Server Error`. Klien harus menganggap `500` sebagai
kegagalan sementara dan tidak mem-parse body-nya.

## Catatan keamanan dan batasan saat ini

| Hal | Kondisi |
|---|---|
| `DEBUG` bawaan `true` | Di server non-lokal wajib `DEBUG=false`. |
| Validasi `422` memantulkan `input` | Kata sandi bisa ikut terpantul di body `422`. Hindari log body `422`. |
| Tanpa rate limit | Login/register bisa dicoba berulang; `409` pada register bisa dipakai menebak email terdaftar. |
| Tanpa verifikasi email | Akun baru langsung aktif. |
| Tanpa CORS | Flutter web beda origin akan diblokir; app mobile native tidak terpengaruh. |
| Hanya HTTP lokal | Di produksi pasang di belakang HTTPS. |
| `/docs` terbuka | Swagger tersedia tanpa autentikasi. |
| Email huruf kecil di DB | Login mencari email huruf kecil; `/auth/register` sudah menyimpan huruf kecil. |
| Tanpa refresh / logout server | Token berlaku sampai `exp`; logout app hanya hapus token di klien. |
