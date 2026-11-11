# Dokumentasi — PBL Skin Problem Detector

Dokumentasi teknis untuk aplikasi **SkinScan ID** (nama paket: `pbl_skin_problem_detector`).

Aplikasi Flutter untuk mendeteksi masalah kulit (jerawat) berdasarkan **skala GEA
(Global Evaluation of Acne)** 0–5. Autentikasi memakai backend FastAPI
(email/kata sandi + Google Sign-In, JWT Bearer), dan **diagnosa memakai CNN di
backend** (`POST /ml/predict`, 1–3 foto → grade GEA 0–4) dengan **fallback
rule-based** dari jawaban interview bila inferensi gagal. ML Kit tetap dipakai
untuk *deteksi wajah* saat pengambilan foto (kualitas & sudut), bukan untuk
klasifikasi lesi.

> ⚠️ Hasil bersifat informatif, **bukan** pengganti diagnosis dokter.

> 📁 Kode Flutter ada di folder [`mobile/`](../mobile/). Semua path di dokumentasi
> ini (`lib/...`, `android/...`, `pubspec.yaml`, dst.) relatif terhadap `mobile/`.

## Ringkasan Cepat

| Aspek | Keterangan |
|---|---|
| Framework | Flutter + Dart |
| UI | `shadcn_flutter` |
| State management | **Cubit** (`flutter_bloc`) |
| Navigasi | `go_router` |
| Kamera / galeri | `camera`, `image_picker` |
| Deteksi wajah | `google_mlkit_face_detection` |
| Inferensi | `POST /ml/predict` di backend (CNN TFLite), fallback rule-based |
| Font | Plus Jakarta Sans (`google_fonts`) |
| Entry point | `lib/main.dart` |

## Daftar Isi

| Dokumen | Isi |
|---|---|
| [arsitektur.md](arsitektur.md) | Arsitektur berlapis, state management, routing, alur data |
| [alur-pengguna.md](alur-pengguna.md) | Alur pengguna & navigasi antar layar (dengan diagram) |
| [struktur-folder.md](struktur-folder.md) | Struktur folder & tanggung jawab tiap file |
| [referensi-data.md](referensi-data.md) | Model data, skala GEA, pemetaan label model (IGA0–IGA4 → GEA), dan aturan diagnosis |
| [panduan-instalasi.md](panduan-instalasi.md) | Prasyarat, menjalankan, build, dan troubleshooting |
| [panduan-pengembangan.md](panduan-pengembangan.md) | Konvensi kode & cara menambah fitur |
| [api.md](api.md) | Konteks API backend (mobile/env/keamanan); kontrak resmi di [`backend/openapi.json`](../backend/openapi.json) |
| [fetching_api.md](fetching_api.md) | **AI agent / team reference (EN):** how to fetch the API from mobile (read OpenAPI → `services/`, `auth/` examples) |

## Ruang Lingkup Prototipe

**Sudah ada:**

- Login email/kata sandi ke backend (`POST /auth/login`) dan Google Sign-In
  (`POST /auth/google`); token JWT disimpan di `ApiClient` untuk request
  terproteksi. Endpoint registrasi sudah dipakai service, tetapi **layar
  registrasi belum ada** (tombol "Daftar Sekarang" masih toast).
- Pengambilan 3 selfie (depan, kiri, kanan) via kamera langsung dengan
  pemandu kualitas (cahaya, wajah, sudut) berbasis ML Kit.
- Alternatif unggah 3 foto dari galeri.
- Interview singkat 5 pertanyaan (chat) — bisa dilewati.
- Hasil skala GEA 0–5 dengan badge, bar skala, dan penjelasan.
- Analisis foto dengan CNN di backend: 3 foto dikirim ke `POST /ml/predict`
  (multipart, Bearer JWT), grade = mean softmax → GEA 0–4. Kalau gagal,
  otomatis fallback rule-based dan hasilnya ditandai `ResultSource.ruleBased`.

**Belum ada (rencana):**

- Layar registrasi di aplikasi.
- Penyimpanan riwayat permanen (sesi hanya di memori; token tidak di-persist).
- Endpoint scan/riwayat/artikel di backend.

## Cara Menjalankan Singkat

```bash
cd mobile
flutter pub get
flutter run
```

Detail lengkap ada di [panduan-instalasi.md](panduan-instalasi.md).
