# **Syarat dan Ketentuan DermaScan**

Selamat datang di DermaScan, aplikasi deteksi kondisi kulit wajah berbasis Computer Vision. Dengan mengakses dan menggunakan aplikasi DermaScan, Anda (Pengguna) menyetujui Syarat dan Ketentuan berikut.

# **1\. Layanan Aplikasi**

DermaScan merupakan aplikasi mobile berbasis Android yang dikembangkan oleh Kelompok 5 (TI-3C) Politeknik Negeri Malang. Aplikasi ini berfungsi memberikan informasi awal atau indikasi kondisi kulit wajah (seperti jerawat, komedo, dan noda bekas jerawat) melalui pemrosesan citra wajah dari 3 sudut (depan, kiri, kanan) menggunakan model Machine Learning.

# **2\. Batasan Tanggung Jawab**

* **Bukan Diagnosis Medis**: Analisis skala *Investigator's Global Assessment* (IGA) yang diberikan oleh aplikasi merupakan informasi awal dan **bukan** merupakan diagnosis medis, rekomendasi dokter, atau resep pengobatan.  
* **Keterbatasan Akurasi**: Hasil pemindaian sangat bergantung pada kualitas foto, pencahayaan, dan algoritma *Computer Vision* yang masih memiliki keterbatasan. Kami tidak menjamin tingkat akurasi 100%.

# **3\. Kebijakan Privasi dan Pengelolaan Data**

Sesuai dengan ketentuan operasional aplikasi, berikut adalah cara kami mengelola data Anda:

* **Foto Wajah**: Foto yang Anda unggah akan diproses di *back-end* (FastAPI) dan disimpan secara aman di *Cloudflare R2 Storage*. Data ini tidak digunakan sebagai *dataset* pelatihan model lanjutan secara otomatis.  
* **Data Sesi**: Informasi hasil analisis, wawancara profil kulit singkat (gender, umur, penggunaan sunscreen), dan riwayat disimpan di database server. Pengguna memiliki hak penuh untuk menghapus sesi pada aplikasi yang secara otomatis menghapus foto dan metadatanya.

# **4\. Kepatuhan Penggunaan**

Pengguna dilarang menyalahgunakan sistem dengan mengunggah gambar yang tidak pantas atau merekayasa balik (*reverse engineering*) infrastruktur *machine learning* API kami.

# **5\. Perubahan Syarat dan Ketentuan**

Syarat dan Ketentuan ini dapat diperbarui sewaktu-waktu sejalan dengan tahap pengembangan.