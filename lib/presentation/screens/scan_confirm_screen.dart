import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pbl_skin_problem_detector/business/cubit/scan_cubit.dart';
import 'package:pbl_skin_problem_detector/business/cubit/scan_state.dart';
import 'package:pbl_skin_problem_detector/presentation/theme/app_colors.dart';
import 'package:pbl_skin_problem_detector/presentation/widgets/app_widgets.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class ScanConfirmScreen extends StatelessWidget {
  const ScanConfirmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScanCubit, ScanState>(
      builder: (context, state) {
        final photos = <(String, String?)>[
          ('Kiri', state.session.leftPath),
          ('Depan', state.session.frontPath),
          ('Kanan', state.session.rightPath),
        ];

        return Scaffold(
          headers: [
            AppBar(
              title: const Text('Konfirmasi'),
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
            const Divider(),
          ],
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 200,
                  child: Row(
                    children: [
                      for (var i = 0; i < photos.length; i++) ...[
                        Expanded(
                          child: Column(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: photos[i].$2 == null
                                      ? Container(
                                          color: AppColors.muted,
                                          alignment: Alignment.center,
                                          child: const Icon(
                                            LucideIcons.imageOff,
                                            color: AppColors.inkMuted,
                                          ),
                                        )
                                      : Image.file(
                                          File(photos[i].$2!),
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        ),
                                ),
                              ),
                              const Gap(8),
                              Text(photos[i].$1).small.semiBold,
                            ],
                          ),
                        ),
                        if (i != photos.length - 1) const Gap(10),
                      ],
                    ],
                  ),
                ),
                const Gap(32),
                const Center(
                  child: IconTile(
                    icon: LucideIcons.check,
                    background: AppColors.brand,
                    foreground: AppColors.white,
                    size: 64,
                    iconSize: 32,
                    circle: true,
                  ),
                ),
                const Gap(16),
                Center(child: const Text('Selesai!').x2Large.bold),
                const Gap(6),
                Center(
                  child: const Text('Selfie Anda siap untuk dianalisis.').muted,
                ),
                const Spacer(),
                PrimaryButton(
                  alignment: Alignment.center,
                  trailing: const Icon(LucideIcons.arrowRight),
                  onPressed: () {
                    context.read<ScanCubit>().continueToInterview();
                    context.go('/scan/interview');
                  },
                  child: const Text('Lanjutkan'),
                ),
                const Gap(10),
                OutlineButton(
                  alignment: Alignment.center,
                  leading: const Icon(LucideIcons.refreshCw),
                  onPressed: () {
                    context.read<ScanCubit>().retakePhotos();
                    context.go('/scan');
                  },
                  child: const Text('Selfie Ulang'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
