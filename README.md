# PBL Skin Problem Detector

Monorepo aplikasi pendeteksi tingkat keparahan jerawat berdasarkan skala **GEA (Global Evaluation of Acne)**.

## Struktur

| Folder | Isi |
|---|---|
| [`mobile/`](mobile/) | Aplikasi Flutter (lihat [mobile/README.md](mobile/README.md)) |
| [`backend/`](backend/) | API server FastAPI (lihat [backend/README.md](backend/README.md)) |
| [`machine-learning/`](machine-learning/) | Dataset, training, dan model |
| [`docs/`](docs/) | Dokumentasi proyek (mulai dari [docs/README.md](docs/README.md)) |

## Model

`custom_cnn_1.tflite` ada di `machine-learning/models/` (ikut di-commit, untuk di-embed ke back-end/mobile):

https://github.com/trialdyk/PBL-Skin-Problem-Detector/blob/main/machine-learning/models/custom_cnn_1.tflite

## Menjalankan aplikasi mobile

```bash
cd mobile
flutter pub get
flutter run
```
