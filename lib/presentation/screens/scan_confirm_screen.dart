import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pbl_skin_problem_detector/business/cubit/scan_cubit.dart';
import 'package:pbl_skin_problem_detector/business/cubit/scan_state.dart';
import 'package:pbl_skin_problem_detector/presentation/theme/app_colors.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class ScanConfirmScreen extends StatelessWidget {
  const ScanConfirmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScanCubit, ScanState>(
      builder: (context, state) {
        final paths = [
          state.session.leftPath,
          state.session.frontPath,
          state.session.rightPath,
        ];

        return Scaffold(
          backgroundColor: AppColors.white,
          headers: [
            AppBar(
              trailing: [
                IconButton.ghost(
                  icon: const Icon(LucideIcons.x),
                  onPressed: () {
                    context.read<ScanCubit>().resetFlow();
                    context.go('/home');
                  },
                ),
              ],
            ),
          ],
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                SizedBox(
                  height: 180,
                  child: Row(
                    children: paths.map((path) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: path == null
                                ? Container(color: AppColors.sand)
                                : Image.file(File(path), fit: BoxFit.cover),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const Gap(28),
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: AppColors.mint,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.check,
                    color: AppColors.slate,
                    size: 32,
                  ),
                ),
                const Gap(16),
                const Text(
                  'Selesai!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.slate,
                  ),
                ),
                const Gap(8),
                const Text(
                  'Selfie Anda siap untuk dianalisis.',
                  style: TextStyle(color: Color(0xFF7A8494)),
                ),
                const Spacer(),
                PrimaryButton(
                  onPressed: () {
                    context.read<ScanCubit>().continueToInterview();
                    context.go('/scan/interview');
                  },
                  child: const Text('LANJUTKAN'),
                ),
                const Gap(12),
                OutlineButton(
                  onPressed: () {
                    context.read<ScanCubit>().retakePhotos();
                    context.go('/scan');
                  },
                  child: const Text('SELFIE ULANG'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
