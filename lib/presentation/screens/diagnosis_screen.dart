import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pbl_skin_problem_detector/business/cubit/scan_cubit.dart';
import 'package:pbl_skin_problem_detector/business/cubit/scan_state.dart';
import 'package:pbl_skin_problem_detector/presentation/theme/app_colors.dart';
import 'package:pbl_skin_problem_detector/presentation/theme/app_font.dart';
import 'package:pbl_skin_problem_detector/presentation/widgets/app_widgets.dart';
import 'package:pbl_skin_problem_detector/presentation/widgets/gea_result_badge.dart';
import 'package:pbl_skin_problem_detector/presentation/widgets/gea_scale_bar.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class DiagnosisScreen extends StatelessWidget {
  const DiagnosisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScanCubit, ScanState>(
      builder: (context, state) {
        final result = state.result;
        final preview = state.session.frontPath;

        void backHome() {
          context.read<ScanCubit>().resetFlow();
          context.go('/home');
        }

        return Scaffold(
          backgroundColor: AppColors.page,
          child: SoftPageBackground(
            child: Column(
              children: [
                _ResultHeader(onClose: backHome),
                Expanded(
                  child: state.phase == ScanPhase.diagnosing || result == null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(size: 36),
                              const Gap(16),
                              Text(
                                'Menganalisis profil kulit...',
                                style: appFont(
                                  fontSize: 14,
                                  color: AppColors.inkMuted,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                          children: [
                            if (preview != null) ...[
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.brandLight,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.brand.withValues(
                                          alpha: 0.12,
                                        ),
                                        blurRadius: 18,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: Image.file(
                                      File(preview),
                                      width: 92,
                                      height: 92,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                              const Gap(16),
                            ],
                            Text(
                              'Tingkat GEA Anda',
                              textAlign: TextAlign.center,
                              style: appFont(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                            const Gap(6),
                            Text(
                              'Global Evaluation of Acne: 0–1 (ringan) hingga '
                              '4–5 (sangat berat).',
                              textAlign: TextAlign.center,
                              style: appFont(
                                fontSize: 12.5,
                                color: AppColors.inkMuted,
                                height: 1.4,
                              ),
                            ),
                            const Gap(20),
                            GeaResultBadge(result: result),
                            const Gap(14),
                            SoftSurface(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Skala keparahan',
                                    style: appFont(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const Gap(14),
                                  GeaScaleBar(activeGrade: result.grade),
                                ],
                              ),
                            ),
                            const Gap(12),
                            SoftSurface(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        LucideIcons.fileText,
                                        size: 16,
                                        color: AppColors.brand,
                                      ),
                                      const Gap(8),
                                      Text(
                                        'Penjelasan',
                                        style: appFont(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Gap(10),
                                  Text(
                                    result.description,
                                    style: appFont(
                                      fontSize: 13.5,
                                      color: AppColors.inkMuted,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Gap(12),
                            SoftSurface(
                              color: AppColors.brandSoft,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    LucideIcons.info,
                                    size: 18,
                                    color: AppColors.brand,
                                  ),
                                  const Gap(10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Catatan',
                                          style: appFont(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const Gap(4),
                                        Text(
                                          'Hasil saat ini rule-based dari '
                                          'interview (foto belum dianalisis '
                                          'ML). Bukan pengganti diagnosis '
                                          'dokter.',
                                          style: appFont(
                                            fontSize: 12.5,
                                            color: AppColors.inkMuted,
                                            height: 1.45,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Gap(24),
                            AppButton(
                              label: 'Kembali ke Beranda',
                              leading: const Icon(
                                LucideIcons.house,
                                size: 18,
                                color: AppColors.white,
                              ),
                              onTap: backHome,
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ResultHeader extends StatelessWidget {
  const _ResultHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.paddingOf(context).top + 12,
        16,
        8,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Hasil Analisis',
              style: appFont(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
          ),
          GestureDetector(
            onTap: onClose,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.ink.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                LucideIcons.x,
                size: 18,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
