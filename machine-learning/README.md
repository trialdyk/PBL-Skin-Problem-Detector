# Machine Learning

Dataset, notebook eksperimen, training, dan export model klasifikasi tingkat keparahan jerawat (skala GEA 0–5).

## Model

File bobot bersama ada di [`models/`](models/). Hasil laporan per anggota ada di folder masing-masing (contoh: [`laksamanaap/`](laksamanaap/)).

https://github.com/trialdyk/PBL-Skin-Problem-Detector/blob/main/machine-learning/models/custom_cnn_1.tflite

| File | Asal | Keterangan |
|---|---|---|
| `models/custom_cnn_1.tflite` | notebook [`custom_cnn_1.ipynb`](notebooks/custom_cnn_1.ipynb) | Custom CNN TensorFlow Lite, 4 kelas Hayashi (`mild`, `moderate`, `severe`, `very_severe`) |
| `laksamanaap/laksa_custom_cnn.tflite` | notebook [`laksa_custom_cnn.ipynb`](notebooks/laksa_custom_cnn.ipynb) | Custom CNN dari Roboflow Acne Severity v3 (kelas IGA, dipetakan ke GEA). |

## Dataset

Salinan lokal ada di `dataset/` (folder ini di-gitignore, tidak ikut di-commit). Unduh dari sumber di bawah, lalu letakkan di `dataset/`.

| Dataset | Sumber | Keterangan |
|---|---|---|
| **ACNE04** | [Hugging Face — Layered-Labs/ACNE04](https://huggingface.co/datasets/Layered-Labs/ACNE04) | Dataset utama. 1.457 foto wajah, label keparahan 4 tingkat (Hayashi 0–3), ~18.983 bounding box lesi. Salinan lokal: `dataset/ACNE04/`. Lisensi: academic/research use only. Paper asli: [Wu et al., ICCV 2019](https://openaccess.thecvf.com/content_ICCV_2019/html/Wu_Joint_Acne_Image_Grading_and_Counting_via_Label_Distribution_Learning_ICCV_2019_paper.html). |
| **ACNE04-v2** | [AIpourlapeau/acne04v2](https://github.com/AIpourlapeau/acne04v2) | Daftar nama gambar (anotasi JSON) untuk menyaring subset training. Dipakai opsional di [`custom_cnn_1.ipynb`](notebooks/custom_cnn_1.ipynb); label severity tetap dari ACNE04. |
| **Acne Severity Classification** | [Roboflow Universe — Taschenbier (v3)](https://universe.roboflow.com/taschenbier/acne-severity-classification/dataset/3) | **Versi 3**, ~6.000 gambar (6.451 total; train 5.991 / valid 325 / test 135). 6 kelas **IGA** (`IGA0`, `IGA1`, `IGA2`, `IGA3`, `IGA3_Level3`, `IGA4`). Skala IGA dekat dengan GEA 0–5 yang dipakai aplikasi. Training: [`laksa_custom_cnn.ipynb`](notebooks/laksa_custom_cnn.ipynb) (unduh lewat `ROBOFLOW_API_KEY`). |
