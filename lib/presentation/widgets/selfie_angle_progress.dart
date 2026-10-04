import 'package:pbl_skin_problem_detector/data/models/scan_session.dart';
import 'package:pbl_skin_problem_detector/presentation/theme/app_colors.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

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
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: active || done
                      ? AppColors.mint
                      : const Color(0xFF9AA3B0),
                  width: 2,
                ),
                color: done ? AppColors.mint.withValues(alpha: 0.25) : null,
              ),
              child: Icon(
                LucideIcons.user,
                color: active || done
                    ? AppColors.white
                    : const Color(0xFF9AA3B0),
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
                color: active || done
                    ? AppColors.white
                    : const Color(0xFF9AA3B0),
                fontSize: 12,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
