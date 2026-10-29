import 'package:go_router/go_router.dart';
import 'package:pbl_skin_problem_detector/presentation/theme/app_colors.dart';
import 'package:pbl_skin_problem_detector/presentation/theme/app_font.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  _BackButton(onPressed: () => context.pop()),
                  const Gap(16),
                  Expanded(
                    child: Text(
                      'Kebijakan Privasi',
                      style: appFont(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text.rich(
                    TextSpan(
                      style: appFont(
                        fontSize: 13,
                        height: 1.65,
                        color: AppColors.inkMuted,
                      ),
                      children: [
                        TextSpan(
                          text: 'Kebijakan Privasi DermaScan\n',
                          style: appFont(
                            fontSize: 21,
                            height: 1.3,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        const TextSpan(
                          text: '\nDi DermaScan, kami sangat menghargai privasi dan keamanan data Anda. Kebijakan Privasi ini menjelaskan bagaimana kami mengumpulkan, menggunakan, menyimpan, dan melindungi informasi pribadi Anda saat menggunakan aplikasi DermaScan.\n\n',
                        ),
                        _heading('1. Data yang Kami Kumpulkan'),
                        const TextSpan(
                          text: 'Untuk menyediakan layanan analisis kondisi kulit wajah, kami mengumpulkan beberapa jenis data berikut:\n',
                        ),
                        _boldLabel('Informasi Akun: '),
                        const TextSpan(
                          text: 'Email dan kata sandi yang Anda gunakan saat proses Registrasi dan Login.\n',
                        ),
                        _boldLabel('Foto Wajah: '),
                        const TextSpan(
                          text: 'Tiga (3) foto selfie wajah Anda dari sudut depan, kiri, dan kanan, baik yang diambil melalui kamera maupun yang diunggah dari galeri.\n',
                        ),
                        _boldLabel('Profil Kulit: '),
                        const TextSpan(
                          text: 'Data dari wawancara singkat (interview) opsional, yang mencakup gender, umur, penggunaan sunscreen, tipe kulit, dan pola makan.\n\n',
                        ),
                        _heading('2. Penggunaan Data'),
                        const TextSpan(
                          text: 'Data yang Anda berikan akan kami gunakan secara spesifik untuk tujuan berikut:\n',
                        ),
                        _boldLabel('Analisis Kondisi Kulit: '),
                        const TextSpan(
                          text: 'Foto wajah Anda diproses di back-end menggunakan model Machine Learning untuk mendeteksi kondisi (seperti jerawat, komedo, dan noda bekas jerawat) dan memberikan ringkasan berbasis skala IGA (Investigator\'s Global Assessment).\n',
                        ),
                        _boldLabel('Personalisasi: '),
                        const TextSpan(
                          text: 'Menyediakan artikel edukasi dan panduan perawatan yang sesuai dengan kondisi wajah Anda.\n',
                        ),
                        _boldLabel('Manajemen Sesi: '),
                        const TextSpan(
                          text: 'Mengelola riwayat pemindaian Anda agar dapat dilihat kembali di masa mendatang.\n\n',
                        ),
                        _heading('3. Penyimpanan dan Keamanan Data'),
                        _boldLabel('Penyimpanan: '),
                        const TextSpan(
                          text: 'Foto wajah Anda disimpan di Cloudflare R2 Storage, sedangkan data profil dan metadata sesi disimpan di database server back-end (FastAPI).\n',
                        ),
                        _boldLabel('Keamanan Kredensial: '),
                        const TextSpan(
                          text: 'Kata sandi Anda disimpan dalam bentuk hash, dan seluruh komunikasi antara aplikasi seluler dan server dienkripsi menggunakan protokol HTTPS.\n',
                        ),
                        _boldLabel('Akses Terbatas: '),
                        const TextSpan(
                          text: 'Foto dan riwayat diagnosis hanya dapat diakses oleh Anda sebagai pemilik akun menggunakan token akses yang valid. Berkas di server tidak dapat diakses langsung oleh publik.\n\n',
                        ),
                        _heading('4. Perlindungan dan Berbagi Data'),
                        _boldLabel('Tidak Ada Pelatihan Otomatis: '),
                        const TextSpan(
                          text: 'Foto wajah Anda tidak akan otomatis dimasukkan ke dalam dataset untuk melatih model kami. Penggunaan foto untuk kebutuhan penelitian atau pelatihan model lebih lanjut memerlukan persetujuan terpisah.\nKami tidak memperjualbelikan, menyewakan, atau membagikan data identitas maupun foto wajah Anda kepada pihak ketiga untuk tujuan komersial.\n\n',
                        ),
                        _heading('5. Hak dan Kontrol Pengguna'),
                        _boldLabel('Penghapusan Riwayat: '),
                        const TextSpan(
                          text: 'Melalui menu Riwayat, Anda dapat menghapus sesi diagnosis kapan saja. Tindakan ini akan secara permanen menghapus metadata sesi beserta ketiga foto terkait dari database dan Cloudflare R2.\n',
                        ),
                        _boldLabel('Pencabutan Akses Lokal: '),
                        const TextSpan(
                          text: 'Anda dapat menekan tombol Logout pada menu Profil untuk menghapus token akses otentikasi dari perangkat Anda.\n\n',
                        ),
                        _heading('6. Pembaruan Kebijakan'),
                        const TextSpan(
                          text: 'Kebijakan Privasi ini dapat diperbarui sewaktu-waktu seiring dengan pengembangan aplikasi DermaScan.',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static TextSpan _heading(String text) => TextSpan(
    text: '$text\n',
    style: appFont(
      fontSize: 15,
      height: 1.45,
      fontWeight: FontWeight.w700,
      color: AppColors.brand,
    ),
  );

  static TextSpan _boldLabel(String text) => TextSpan(
    text: text,
    style: appFont(fontWeight: FontWeight.w700, color: AppColors.ink),
  );
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
        ),
        child: const Icon(
          LucideIcons.arrowLeft,
          size: 18,
          color: AppColors.ink,
        ),
      ),
    );
  }
}
