import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pbl_skin_problem_detector/business/cubit/scan_cubit.dart';
import 'package:pbl_skin_problem_detector/presentation/theme/app_colors.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class ScanIntroScreen extends StatelessWidget {
  const ScanIntroScreen({super.key});

  static const _instructions = [
    'Hapus makeup dan lepas kacamata',
    'Pastikan rambut tidak menutupi wajah',
    'Hadapkan wajah ke kamera dengan ekspresi netral',
    'Pastikan pencahayaan Anda cukup',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      headers: [
        AppBar(
          leading: [
            IconButton.ghost(
              icon: const Icon(LucideIcons.x),
              onPressed: () => context.pop(),
            ),
          ],
          title: const Text('Scan Wajah'),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Container(
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: [AppColors.mint, AppColors.sand],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Center(
              child: Icon(LucideIcons.scanFace, size: 72, color: AppColors.slate),
            ),
          ),
          const Gap(24),
          const Text(
            'AMBIL 3 SELFIE',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.slate,
            ),
          ),
          const Gap(12),
          const Text(
            'Untuk hasil terbaik, ikuti panduan berikut sebelum mengambil foto:',
            style: TextStyle(color: Color(0xFF7A8494), height: 1.4),
          ),
          const Gap(16),
          ..._instructions.map(
            (text) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('•  ', style: TextStyle(color: AppColors.slate)),
                  Expanded(
                    child: Text(
                      text,
                      style: const TextStyle(
                        color: AppColors.slate,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Gap(8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.sand.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.sand),
            ),
            child: const Text(
              'Aplikasi membutuhkan akses kamera/galeri. Pada prototipe ini, foto hanya disimpan sementara di sesi aplikasi (belum dikirim ke server).',
              style: TextStyle(color: AppColors.slate, height: 1.4),
            ),
          ),
          const Gap(28),
          PrimaryButton(
            onPressed: () {
              context.read<ScanCubit>().startCapture();
              context.push('/scan/capture');
            },
            child: const Text('AMBIL 3 SELFIE'),
          ),
          const Gap(12),
          Center(
            child: GhostButton(
              onPressed: () {
                context.read<ScanCubit>().startUpload();
                context.push('/scan/upload');
              },
              child: const Text(
                'UNGGAH FOTO SELFIE',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
