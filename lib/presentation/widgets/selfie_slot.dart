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
    return GestureDetector(
      onTap: onPick,
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.sand.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFD5DBE3)),
                image: path != null
                    ? DecorationImage(
                        image: FileImage(File(path!)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: path == null
                  ? const Center(
                      child: Icon(LucideIcons.camera, color: AppColors.slate),
                    )
                  : null,
            ),
          ),
          const Gap(8),
          Text(
            _label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.slate,
            ),
          ),
        ],
      ),
    );
  }
}
