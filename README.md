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

Model yang **dipakai backend** sekarang adalah CNN Fadillah Dama:

- `machine-learning/Fadillah-Dama/deep_learning/dermascan_custom_cnn.tflite`
  (sumber training) → disalin ke `backend/app/ml/artifacts/` dan di-commit.
- Input `[1, 160, 160, 3]` float32 piksel 0–255, output softmax 5 kelas
  `IGA0`–`IGA4` → grade GEA 0–4.
- Dipanggil aplikasi lewat `POST /ml/predict` (lihat
  [docs/api.md](docs/api.md) dan [backend/README.md](backend/README.md)).

Model lama `custom_cnn_1.tflite` di `machine-learning/models/` tetap disimpan
sebagai pembanding, tetapi tidak dipakai alur produk:

https://github.com/trialdyk/PBL-Skin-Problem-Detector/blob/main/machine-learning/models/custom_cnn_1.tflite

## Menjalankan aplikasi mobile

```bash
cd mobile
flutter pub get
flutter run
```
