# Haar + LBF + LBP-HSV + SVM

Model klasifikasi tingkat keparahan jerawat ACNE04 menggunakan pipeline
StandardScaler + SVM RBF, varian **multi_fixed** (C=10, gamma=scale).

## Metode

Foto -> crop Haar -> 68 landmark LBF -> mask -> LBP radius 1,2,3 + HSV
-> 102 fitur -> scaler + SVM.

Mask mengecualikan mata, alis, **hidung (indeks 27-35)**, dan bibir dengan
convex hull. Dahi diperkirakan dari alis. Jika landmark gagal atau mask terlalu
kecil, digunakan fallback seluruh crop sesuai training. Jika interior LBP
terlalu kecil, radius terkait menggunakan interior seluruh crop.

Label: 0=mild, 1=moderate, 2=severe, 3=very_severe.

## Isi paket

- `results_lbf_multiradius/models/multi_fixed.joblib`: pipeline scaler + SVM.
- `results_lbf_multiradius/models/multi_fixed_config.json`: konfigurasi fitur.
- `results_lbf_multiradius/run_metadata.json`: metadata dan hash Haar/LBF.
- `results_lbf_multiradius/`: tabel evaluasi dan confusion matrix validation.
- `ACNE04_Prediksi_Gambar_Baru_LBF_MultiFixed.ipynb`: prediksi foto baru;
  path sudah disesuaikan untuk folder paket ini.
- `ACNE04_Haar_LBF_Multiradius_Tuning_SVM.ipynb`: arsip training dan evaluasi.
- `download_lbf_model.py`: pengunduh model landmark pretrained.
- `requirements.txt`: dependensi dengan versi sesuai environment training.

## Menjalankan prediksi

Gunakan Python 3.10-3.12. Dari folder ini:

```powershell
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
.\.venv\Scripts\python.exe download_lbf_model.py
.\.venv\Scripts\python.exe -m ipykernel install --user --name acne04-lbf --display-name "Python (ACNE04 LBF)"
```

Buka notebook prediksi dengan kernel tersebut. Simpan foto pada folder ini
sebagai `foto_uji.jpg`, atau ubah `IMAGE_PATH` pada langkah 2. Jalankan Run All
dengan working directory folder ini. Tidak perlu training ulang untuk prediksi.

`lbf_models/lbfmodel.yaml` tidak disertakan (sekitar 56 MB); script download
menyiapkannya. Notebook memverifikasi hash model landmark sesuai training.
File `.joblib` hanya berisi scaler dan SVM; preprocessing dan mask tanpa hidung
harus mengikuti notebook prediksi yang disertakan.

## Hasil validation

212 sampel, accuracy 58.49%, macro-F1 0.5514, balanced accuracy 53.95%.
Recall tiap kelas: mild 61.33%, moderate 62.64%, severe 44.44%,
very_severe 47.37%. Confusion matrix tersedia sebagai PNG dan CSV,
termasuk versi normalisasi per baris.

## Mengulang training

Notebook training mempertahankan path proyek sumber. Untuk menjalankannya,
gunakan layout proyek asli dengan `ACNE04-Preprocessed`,
`ACNE04-Dataset/Images`, `experiments/acne04_landmark`, dan
`experiments/acne04_classical/results/manifest_with_roi.csv`.
Dataset dan manifest training tidak disertakan dalam paket prediksi ini.

## Commit

Commit isi paket ini. Abaikan `.venv/`, `__pycache__/`, `.ipynb_checkpoints/`,
foto uji pribadi, dan file landmark yang dibuat script download.
