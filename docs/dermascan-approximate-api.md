# DAFTAR API DERMASCAN

## 1. Registrasi, login, dan sesi autentikasi

| Method | Endpoint | Fungsi | Penjelasan singkat |
| --- | --- | --- | --- |
| `POST` | `/auth/register` | Registrasi akun | Membuat akun baru dan mengembalikan token akses. |
| `POST` | `/auth/login` | Login | Memeriksa email dan kata sandi untuk memberikan token akses. |
| `POST` | `/auth/refresh` | Perbarui token | Menggunakan refresh token untuk memperoleh token akses baru. |
| `POST` | `/auth/logout` | Logout | Mencabut sesi atau refresh token perangkat yang digunakan. |

## 2. Verifikasi email dan pemulihan kata sandi

| Method | Endpoint | Fungsi | Penjelasan singkat |
| --- | --- | --- | --- |
| `POST` | `/auth/verify-email` | Verifikasi email | Mengonfirmasi kepemilikan email menggunakan kode atau token. |
| `POST` | `/auth/resend-verification` | Kirim ulang verifikasi | Mengirim kembali kode atau tautan verifikasi email. |
| `POST` | `/auth/forgot-password` | Permintaan reset | Mengirim kode atau tautan untuk mengatur ulang kata sandi. |
| `POST` | `/auth/reset-password` | Reset kata sandi | Menetapkan kata sandi baru menggunakan token reset. |

## 3. Profil dan pengelolaan akun

| Method | Endpoint | Fungsi | Penjelasan singkat |
| --- | --- | --- | --- |
| `GET` | `/user/me` | Lihat profil | Mengambil informasi akun pengguna yang sedang login. |
| `PATCH` | `/user/me` | Ubah profil | Memperbarui nama dan informasi profil yang diizinkan. |
| `PUT` | `/user/me/password` | Ubah kata sandi | Mengganti kata sandi setelah memverifikasi kata sandi lama. |
| `DELETE` | `/user/me` | Hapus akun | Menghapus akun beserta sesi, hasil, jawaban, dan foto terkait. |

## 4. Sesi scan wajah

| Method | Endpoint | Fungsi | Penjelasan singkat |
| --- | --- | --- | --- |
| `POST` | `/scan` | Buat sesi scan | Membuat sesi baru dan mengembalikan ID untuk alur scan. |
| `GET` | `/scan/{scan_id}` | Detail sesi | Mengambil status, metadata, jawaban interview, dan hasil sesi. |

## 5. Unggah dan akses foto

| Method | Endpoint | Fungsi | Penjelasan singkat |
| --- | --- | --- | --- |
| `PUT` | `/scan/{scan_id}/photos/{angle}` | Unggah atau ganti foto | Menyimpan foto untuk sudut front, left, atau right pada sesi. |
| `GET` | `/scan/{scan_id}/photos/{angle}` | Akses foto | Mengambil foto milik pengguna atau URL akses sementara. |

## 6. Interview atau kuesioner kulit

| Method | Endpoint | Fungsi | Penjelasan singkat |
| --- | --- | --- | --- |
| `PUT` | `/scan/{scan_id}/interview` | Simpan jawaban | Menyimpan jawaban profil kulit atau penanda interview dilewati. |

## 7. Analisis model dan hasil

| Method | Endpoint | Fungsi | Penjelasan singkat |
| --- | --- | --- | --- |
| `POST` | `/scan/{scan_id}/analyze` | Mulai analisis | Memproses tiga foto sesi dengan model dan menyimpan hasilnya. |
| `GET` | `/scan/{scan_id}` | Lihat hasil analisis | Mengambil status pemrosesan serta grade, label, dan deskripsi hasil. |

## 8. Riwayat dan penghapusan scan

| Method | Endpoint | Fungsi | Penjelasan singkat |
| --- | --- | --- | --- |
| `GET` | `/scan` | Daftar riwayat | Menampilkan riwayat scan pengguna dengan pagination. |
| `GET` | `/scan/{scan_id}` | Detail riwayat | Membuka kembali informasi dan hasil scan sebelumnya. |
| `DELETE` | `/scan/{scan_id}` | Hapus riwayat | Menghapus sesi, hasil analisis, dan foto terkait dari penyimpanan. |

## 9. Artikel dan edukasi

| Method | Endpoint | Fungsi | Penjelasan singkat |
| --- | --- | --- | --- |
| `GET` | `/article` | Daftar artikel | Mengambil artikel edukasi; dapat mendukung kategori dan pencarian. |
| `GET` | `/article/{article_id}` | Detail artikel | Mengambil isi lengkap artikel dan referensi artikel terkait. |

## 10. Pemeriksaan layanan dan status pekerjaan

| Method | Endpoint | Fungsi | Penjelasan singkat |
| --- | --- | --- | --- |
| `GET` | `/health` | Cek layanan | Memastikan backend hidup tanpa memeriksa database. |

## 11. Login Google

| Method | Endpoint | Fungsi | Penjelasan singkat |
| --- | --- | --- | --- |
| `POST` | `/auth/google` | Login Google | Memverifikasi identitas Google dan memberikan sesi aplikasi. |
