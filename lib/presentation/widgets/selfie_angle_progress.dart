import 'package:pbl_skin_problem_detector/data/models/scan_session.dart';
import 'package:pbl_skin_problem_detector/presentation/theme/app_colors.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

/// Indikator 3 sudut selfie (dipakai di layar kamera gelap).
class SelfieAngleProgress extends StatelessWidget {
  const SelfieAngleProgress({
    super.key,
    required this.current,
    required this.session,
  });

  final SelfieAngle current;
  final ScanSession session;

  @override
  Widget build(BuildContext context) {
    final angles = SelfieAngle.values;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: angles.map((angle) {
        final done = session.pathFor(angle) != null;
        final active = angle == current;
        final highlighted = active || done;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      highlighted ? AppColors.brandLight : AppColors.cameraMuted,
                  width: active ? 2.5 : 1.5,
                ),
                color: done ? AppColors.brandLight : null,
              ),
              child: Icon(
                done ? LucideIcons.check : LucideIcons.user,
                size: 20,
                color: done
                    ? AppColors.cameraBg
                    : (highlighted
                          ? AppColors.brandLight
                          : AppColors.cameraMuted),
              ),
            ),
            const Gap(6),
            Text(
              switch (angle) {
                SelfieAngle.front => 'Depan',
                SelfieAngle.left => 'Kiri',
                SelfieAngle.right => 'Kanan',
              },
              style: TextStyle(
                color: highlighted ? AppColors.white : AppColors.cameraMuted,
                fontSize: 12,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
