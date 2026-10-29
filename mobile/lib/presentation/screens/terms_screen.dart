import 'package:flutter/material.dart' show SelectableText;
import 'package:go_router/go_router.dart';
import 'package:pbl_skin_problem_detector/presentation/theme/app_colors.dart';
import 'package:pbl_skin_problem_detector/presentation/theme/app_font.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' hide SelectableText;

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

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
                      'Syarat & Ketentuan',
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
                  child: SelectableText.rich(
                    TextSpan(
                      style: appFont(
                        fontSize: 13,
                        height: 1.65,
                        color: AppColors.inkMuted,
                      ),
                      children: [
                        TextSpan(
                          text: 'Syarat dan Ketentuan DermaScan\n',
                          style: appFont(
                            fontSize: 21,
                            height: 1.3,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        const TextSpan(
                          text: '\nSelamat datang di DermaScan, aplikasi deteksi kondisi kulit wajah berbasis Computer Vision. Dengan mengakses dan menggunakan aplikasi DermaScan, Anda (Pengguna) menyetujui Syarat dan Ketentuan berikut.\n\n',
                        ),
                        _heading('1. Layanan Aplikasi'),
                        const TextSpan(
                          text: 'DermaScan merupakan aplikasi mobile berbasis Android yang dikembangkan oleh Kelompok 5 (TI-3C) Politeknik Negeri Malang. Aplikasi ini berfungsi memberikan informasi awal atau indikasi kondisi kulit wajah (seperti jerawat, komedo, dan noda bekas jerawat) melalui pemrosesan citra wajah dari 3 sudut (depan, kiri, kanan) menggunakan model Machine Learning.\n\n',
                        ),
                        _heading('2. Batasan Tanggung Jawab'),
                        _boldLabel('Bukan Diagnosis Medis: '),
                        const TextSpan(
                          text: 'Analisis skala Investigator\'s Global Assessment (IGA) yang diberikan oleh aplikasi merupakan informasi awal dan bukan merupakan diagnosis medis, rekomendasi dokter, atau resep pengobatan.\n',
                        ),
                        _boldLabel('Keterbatasan Akurasi: '),
                        const TextSpan(
                          text: 'Hasil pemindaian sangat bergantung pada kualitas foto, pencahayaan, dan algoritma Computer Vision yang masih memiliki keterbatasan. Kami tidak menjamin tingkat akurasi 100%.\n\n',
                        ),
                        _heading('3. Kebijakan Privasi dan Pengelolaan Data'),
                        _boldLabel('Foto Wajah: '),
                        const TextSpan(
                          text: 'Foto yang Anda unggah akan diproses di back-end (FastAPI) dan disimpan secara aman di Cloudflare R2 Storage. Data ini tidak digunakan sebagai dataset pelatihan model lanjutan secara otomatis.\n',
                        ),
                        _boldLabel('Data Sesi: '),
                        const TextSpan(
                          text: 'Informasi hasil analisis, wawancara profil kulit singkat (gender, umur, penggunaan sunscreen), dan riwayat disimpan di database server. Pengguna memiliki hak penuh untuk menghapus sesi pada aplikasi yang secara otomatis menghapus foto dan metadatanya.\n\n',
                        ),
                        _heading('4. Kepatuhan Penggunaan'),
                        const TextSpan(
                          text: 'Pengguna dilarang menyalahgunakan sistem dengan mengunggah gambar yang tidak pantas atau merekayasa balik (reverse engineering) infrastruktur machine learning API kami.\n\n',
                        ),
                        _heading('5. Perubahan Syarat dan Ketentuan'),
                        const TextSpan(
                          text: 'Syarat dan Ketentuan ini dapat diperbarui sewaktu-waktu sejalan dengan tahap pengembangan.',
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
