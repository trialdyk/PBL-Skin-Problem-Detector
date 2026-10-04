import 'package:go_router/go_router.dart';
import 'package:pbl_skin_problem_detector/presentation/theme/app_colors.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final horizontal = (size.width * 0.06).clamp(20.0, 32.0);
    final illustrationHeight = (size.height * 0.34).clamp(180.0, 280.0);

    return Scaffold(
      backgroundColor: AppColors.white,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(horizontal, 16, horizontal, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 40),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const Gap(12),
                      SizedBox(
                        height: illustrationHeight,
                        width: double.infinity,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Positioned(
                                top: 24,
                                child: Container(
                                  width: illustrationHeight * 0.55,
                                  height: illustrationHeight * 0.32,
                                  decoration: BoxDecoration(
                                    color: AppColors.mint,
                                    borderRadius: BorderRadius.circular(40),
                                  ),
                                ),
                              ),
                              Icon(
                                LucideIcons.scanFace,
                                size: illustrationHeight * 0.38,
                                color: AppColors.slate,
                              ),
                              Positioned(
                                bottom: 20,
                                left: 28,
                                child: Icon(
                                  LucideIcons.sparkles,
                                  color: AppColors.blush.withValues(alpha: 0.9),
                                  size: 22,
                                ),
                              ),
                              Positioned(
                                bottom: 28,
                                right: 28,
                                child: Icon(
                                  LucideIcons.leaf,
                                  color: AppColors.sand,
                                  size: 22,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Gap(18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 22,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.mint,
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                          const Gap(6),
                          _Dot(color: AppColors.mint.withValues(alpha: 0.35)),
                          const Gap(6),
                          _Dot(color: AppColors.mint.withValues(alpha: 0.35)),
                        ],
                      ),
                      const Gap(28),
                      const Text(
                        'Scan, Analisis, dan Pahami Kulitmu',
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.slate,
                          height: 1.25,
                        ),
                      ),
                      const Gap(12),
                      const Text(
                        'Mulailah perjalanan menuju kulit yang lebih sehat dengan analisis berbasis skala GEA.',
                        textAlign: TextAlign.center,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF7A8494),
                          height: 1.45,
                        ),
                      ),
                      const Spacer(),
                      const Gap(28),
                      SizedBox(
                        width: double.infinity,
                        child: PrimaryButton(
                          onPressed: () => context.go('/login'),
                          child: const Text('Masuk'),
                        ),
                      ),
                      const Gap(14),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text(
                            'Siap menganalisis kulitmu? ',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF7A8494),
                            ),
                          ),
                          GhostButton(
                            onPressed: () => context.go('/login'),
                            density: ButtonDensity.compact,
                            child: const Text(
                              'Lanjut',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.slate,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
