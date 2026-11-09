# SkinScan ID / DermaScan — Aplikasi Flutter

Aplikasi Flutter untuk mendeteksi tingkat keparahan jerawat berdasarkan skala
**GEA (Global Evaluation of Acne)** 0–5. Paket: `pbl_skin_problem_detector`.

> ⚠️ Hasil bersifat informatif, **bukan** pengganti diagnosis dokter.

## Tech Stack

| Layer | Teknologi |
|---|---|
| Framework | Flutter + Dart (SDK `^3.13.2`) |
| UI | [`shadcn_flutter`](https://pub.dev/packages/shadcn_flutter) `^0.0.55` |
| State management | **Cubit** (`flutter_bloc`) |
| Navigasi | `go_router` |
| Kamera / galeri | `camera`, `image_picker` |
| Deteksi wajah | `google_mlkit_face_detection` (kualitas foto, bukan klasifikasi lesi) |
| Autentikasi | HTTP ke backend FastAPI (`http`) + `google_sign_in` |
| Inferensi | HTTP multipart ke `POST /ml/predict` (CNN TFLite di backend) |
| Font | Plus Jakarta Sans (`google_fonts`) |
| Entry point | `lib/main.dart` |

## Konfigurasi Backend

Dipusatkan di `lib/core/api_config.dart`; jangan menaruh URL di widget/service.

| Item | Nilai bawaan |
|---|---|
| `API_BASE_URL` | `https://pbl.trialdyk.my.id` |
| `GOOGLE_SERVER_CLIENT_ID` | Web OAuth client ID (harus sama dengan `GOOGLE_CLIENT_ID` di backend) |

Override saat menjalankan / build:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

| Klien | Base URL lokal |
|---|---|
| Emulator Android | `http://10.0.2.2:8000` |
| iOS Simulator | `http://127.0.0.1:8000` |
| Perangkat fisik | `http://<IP-laptop>:8000` (server jalan dengan `--host 0.0.0.0`) |

## Menjalankan

```bash
cd mobile
flutter pub get
flutter run
```

Uji & analisis sebelum commit:

```bash
flutter analyze    # harus "No issues found!"
flutter test       # harus "All tests passed!"
```

Akun demo (dari `python -m app.db.seed` di backend) — `pengguna@gmail.com` /
`skinscan123`.

## Struktur Folder

```text
lib/
├── data/          # models, repositories, services (auth/, ml/, scan/)
├── presentation/  # screens, widgets, theme
├── business/      # cubit/ (state management) — bloc/ masih placeholder
├── core/          # api_config.dart (base URL + Google client ID)
├── app_router.dart
└── main.dart
```

Arah dependensi: `presentation → business → data`. Penjelasan lengkap ada di
[`../docs/arsitektur.md`](../docs/arsitektur.md) dan
[`../docs/struktur-folder.md`](../docs/struktur-folder.md).

## Warna & Tema

Tema **krem hangat + sage + terakota**. Semua token ada di
`lib/presentation/theme/app_colors.dart` dan dipakai lewat `ColorScheme` shadcn
di `lib/presentation/theme/app_theme.dart`. Jangan menulis hex langsung di
widget.

## Skala GEA (Global Evaluation of Acne)

| Grade | Label | Deskripsi |
|---|---|---|
| 0 | Bersih | Tidak ada lesi |
| 1 | Hampir bersih | Beberapa komedo / papula kecil |
| 2 | Ringan | < setengah wajah, komedo + sedikit pustula |
| 3 | Sedang | > setengah wajah, banyak lesi, kadang 1 nodul |
| 4 | Berat | Inflamasi luas + nodul & kista |
| 5 | Sangat berat | Nodul & kista mendominasi area luas |

Model ML mengeluarkan **5 kelas IGA (`IGA0`–`IGA4`)** yang dipetakan **1:1** ke
grade **GEA 0–4** (label keduanya memang identik). Grade **5 tidak punya kelas
model**, jadi tidak akan pernah muncul dari hasil inferensi. Detail + contoh
kode: [`../docs/referensi-data.md`](../docs/referensi-data.md#pemetaan-label-model-ml--gea-iga0iga4).

## Ruang Lingkup

**Sudah ada**

- Login email/kata sandi ke backend (`POST /auth/login`) dan Google Sign-In
  (`POST /auth/google`); JWT disimpan di `ApiClient` untuk request bertanda
  `auth: true`.
- Pengambilan 3 selfie (depan, kiri, kanan) lewat kamera dengan pemandu kualitas
  berbasis ML Kit (cahaya, wajah, sudut), plus alternatif unggah dari galeri.
- Interview 5 pertanyaan (chat) yang bisa dilewati.
- Hasil skala GEA 0–5 (badge, bar skala, penjelasan) dari CNN di backend:
  3 foto dikirim ke `POST /ml/predict` (`lib/data/services/ml/`), grade diambil
  dari `aggregate` (mean softmax 3 foto). Hasil ditandai `ResultSource.ml`.
- Fallback otomatis: kalau ML gagal (offline / `503` / belum ada foto), grade
  dihitung rule-based dari interview (`gea_diagnosis_service.dart`) dan layar
  hasil menampilkan catatan bahwa foto tidak dianalisis.

**Belum ada**

- Layar registrasi (service `AuthRegister` dan endpoint backend sudah siap,
  tetapi tombol "Daftar Sekarang" masih menampilkan toast).
- Penyimpanan permanen: sesi scan hanya di memori dan token tidak di-persist,
  jadi menutup aplikasi berarti harus login ulang.
- Riwayat diagnosa, lupa kata sandi, dan verifikasi email.
- Inferensi on-device (model hanya berjalan di backend, bukan di HP).

## Referensi Lain

| Dokumen | Isi |
|---|---|
| [`../docs/README.md`](../docs/README.md) | Indeks dokumentasi |
| [`../docs/panduan-instalasi.md`](../docs/panduan-instalasi.md) | Prasyarat, build, troubleshooting |
| [`../docs/panduan-pengembangan.md`](../docs/panduan-pengembangan.md) | Konvensi kode & cara menambah fitur |
| [`../docs/alur-pengguna.md`](../docs/alur-pengguna.md) | Alur navigasi antar layar |
| [`../docs/fetching_api.md`](../docs/fetching_api.md) | Cara menambah pemanggilan API |
| [`../backend/openapi.json`](../backend/openapi.json) | Kontrak API (sumber kebenaran) |
