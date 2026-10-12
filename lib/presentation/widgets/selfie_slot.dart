import 'dart:io';

import 'package:pbl_skin_problem_detector/data/models/scan_session.dart';
import 'package:pbl_skin_problem_detector/presentation/theme/app_colors.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class SelfieSlot extends StatelessWidget {
  const SelfieSlot({
    super.key,
    required this.angle,
    required this.path,
    required this.onPick,
  });

  final SelfieAngle angle;
  final String? path;
  final VoidCallback onPick;

  String get _label => switch (angle) {
        SelfieAngle.front => 'Depan',
        SelfieAngle.left => 'Kiri',
        SelfieAngle.right => 'Kanan',
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final filled = path != null;

    return GestureDetector(
      onTap: onPick,
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: scheme.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: filled ? scheme.primary : scheme.border,
                  width: filled ? 2 : 1,
                ),
                image: filled
                    ? DecorationImage(
                        image: FileImage(File(path!)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: filled
                  ? Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            LucideIcons.check,
                            size: 14,
                            color: scheme.primaryForeground,
                          ),
                        ),
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          LucideIcons.imagePlus,
                          color: AppColors.brand,
                        ),
                        const Gap(6),
                        const Text('Pilih').xSmall.muted,
                      ],
                    ),
            ),
          ),
          const Gap(8),
          Text(_label).small.semiBold,
        ],
      ),
    );
  }
}
