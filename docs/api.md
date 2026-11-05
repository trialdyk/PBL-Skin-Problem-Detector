# Dokumentasi API Backend

Backend DermaScan (FastAPI) ada di folder [`backend/`](../backend/). Dokumen ini
disusun dari kode yang ada dan sudah dicocokkan dengan server yang berjalan.
Cara menjalankan backend ada di [backend/README.md](../backend/README.md); cara
menambah endpoint baru ada di [backend/AGENTS.md](../backend/AGENTS.md).

## Ringkasan

| Hal | Nilai |
|---|---|
| Base URL (lokal) | `http://127.0.0.1:8000` |
| Format | JSON (`Content-Type: application/json`) |
| Dokumentasi interaktif | `/docs` (Swagger UI), `/redoc`, skema mentah di `/openapi.json` |
| Autentikasi | Bearer JWT, **diterbitkan** oleh `/auth/login` tetapi **belum diperiksa** endpoint mana pun |
| Aplikasi mobile | Belum memanggil API ini; login di app masih mock |

> Swagger di `/docs` dibuat otomatis dari kode (`backend/app/routers/`,
> `backend/app/schemas/`), jadi selalu mengikuti kode. Dokumen ini menambahkan
> aturan dan konteks yang tidak muat di Swagger.

Base URL dari aplikasi mobile:

| Klien | Base URL |
|---|---|
| Emulator Android | `http://10.0.2.2:8000` |
| iOS Simulator | `http://127.0.0.1:8000` |
| Perangkat fisik | `http://<IP-laptop>:8000`, jalankan server dengan `--host 0.0.0.0` (`run.sh` hanya mengikat `127.0.0.1`) |

## Daftar Endpoint

| Method | Path | Fungsi | Status |
|---|---|---|---|
| `POST` | `/auth/login` | Login email + kata sandi, mengembalikan JWT | Siap |
| `POST` | `/auth/register` | Buat akun baru, langsung mengembalikan JWT | Siap |
| `GET` | `/health` | Cek layanan hidup (tanpa database) | Siap |
| `GET` | `/users/status` | Penanda router terdaftar | Placeholder |
| `GET` | `/items/status` | Penanda router terdaftar | Placeholder |

Belum ada: profil (`/users/me`), refresh token, logout, verifikasi email, lupa
kata sandi, login Google, riwayat diagnosa, dan endpoint inferensi model.

---

## `POST /auth/login`

Kolom request mengikuti alur login di aplikasi
(`mobile/lib/presentation/screens/login_screen.dart` dan `AuthService.login`).

### Request body

| Field | Tipe | Wajib | Aturan | Asal di app |
|---|---|---|---|---|
| `email` | string | ya | Dipangkas spasi dan diubah ke huruf kecil. Maks 255 karakter. Format `nama@domain.tld` (`^[A-Za-z0-9_.+-]+@[A-Za-z0-9_-]+\.[A-Za-z0-9_.-]+$`), sama dengan validasi di app. Huruf non-ASCII ditolak. | Kolom "Email" |
| `password` | string | ya | 1 sampai 128 karakter. Tidak dipangkas, spasi dihitung. | Kolom "Kata Sandi" |
| `accepted_terms` | boolean | ya | Harus `true`/`false` sungguhan. String seperti `"yes"` atau angka `1` ditolak (`422`). | Tidak ada checkbox; app mengisi `true` saat tombol "Masuk ke Akun" ditekan |
| `accepted_privacy` | boolean | ya | Sama seperti di atas. | Sama seperti di atas |

Layar login saat ini hanya punya kolom Email dan Kata Sandi. Persetujuan
Syarat & Ketentuan dan Kebijakan Privasi ditampilkan sebagai teks ("Dengan
masuk, Anda menyetujui ..."), lalu app mengirim kedua flag `true` secara
otomatis. Checkbox "Ingat saya" hanya menyimpan state lokal dan **tidak**
dikirim ke API.

```json
{
  "email": "pengguna@gmail.com",
  "password": "skinscan123",
  "accepted_terms": true,
  "accepted_privacy": true
}
```

### Respons `200 OK`

```json
{
  "access_token": "<jwt>",
  "token_type": "bearer",
  "expires_in": 86400,
  "user": {
    "id": "2f332d15-4f0e-41e8-94fa-40524372162c",
    "email": "pengguna@gmail.com",
    "full_name": "Pengguna Demo"
  }
}
```

| Field | Keterangan |
|---|---|
| `access_token` | JWT HS256. Klaim: `sub` (id user, UUID), `iat`, `exp` (detik sejak epoch). Tidak ada klaim lain. |
| `token_type` | Selalu `"bearer"`. |
| `expires_in` | Masa berlaku dalam **detik** (`JWT_EXPIRE_MINUTES` × 60, bawaan 86400 = 24 jam). |
| `user.id` | UUID user. |
| `user.email` | Email dalam huruf kecil. |
| `user.full_name` | String atau `null`. |

Hash kata sandi tidak pernah dikirim.

### Kode status

Urutan pemeriksaan: validasi bentuk body (`422`) → persetujuan (`400`) →
kredensial (`401`).

| Status | Kapan | Bentuk `detail` |
|---|---|---|
| `200` | Kredensial benar dan akun aktif | (lihat di atas) |
| `400` | `accepted_terms` atau `accepted_privacy` bernilai `false` (app tidak pernah mengirim ini) | string |
| `401` | Email tidak terdaftar, kata sandi salah, atau akun nonaktif (`is_active = false`) | string |
| `405` | Method selain `POST` (header `Allow: POST`) | string |
| `422` | Body tidak valid: field kosong, hilang, salah tipe, format email salah, melebihi batas, atau bukan JSON | **list** |
| `500` | Kesalahan server, mis. database tidak terjangkau | lihat "Respons 500" |

Karena urutan di atas: persetujuan `false` menghasilkan `400` meskipun kata
sandinya salah, dan email berformat salah menghasilkan `422` meskipun
persetujuan `false`.

**`400`** (teks siap ditampilkan ke pengguna):

```json
{ "detail": "Centang Syarat & Ketentuan serta Kebijakan Privasi terlebih dahulu." }
```

**`401`** (header `WWW-Authenticate: Bearer`). Pesan sama untuk email tidak
terdaftar, kata sandi salah, dan akun nonaktif, supaya tidak membocorkan email
mana yang terdaftar:

```json
{ "detail": "Email atau kata sandi salah. Periksa kembali." }
```

**`422`** adalah format bawaan FastAPI. `detail` di sini berupa **list**, bukan
string, dan pesannya berbahasa Inggris, jadi **jangan ditampilkan langsung ke
pengguna**. Form di app sudah memvalidasi email dan kolom kosong sebelum
mengirim, sehingga `422` seharusnya tidak muncul pada pemakaian normal.

```json
{
  "detail": [
    {
      "type": "missing",
      "loc": ["body", "accepted_privacy"],
      "msg": "Field required",
      "input": { "email": "pengguna@gmail.com", "password": "skinscan123", "accepted_terms": true }
    }
  ]
}
```

Perhatikan: field `input` memantulkan nilai yang dikirim klien, termasuk kata
sandi. Lihat "Catatan keamanan".

### Contoh `curl`

```bash
curl -X POST http://127.0.0.1:8000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"pengguna@gmail.com","password":"skinscan123","accepted_terms":true,"accepted_privacy":true}'
```

### Akun demo

Buat akun yang sama dengan mock di app (hanya untuk `APP_ENV=development`):

```bash
cd backend
python -m app.db.seed
```

| Email | Kata sandi | Nama |
|---|---|---|
| `pengguna@gmail.com` | `skinscan123` | Pengguna Demo |

Perintah ini aman dijalankan berulang (akun yang sudah ada dilewati).

### Memakai token

Token sudah diterbitkan, tetapi **belum ada endpoint yang memverifikasinya**
(belum ada fungsi decode di `app/core/security.py` maupun dependency
`get_current_user`). Klien sebaiknya menyimpan token dan mengirimnya sebagai
`Authorization: Bearer <access_token>` untuk endpoint terlindungi di masa depan.
Langkah menambah endpoint terlindungi ada di
[backend/AGENTS.md](../backend/AGENTS.md).

---

## `POST /auth/register`

Membuat akun lalu langsung masuk: respons sama dengan login (token + user), jadi
app tidak perlu memanggil `/auth/login` lagi.

> Aplikasi mobile belum punya layar daftar; tautan "Daftar Sekarang" di layar
> login masih menampilkan toast "belum tersedia". Field di bawah mengikuti tabel
> `users` dan pola login, bukan layar yang sudah ada. Sesuaikan jika desain
> layar daftar berbeda.

### Request body

| Field | Tipe | Wajib | Aturan |
|---|---|---|---|
| `full_name` | string | tidak | Nama tampilan. Dipangkas spasi, 1 sampai 255 karakter. Jika tidak dikirim, tersimpan `null`. String kosong atau hanya spasi ditolak (`422`). |
| `email` | string | ya | Aturan sama dengan login: dipangkas, diubah ke huruf kecil, maks 255 karakter, format `nama@domain.tld`. |
| `password` | string | ya | **8 sampai 128 karakter.** Tidak dipangkas. |
| `accepted_terms` | boolean | ya | Boolean sungguhan dan harus `true`. |
| `accepted_privacy` | boolean | ya | Boolean sungguhan dan harus `true`. |

Konfirmasi kata sandi (dua kali ketik) cukup dicek di sisi app; server tidak
menerimanya.

```json
{
  "full_name": "Budi Santoso",
  "email": "budi@gmail.com",
  "password": "rahasia123",
  "accepted_terms": true,
  "accepted_privacy": true
}
```

### Respons `201 Created`

Bentuknya sama dengan respons login (`access_token`, `token_type`,
`expires_in`, `user`), dengan `user.email` dalam huruf kecil dan `user.full_name`
sesuai input (atau `null`).

### Kode status

Urutan pemeriksaan: validasi bentuk body (`422`) → persetujuan (`400`) →
email sudah dipakai (`409`).

| Status | Kapan | Bentuk `detail` |
|---|---|---|
| `201` | Akun dibuat | (lihat di atas) |
| `400` | `accepted_terms` atau `accepted_privacy` bernilai `false` | string |
| `409` | Email sudah punya akun (tidak peduli huruf besar/kecil atau spasi di tepi) | string |
| `422` | Body tidak valid: kata sandi < 8 atau > 128 karakter, email salah format, nama kosong/terlalu panjang, tipe salah, field wajib hilang, atau bukan JSON | **list** |

Pesan `400` sama dengan login. Pesan `409` siap ditampilkan:

```json
{ "detail": "Email sudah terdaftar. Silakan masuk." }
```

`422` berformat sama seperti di login dan tidak boleh ditampilkan langsung.

### Contoh `curl`

```bash
curl -X POST http://127.0.0.1:8000/auth/register \
  -H "Content-Type: application/json" \
  -d '{"full_name":"Budi Santoso","email":"budi@gmail.com","password":"rahasia123","accepted_terms":true,"accepted_privacy":true}'
```

### Catatan

- Dua permintaan bersamaan dengan email yang sama: tepat satu yang `201`, sisanya
  `409`. Penentunya indeks unik `users.email` di database, bukan pemeriksaan di kode.
- `409` memberi tahu bahwa email sudah terdaftar. Itu tak terhindarkan pada
  pendaftaran; login sengaja memakai satu pesan umum agar tidak ikut membocorkan.
- Kata sandi disimpan sebagai hash Argon2. Akun baru langsung aktif; belum ada
  verifikasi email.
- Aturan kata sandi (min 8) hanya berlaku saat daftar. Login tetap menerima
  1 sampai 128 karakter agar akun lama (mis. akun demo) tetap bisa masuk.

---

## `GET /health`

Tidak menyentuh database, jadi tetap `200` walaupun Postgres mati.

```json
{ "status": "ok", "service": "dermascan-backend" }
```

## `GET /users/status` dan `GET /items/status`

Placeholder yang hanya membuktikan router terdaftar. Tanpa autentikasi, tanpa
database. Bentuk respons `/users/status`:

```json
{
  "router": "users",
  "status": "registered",
  "note": "Placeholder only — no user business features in PBL-04"
}
```

`/items/status` sama, dengan `"router": "items"`.

---

## Konfigurasi yang memengaruhi API

Dibaca dari environment atau `backend/.env` (template: `backend/.env.example`).

| Variabel | Bawaan | Keterangan |
|---|---|---|
| `APP_ENV` | `development` | Di luar `development`, `JWT_SECRET_KEY` wajib diisi atau server gagal start. Seed demo menolak jalan di luar `development`. |
| `DEBUG` | `true` | **Bawaan `true` apa pun nilai `APP_ENV`.** Lihat "Respons 500". |
| `JWT_SECRET_KEY` | nilai dev tetap | Wajib diganti di luar development. Panjang tidak divalidasi; pakai ≥ 32 byte acak. |
| `JWT_ALGORITHM` | `HS256` | |
| `JWT_EXPIRE_MINUTES` | `1440` | Masa berlaku token; menentukan `expires_in`. |
| `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD`, `DB_NAME`, `DB_SSL_MODE` | `localhost`, `5434`, `postgres`, kosong, `dermascan`, `disable` | Koneksi PostgreSQL. |

## Respons 500

Tidak ada penanganan khusus untuk error server. Jika database tidak terjangkau
saat `POST /auth/login`, hasilnya `500`. Dengan `DEBUG=true` (bawaan), body-nya
adalah **traceback Python lengkap** (`text/plain`, belasan KB), bukan JSON.
Dengan `DEBUG=false`, body-nya hanya `Internal Server Error`. Klien harus
menganggap `500` sebagai "login gagal, coba lagi" dan tidak mem-parse body-nya.

## Catatan keamanan dan batasan saat ini

| Hal | Kondisi |
|---|---|
| `DEBUG` bawaan `true` | Di server non-lokal wajib `DEBUG=false`, kalau tidak traceback bocor di respons `500`. |
| Validasi `422` memantulkan `input` | Kata sandi yang dikirim bisa ikut terpantul di body `422` (mis. kata sandi > 128 karakter atau field lain hilang). Hindari mencatat body respons `422` di log. |
| Tanpa pembatasan percobaan | Belum ada rate limit atau penguncian akun; login bisa dicoba berulang, dan `/auth/register` bisa dipakai membuat akun tanpa batas serta menebak email yang terdaftar lewat `409`. |
| Tanpa verifikasi email | Akun baru langsung aktif dan mendapat token, dengan email apa pun yang formatnya valid. |
| Tanpa CORS | Panggilan dari browser (mis. Flutter web) lain origin akan diblokir; `OPTIONS /auth/login` menghasilkan `405`. Aplikasi mobile tidak terpengaruh. |
| Hanya HTTP lokal | `uvicorn` tidak memakai TLS. Di produksi pasang di belakang HTTPS. |
| `/docs` terbuka | Swagger tersedia tanpa autentikasi. |
| Email harus huruf kecil di database | Login mencari `email` persis dalam huruf kecil. `/auth/register` sudah menyimpan huruf kecil; akun yang dibuat lewat jalur lain (SQL manual, seed baru) harus melakukan hal yang sama. |
| Tanpa refresh token / logout | Token berlaku sampai `exp`; logout di app hanya menghapus token di sisi klien. |
