# **Kebijakan Privasi DermaScan**

Di DermaScan, kami sangat menghargai privasi dan keamanan data Anda. Kebijakan Privasi ini menjelaskan bagaimana kami mengumpulkan, menggunakan, menyimpan, dan melindungi informasi pribadi Anda saat menggunakan aplikasi DermaScan.

# **1\. Data yang Kami Kumpulkan**

Untuk menyediakan layanan analisis kondisi kulit wajah, kami mengumpulkan beberapa jenis data berikut:

* **Informasi Akun**: Email dan kata sandi yang Anda gunakan saat proses Registrasi dan Login.  
* **Foto Wajah**: Tiga (3) foto *selfie* wajah Anda dari sudut depan, kiri, dan kanan, baik yang diambil melalui kamera maupun yang diunggah dari galeri.  
* **Profil Kulit**: Data dari wawancara singkat (*interview*) opsional, yang mencakup gender, umur, penggunaan *sunscreen*, tipe kulit, dan pola makan.

# **2\. Penggunaan Data**

Data yang Anda berikan akan kami gunakan secara spesifik untuk tujuan berikut:

* **Analisis Kondisi Kulit**: Foto wajah Anda diproses di *back-end* menggunakan model *Machine Learning* untuk mendeteksi kondisi (seperti jerawat, komedo, dan noda bekas jerawat) dan memberikan ringkasan berbasis skala IGA (*Investigator's Global Assessment*).  
* **Personalisasi**: Menyediakan artikel edukasi dan panduan perawatan yang sesuai dengan kondisi wajah Anda.  
* **Manajemen Sesi**: Mengelola riwayat pemindaian Anda agar dapat dilihat kembali di masa mendatang.

# **3\. Penyimpanan dan Keamanan Data**

Infrastruktur kami dirancang dengan standar keamanan untuk melindungi data Anda:

* **Penyimpanan**: Foto wajah Anda disimpan di **Cloudflare R2 Storage**, sedangkan data profil dan metadata sesi disimpan di *database* server *back-end* (FastAPI).  
* **Keamanan Kredensial**: Kata sandi Anda disimpan dalam bentuk *hash*, dan seluruh komunikasi antara aplikasi seluler dan server dienkripsi menggunakan protokol **HTTPS**.  
* **Akses Terbatas**: Foto dan riwayat diagnosis hanya dapat diakses oleh Anda sebagai pemilik akun menggunakan token akses yang valid. Berkas di server tidak dapat diakses langsung oleh publik.

# **4\. Perlindungan dan Berbagi Data**

* **Tidak Ada Pelatihan Otomatis**: Foto wajah Anda **tidak** akan otomatis dimasukkan ke dalam *dataset* untuk melatih model kami. Penggunaan foto untuk kebutuhan penelitian atau pelatihan model lebih lanjut memerlukan persetujuan terpisah.  
* Kami tidak memperjualbelikan, menyewakan, atau membagikan data identitas maupun foto wajah Anda kepada pihak ketiga untuk tujuan komersial.

# **5\. Hak dan Kontrol Pengguna**

Anda memiliki kendali penuh atas data Anda di dalam aplikasi DermaScan:

* **Penghapusan Riwayat**: Melalui menu Riwayat, Anda dapat menghapus sesi diagnosis kapan saja. Tindakan ini akan secara permanen menghapus metadata sesi beserta ketiga foto terkait dari *database* dan *Cloudflare R2*.  
* **Pencabutan Akses Lokal**: Anda dapat menekan tombol *Logout* pada menu Profil untuk menghapus token akses otentikasi dari perangkat Anda.

# **6\. Pembaruan Kebijakan**

Kebijakan Privasi ini dapat diperbarui sewaktu-waktu seiring dengan pengembangan aplikasi DermaScan.