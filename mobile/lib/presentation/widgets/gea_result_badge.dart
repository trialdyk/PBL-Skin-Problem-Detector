import 'package:pbl_skin_problem_detector/data/models/gea_result.dart';
import 'package:pbl_skin_problem_detector/presentation/theme/app_colors.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class GeaResultBadge extends StatelessWidget {
  const GeaResultBadge({super.key, required this.result});

  final GeaResult result;

  @override
  Widget build(BuildContext context) {
    final bg = AppColors.gradeColor(result.grade);
    final fg = AppColors.onGrade(result.grade);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: fg.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              'Global Evaluation of Acne',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
                color: fg,
              ),
            ),
          ),
          const Gap(14),
          Text(
            '${result.grade}',
            style: TextStyle(
              fontSize: 72,
              height: 1,
              fontWeight: FontWeight.w800,
              color: fg,
            ),
          ),
          const Gap(10),
          Text(
            result.labelId,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
          const Gap(2),
          Text(
            result.labelEn,
            style: TextStyle(
              fontSize: 13,
              color: fg.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}
