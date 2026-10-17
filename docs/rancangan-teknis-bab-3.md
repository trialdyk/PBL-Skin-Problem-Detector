# 3.3 Studi Kelayakan Teknis dan Data

Studi kelayakan awal dilakukan pada kegiatan Minggu 1–3 untuk memastikan sumber data, volume data, dan pendekatan model machine learning realistis dikerjakan dalam jangka waktu 16 minggu, sebelum pengembangan aplikasi berjalan jauh.

## Sumber dataset

Dataset utama yang digunakan adalah **ACNE04** versi siap pakai di Hugging Face:

**https://huggingface.co/datasets/Layered-Labs/ACNE04**

Dataset ini merupakan pengemasan ulang korpus ACNE04 asli (foto wajah + label keparahan + anotasi lesi) dalam format yang mudah diunduh dan diproses. Kontennya mencakup:

- sekitar **1.457 foto wajah** dengan jerawat;
- label keparahan **4 tingkat (Hayashi scale)**: `level` 0–3 / `severity` (misalnya mild, moderate, dst.);
- sekitar **18.983 bounding box lesi** per gambar (berguna untuk deteksi/lokalisasi lesi, bukan hanya klasifikasi);
- pembagian **5-fold cross-validation** yang sudah disediakan untuk evaluasi yang konsisten;
- lisensi **academic use only**, sehingga cocok untuk tugas besar / PBL kampus.

Dengan demikian, tim **tidak perlu mengumpulkan dataset dari nol** di awal semester. Pengumpulan data tambahan (jika diperlukan) hanya sebagai pelengkap, misalnya untuk uji coba real-device atau penyesuaian domain.

## Perkiraan jumlah data

| Aspek             | Perkiraan                                            |
| ----------------- | ---------------------------------------------------- |
| Jumlah gambar     | ± **1.457** foto                                     |
| Jenis tugas label | Klasifikasi severity (4 kelas) + deteksi lesi (bbox) |
| Ukuran kisaran    | 1K–10K (sesuai kartu dataset HF)                     |
| Split evaluasi    | fold CV bawaan dataset                               |

Jumlah ±1.457 gambar **masih memadai** untuk eksperimen klasifikasi berbasis _transfer learning_ (misalnya MobileNet / EfficientNet kecil yang sudah dilatih di ImageNet), terutama jika fokusnya adalah model yang ringan dan evaluasi dengan fold yang sudah tersedia. Jumlah ini **kurang ideal** jika ingin melatih model deteksi lesi yang sangat dalam dari scratch tanpa transfer learning; oleh karena itu strategi tim mengutamakan fine-tuning model yang sudah ada, bukan training dari nol.

## Keterkaitan dengan skala GEA pada aplikasi

Aplikasi menampilkan hasil dalam kerangka **GEA 0–5**, sedangkan ACNE04 memakai **skala Hayashi 4 tingkat**. Secara kelayakan data, ini tetap dapat dijalankan dengan catatan teknis:

1. model dilatih pada label ACNE04 (4 kelas);
2. hasil model dipetakan / dikalibrasikan ke tampilan GEA di sisi aplikasi atau back-end (dengan dokumentasi mapping yang jelas);
3. interview profil kulit pada aplikasi dipakai sebagai informasi pendukung, bukan pengganti label dataset.

Dengan pendekatan ini, dataset tetap relevan tanpa memaksa relabel manual seluruh 1.457 gambar di awal semester.

## Penilaian kelayakan model ML dalam 16 minggu

**Kesimpulan: realistis**, dengan batasan ruang lingkup yang tegas.

| Pertanyaan kelayakan                                   | Penilaian                                                                       |
| ------------------------------------------------------ | ------------------------------------------------------------------------------- |
| Apakah dataset tersedia sekarang?                      | Ya — ACNE04 di Hugging Face, lengkap & berlisensi akademik                      |
| Apakah jumlah data cukup untuk prototipe klasifikasi?  | Ya — cukup untuk fine-tuning model ringan + evaluasi fold                       |
| Apakah training model di HP realistis?                 | **Tidak** — training dilakukan di PC/server, bukan on-device                    |
| Apakah inferensi di perangkat mobile wajib?            | Tidak wajib pada tahap ini; arsitektur tim menempatkan diagnosa di **FastAPI**  |
| Apakah alur aplikasi (scan 3 sudut + hasil) realistis? | Ya — Flutter menangani kamera/ML Kit bimbingan wajah; server menangani analisis |

Alasan kelayakan teknis:

1. **Data sudah ada** sejak awal, sehingga risiko “baru sadar dataset kurang di minggu ke-10” dapat ditekan.
2. **Training di server / lingkungan pengembangan** (Python + FastAPI) jauh lebih realistis dalam 16 minggu daripada memaksakan training berat langsung di Android.
3. **Inferensi di back-end FastAPI** sesuai arsitektur yang sudah dirancang: Flutter mengirim foto, server mengembalikan skor/label GEA, foto disimpan di Cloudflare R2.
4. Di sisi mobile, beban utamanya adalah **pengambilan gambar + validasi pencahayaan/posisi wajah (ML Kit)**, yang sudah terbukti dapat dijalankan on-device tanpa model klasifikasi jerawat yang berat.

## Risiko dan mitigasi

| Risiko                                           | Mitigasi                                                                      |
| ------------------------------------------------ | ----------------------------------------------------------------------------- |
| Label ACNE04 ≠ GEA 0–5 secara langsung           | Buat skema mapping Hayashi → GEA dan dokumentasikan di laporan                |
| Domain foto dataset vs foto selfie user berbeda  | Uji dengan foto uji internal; tambah augmentasi / fine-tune ringan jika perlu |
| Deteksi lesi penuh terlalu berat untuk 16 minggu | Prioritas: klasifikasi severity dulu; deteksi lesi sebagai opsi lanjutan      |
| Lisensi akademik                                 | Digunakan hanya untuk keperluan PBL/tugas, sesuai ketentuan dataset           |
