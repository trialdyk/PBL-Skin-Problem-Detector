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
| Autentikasi | Bearer JWT dari `/auth/login`, `/auth/register`, atau `/auth/google`. Di Swagger: tombol **Authorize** → isi token. |
| Publik | `POST /auth/login`, `POST /auth/register`, `POST /auth/google`, `GET /health` |
| Protected | Semua route lain (saat ini `/users/*`, `/items/*`, `/ml/*`) via `Authorization: Bearer <token>` |
| Aplikasi mobile | **Sudah** memanggil API lewat `mobile/lib/data/services/auth/` (`POST /auth/login`, `/auth/register`, `/auth/google`) dan `mobile/lib/data/services/ml/` (`POST /ml/predict`); Bearer token otomatis pada request `auth: true` |

Base URL aplikasi mobile (dibaca dari `mobile/lib/core/api_config.dart`, bukan
hard-code di layar):

| Item | Nilai |
|---|---|
| Bawaan (produksi) | `https://pbl.trialdyk.my.id` |
| Override | `flutter run --dart-define=API_BASE_URL=...` |
| Emulator Android | `http://10.0.2.2:8000` |
| iOS Simulator | `http://127.0.0.1:8000` |
| Perangkat fisik | `http://<IP-laptop>:8000`, jalankan server dengan `--host 0.0.0.0` (`run.sh` hanya mengikat `127.0.0.1`) |

## Endpoint saat ini

Daftar resmi = kunci `paths` di `backend/openapi.json`. Saat export terakhir:

| Method | Path | Auth | Catatan |
|---|---|---|---|
| `POST` | `/auth/login` | Publik | JWT + user |
| `POST` | `/auth/register` | Publik | Akun baru + JWT |
| `POST` | `/auth/google` | Publik | Tukar Google `id_token` → JWT |
| `GET` | `/health` | Publik | Tanpa database |
| `GET` | `/users/status` | Bearer | Placeholder |
| `GET` | `/items/status` | Bearer | Placeholder |
| `POST` | `/ml/predict` | Bearer | Prediksi keparahan jerawat (CNN) → grade GEA |

Tanpa header / token invalid / user nonaktif → `401` dengan
`detail`: `Sesi tidak valid atau sudah berakhir. Silakan masuk kembali.`
dan header `WWW-Authenticate: Bearer`.

Detail field, contoh schema, dan response error: buka `openapi.json` atau `/docs`.

Belum ada: profil (`/users/me`), refresh token, logout, verifikasi email, lupa
kata sandi, dan riwayat diagnosa.

## `POST /ml/predict` — catatan di luar OpenAPI

Endpoint ini menerima **multipart/form-data**, jadi `Content-Type` bukan JSON.

| Hal | Nilai |
|---|---|
| Field berkas | `files` (boleh diulang; nama field di klien: `MlPredict.fileField`) |
| Jumlah berkas | 1–3 (depan, kiri, kanan). Lebih dari 3 → `400` |
| Ukuran per berkas | maks. `ML_MAX_UPLOAD_MB` (bawaan 10 MB) → lewat batas `413` |
| Format | JPEG/PNG/WebP apa pun yang bisa dibaca Pillow; file rusak → `400` |
| Penyimpanan | Foto diproses di memori, **tidak** disimpan ke disk/DB |
| Model | `dermascan-custom-cnn-v1` (`backend/app/ml/artifacts/dermascan_custom_cnn.tflite`) |
| Keluaran model | softmax 5 kelas `IGA0`–`IGA4`, dipetakan 1:1 ke GEA 0–4 |
| Agregasi | rata-rata (mean) probabilitas semua foto → `aggregate.grade` |
| Waktu | ± 20–80 ms/foto di CPU (terukur ~23 ms/foto 720×720); permintaan pertama menambah waktu muat model; klien memakai timeout 60 s |
| Runtime mati | `503` `Layanan analisis belum siap. Coba lagi nanti.` |

Grade **5 tidak pernah** dihasilkan model karena model hanya punya 5 kelas
(`IGA0`–`IGA4`). Kalau `503`/error jaringan, aplikasi jatuh ke diagnosa
rule-based dari interview (`GeaDiagnosisService`) dan menandai hasilnya dengan
`ResultSource.ruleBased`.

## Mapping ke aplikasi mobile

Implementasi ada di `mobile/lib/data/services/auth/` (satu file per endpoint):

| Endpoint | File Flutter | Dipakai layar |
|---|---|---|
| `POST /auth/login` | `auth/auth_login.dart` | `LoginScreen` (email + kata sandi) |
| `POST /auth/google` | `auth/auth_google.dart` | `LoginScreen` (tombol Google) |
| `POST /auth/register` | `auth/auth_register.dart` | `RegisterScreen` → `AuthCubit.register` → `AuthRepository.register`; sukses langsung ke beranda |
| `POST /ml/predict` | `ml/ml_predict.dart` | `DiagnosisScreen` (lewat `ScanRepository`) |

Field yang dikirim (schema: `LoginRequest` / `RegisterRequest` /
`GoogleLoginRequest`):

| Field OpenAPI | Asal di app |
|---|---|
| `email` | Kolom "Email" (`trim()` di klien; server men-*lowercase*) |
| `password` | Kolom "Kata Sandi" |
| `full_name` | Input Nama Lengkap pada halaman register |
| `accepted_terms` / `accepted_privacy` | Register mewajibkan checkbox persetujuan sebelum mengirim `true`; login memakai persetujuan lewat teks di UI |
| `id_token` | Hanya `/auth/google`, dari `GoogleSignIn` dengan `serverClientId` = Web client ID |

Checkbox "Ingat saya" hanya state lokal dan **tidak** dikirim ke API.

`access_token` dari respons disimpan di `ApiClient` dan dipakai otomatis saat
memanggil endpoint dengan `auth: true` (contoh: `GET /users/status` lewat
`services/scan/`). Token tidak di-persist, jadi restart aplikasi berarti login
ulang.

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
| `GOOGLE_CLIENT_ID` | kosong | Web OAuth Client ID; wajib untuk `POST /auth/google`. |
| `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD`, `DB_NAME`, `DB_SSL_MODE` | `localhost`, `5434`, `postgres`, kosong, `dermascan`, `disable` | Koneksi PostgreSQL. |
| `ML_MODEL_PATH` | `app/ml/artifacts/dermascan_custom_cnn.tflite` | Path model; relatif dihitung dari `backend/`. |
| `ML_INPUT_SIZE` | `160` | Sisi gambar yang di-*resize* (harus sama dengan training). |
| `ML_MAX_UPLOAD_MB` | `10` | Batas ukuran per berkas di `/ml/predict`. |

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
