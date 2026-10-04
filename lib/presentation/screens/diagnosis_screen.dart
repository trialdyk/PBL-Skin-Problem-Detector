import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pbl_skin_problem_detector/business/cubit/scan_cubit.dart';
import 'package:pbl_skin_problem_detector/business/cubit/scan_state.dart';
import 'package:pbl_skin_problem_detector/presentation/theme/app_colors.dart';
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

        return Scaffold(
          backgroundColor: AppColors.white,
          headers: [
            AppBar(
              title: const Text('SPOTSCAN'),
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
          child: state.phase == ScanPhase.diagnosing || result == null
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      Gap(16),
                      Text(
                        'Menganalisis profil kulit...',
                        style: TextStyle(color: AppColors.slate),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (preview != null)
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(preview),
                            width: 140,
                            height: 140,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    const Gap(24),
                    const Text(
                      'TINGKAT GEA (Global Evaluation of Acne) ANDA',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.slate,
                        height: 1.25,
                      ),
                    ),
                    const Gap(12),
                    const Text(
                      'Tingkat GEA menunjukkan seberapa parah permasalahan kulit berjerawat Anda: 0–1 (ringan) hingga 4–5 (sangat berat).',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF7A8494),
                        height: 1.4,
                      ),
                    ),
                    const Gap(24),
                    GeaScaleBar(activeGrade: result.grade),
                    const Gap(24),
                    GeaResultBadge(result: result),
                    const Gap(16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E9EF)),
                      ),
                      child: Text(
                        result.description,
                        style: const TextStyle(
                          color: AppColors.slate,
                          height: 1.45,
                        ),
                      ),
                    ),
                    const Gap(12),
                    const Text(
                      'Catatan: hasil saat ini rule-based dari interview (foto belum dianalisis ML).',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9AA3B0),
                      ),
                    ),
                    const Gap(24),
                    PrimaryButton(
                      onPressed: () {
                        context.read<ScanCubit>().resetFlow();
                        context.go('/home');
                      },
                      child: const Text('KEMBALI KE BERANDA'),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
