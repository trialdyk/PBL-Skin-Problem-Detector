# Machine Learning

Dataset, notebook eksperimen, training, dan export model klasifikasi tingkat keparahan jerawat (skala GEA 0–5).

## Model

File bobot ada di [`models/`](models/) dan ikut di-commit (untuk di-embed ke back-end/mobile):

https://github.com/trialdyk/PBL-Skin-Problem-Detector/blob/main/machine-learning/models/custom_cnn_1.tflite

| File | Asal | Keterangan |
|---|---|---|
| `custom_cnn_1.tflite` | notebook [`custom_cnn_1.ipynb`](notebooks/custom_cnn_1.ipynb) | Custom CNN TensorFlow Lite, 4 kelas Hayashi (`mild`, `moderate`, `severe`, `very_severe`) |

## Dataset

Salinan lokal ada di `dataset/` (folder ini di-gitignore, tidak ikut di-commit). Unduh dari sumber di bawah, lalu letakkan di `dataset/`.

| Dataset | Sumber | Keterangan |
|---|---|---|
| **ACNE04** | [Hugging Face — Layered-Labs/ACNE04](https://huggingface.co/datasets/Layered-Labs/ACNE04) | Dataset utama. 1.457 foto wajah, label keparahan 4 tingkat (Hayashi 0–3), ~18.983 bounding box lesi. Salinan lokal: `dataset/ACNE04/`. Lisensi: academic/research use only. Paper asli: [Wu et al., ICCV 2019](https://openaccess.thecvf.com/content_ICCV_2019/html/Wu_Joint_Acne_Image_Grading_and_Counting_via_Label_Distribution_Learning_ICCV_2019_paper.html). |
| **ACNE04-v2** | [AIpourlapeau/acne04v2](https://github.com/AIpourlapeau/acne04v2) | Daftar nama gambar (anotasi JSON) untuk menyaring subset training. Dipakai opsional di [`custom_cnn_1.ipynb`](notebooks/custom_cnn_1.ipynb); label severity tetap dari ACNE04. |
