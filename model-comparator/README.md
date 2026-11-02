# Model Comparator

Web kecil untuk mencoba dan membandingkan model klasifikasi tingkat keparahan jerawat (skala **IGA0–IGA4**). Upload satu gambar, lalu lihat prediksi tiap model dan tabel perbandingannya.

## Model

Daftar model ada di [`models.json`](models.json), file modelnya di [`model/`](model/).

| ID | Nama | Arsitektur | Input |
|---|---|---|---|
| `aldy-01` | Aldy 01 | EfficientNetB2 (`.keras`) | 260×260 |
| `aldy-02` | Aldy 02 | EfficientNetB3 ensemble 3 model (`.tflite` FP16) | 300×300 |
| `dama` | Dama | Custom CNN (`.keras`) | 160×160 |
| `laksa` | Laksa | Custom CNN (`.tflite`) | 224×224 |
| `marsy` | Marsy | MobileNetV2 pretrained (`.tflite`) | 224×224 |

Semua model menerima piksel RGB **0–255** (float32); normalisasi sudah ada di dalam model, jadi tidak ada preprocessing tambahan di luar resize.

## Menjalankan

Dites di WSL (Ubuntu) dengan Python 3.12. TensorFlow belum mendukung Python 3.14.

```bash
cd model-comparator
python3.12 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python app.py
```

Buka http://localhost:5000. Port bisa diganti dengan `PORT=8000 python app.py`.

## Menambah model

1. Taruh file `.keras` atau `.tflite` di `model/`.
2. Tambahkan satu entri di `models.json`:

```json
{
  "id": "nama-model",
  "name": "Nama Tampilan",
  "description": "Arsitektur · keterangan singkat",
  "file": "model/nama_file.tflite",
  "labels": ["IGA0 · Bersih", "IGA1 · Hampir bersih", "IGA2 · Ringan", "IGA3 · Sedang", "IGA4 · Berat"],
  "content_crop": false
}
```

3. Restart server.

Urutan `labels` harus sama dengan urutan index output model. `content_crop: true` membuang tepi hitam gambar sebelum resize (dipakai Aldy 02 sesuai `meta.json`-nya; cara persisnya adalah perkiraan).

## API

| Endpoint | Fungsi |
|---|---|
| `GET /api/models` | Daftar model, label, dan ukuran input |
| `POST /api/predict` | Field `image` + `model` (opsional): prediksi satu model |
| `POST /api/compare` | Field `image`: prediksi semua model sekaligus |

```bash
curl -F "image=@foto.jpg" http://localhost:5000/api/compare
```

Batas ukuran upload 10 MB.

> Hasil prediksi hanya untuk keperluan belajar/evaluasi model, bukan diagnosis medis.
