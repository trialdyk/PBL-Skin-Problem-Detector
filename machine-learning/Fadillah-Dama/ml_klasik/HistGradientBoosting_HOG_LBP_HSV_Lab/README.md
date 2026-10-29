# DermaScan - HistGradientBoosting

## Deskripsi
Model Machine Learning klasik untuk mengklasifikasikan tingkat keparahan jerawat dari foto wajah menjadi Mild, Moderate, Severe, dan Very Severe.

## Dataset
ACNE04 dari Hugging Face (Layered-Labs/ACNE04). Sebanyak 1.411 gambar digunakan setelah audit dan pembersihan.

## Metode
- Klasifikasi: HistGradientBoostingClassifier
- Ekstraksi fitur: HOG, LBP, HSV, Lab, Black-hat Morphology, dan fitur kulit
- Jumlah fitur: 6.259 per gambar
- Ukuran gambar: 512 x 512 piksel

## Hasil Evaluasi
| Metrik | Hasil |
|---|---|
| Accuracy | 65,49% |
| Macro Precision | 63,71% |
| Macro Recall | 61,30% |
| Macro F1-score | 61,50% |
| Jumlah data testing | 284 |

## Struktur Folder
- Notebook: kode pengembangan dan training
- model/: file model terlatih, ekstraksi fitur, konfigurasi, dan metadata
- evaluasi/: laporan pengujian dan confusion matrix

## Catatan
Model masih memiliki keterbatasan dalam klasifikasi kelas Severe. Model ini merupakan prototipe pembelajaran mesin, bukan alat diagnosis medis.