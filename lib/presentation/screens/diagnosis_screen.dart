import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pbl_skin_problem_detector/business/cubit/scan_cubit.dart';
import 'package:pbl_skin_problem_detector/business/cubit/scan_state.dart';
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
          headers: [
            AppBar(
              title: const Text('Hasil Analisis'),
              trailing: [
                IconButton.ghost(
                  icon: const Icon(LucideIcons.x),
                  onPressed: backHome,
                ),
              ],
            ),
            const Divider(),
          ],
          child: state.phase == ScanPhase.diagnosing || result == null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(size: 36),
                      const Gap(16),
                      const Text('Menganalisis profil kulit...').muted,
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (preview != null)
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: Image.file(
                            File(preview),
                            width: 96,
                            height: 96,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    if (preview != null) const Gap(16),
                    Center(
                      child: const Text(
                        'Tingkat GEA Anda',
                        textAlign: TextAlign.center,
                      ).x2Large.bold,
                    ),
                    const Gap(6),
                    Center(
                      child: const Text(
                        'Global Evaluation of Acne: 0–1 (ringan) hingga 4–5 (sangat berat).',
                        textAlign: TextAlign.center,
                      ).small.muted,
                    ),
                    const Gap(20),
                    GeaResultBadge(result: result),
                    const Gap(20),
                    Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Skala keparahan').small.semiBold,
                          const Gap(14),
                          GeaScaleBar(activeGrade: result.grade),
                        ],
                      ),
                    ),
                    const Gap(12),
                    Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(LucideIcons.fileText, size: 16),
                              const Gap(8),
                              const Text('Penjelasan').small.semiBold,
                            ],
                          ),
                          const Gap(8),
                          Text(result.description).small,
                        ],
                      ),
                    ),
                    const Gap(12),
                    const Alert(
                      leading: Icon(LucideIcons.info),
                      title: Text('Catatan'),
                      content: Text(
                        'Hasil saat ini rule-based dari interview (foto belum dianalisis ML). Bukan pengganti diagnosis dokter.',
                      ),
                    ),
                    const Gap(24),
                    PrimaryButton(
                      alignment: Alignment.center,
                      leading: const Icon(LucideIcons.house),
                      onPressed: backHome,
                      child: const Text('Kembali ke Beranda'),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
