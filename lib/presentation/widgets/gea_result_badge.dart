import 'package:pbl_skin_problem_detector/data/models/gea_result.dart';
import 'package:pbl_skin_problem_detector/presentation/theme/app_colors.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class GeaResultBadge extends StatelessWidget {
  const GeaResultBadge({super.key, required this.result});

  final GeaResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            result.badgeTitle,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: AppColors.slate,
            ),
          ),
          const Gap(6),
          Text(
            result.badgeSubtitle,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: AppColors.slate,
            ),
          ),
        ],
      ),
    );
  }
}
