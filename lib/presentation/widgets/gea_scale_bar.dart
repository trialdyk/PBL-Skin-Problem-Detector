import 'package:pbl_skin_problem_detector/presentation/theme/app_colors.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class GeaScaleBar extends StatelessWidget {
  const GeaScaleBar({super.key, required this.activeGrade});

  final int activeGrade;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(6, (grade) {
        final isActive = grade == activeGrade;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: isActive ? 60 : 40,
                  decoration: BoxDecoration(
                    color: AppColors.gradeColor(grade)
                        .withValues(alpha: isActive ? 1 : 0.55),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isActive ? scheme.foreground : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$grade',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.onGrade(grade),
                    ),
                  ),
                ),
                const Gap(6),
                Icon(
                  LucideIcons.chevronUp,
                  size: 14,
                  color: isActive ? scheme.foreground : Colors.transparent,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
