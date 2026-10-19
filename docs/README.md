# Dokumentasi — PBL Skin Problem Detector

Dokumentasi teknis untuk aplikasi **SkinScan ID** (nama paket: `pbl_skin_problem_detector`).

Aplikasi Flutter untuk mendeteksi masalah kulit (jerawat) berdasarkan **skala GEA
(Global Evaluation of Acne)** 0–5. Prototipe ini memakai **mock login** dan
**diagnosa rule-based**; foto wajah belum dianalisis dengan model ML — ML Kit
baru dipakai untuk *deteksi wajah* saat pengambilan foto (kualitas & sudut),
bukan untuk klasifikasi lesi.

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
| Font | Plus Jakarta Sans (`google_fonts`) |
| Entry point | `lib/main.dart` |

## Daftar Isi

| Dokumen | Isi |
|---|---|
| [arsitektur.md](arsitektur.md) | Arsitektur berlapis, state management, routing, alur data |
| [alur-pengguna.md](alur-pengguna.md) | Alur pengguna & navigasi antar layar (dengan diagram) |
| [struktur-folder.md](struktur-folder.md) | Struktur folder & tanggung jawab tiap file |
| [referensi-data.md](referensi-data.md) | Model data, skala GEA, dan aturan diagnosis |
| [panduan-instalasi.md](panduan-instalasi.md) | Prasyarat, menjalankan, build, dan troubleshooting |
| [panduan-pengembangan.md](panduan-pengembangan.md) | Konvensi kode & cara menambah fitur |

## Ruang Lingkup Prototipe

**Sudah ada:**

- Login mock (email/password + tombol Google) dengan validasi S&K.
- Pengambilan 3 selfie (depan, kiri, kanan) via kamera langsung dengan
  pemandu kualitas (cahaya, wajah, sudut) berbasis ML Kit.
- Alternatif unggah 3 foto dari galeri.
- Interview singkat 5 pertanyaan (chat) — bisa dilewati.
- Hasil skala GEA 0–5 dengan badge, bar skala, dan penjelasan.

**Belum ada (rencana):**

- Analisis citra lesi dengan model ML (saat ini rule-based dari interview).
- Backend / penyimpanan riwayat permanen (sesi hanya di memori).
- Integrasi OAuth Google yang sebenarnya (masih mock).

## Cara Menjalankan Singkat

```bash
cd mobile
flutter pub get
flutter run
```

Detail lengkap ada di [panduan-instalasi.md](panduan-instalasi.md).
