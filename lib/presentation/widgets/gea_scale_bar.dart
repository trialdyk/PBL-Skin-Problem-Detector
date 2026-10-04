import 'package:pbl_skin_problem_detector/presentation/theme/app_colors.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class GeaScaleBar extends StatelessWidget {
  const GeaScaleBar({super.key, required this.activeGrade});

  final int activeGrade;

  static const _fills = <Color>[
    AppColors.white,
    Color(0xFFD7EFF0),
    AppColors.mint,
    Color(0xFF8BC4C7),
    AppColors.slate,
    Color(0xFF3E4652),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(6, (grade) {
        final isActive = grade == activeGrade;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: isActive ? 64 : 48,
              decoration: BoxDecoration(
                color: _fills[grade],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isActive ? AppColors.slate : const Color(0xFFD5DBE3),
                  width: isActive ? 2 : 1,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                '$grade',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: grade >= 4 ? AppColors.white : AppColors.slate,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
