import 'package:go_router/go_router.dart';
import 'package:pbl_skin_problem_detector/data/models/article_item.dart';
import 'package:pbl_skin_problem_detector/presentation/theme/app_colors.dart';
import 'package:pbl_skin_problem_detector/presentation/theme/app_font.dart';
import 'package:pbl_skin_problem_detector/presentation/widgets/app_widgets.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class ArticleDetailScreen extends StatelessWidget {
  const ArticleDetailScreen({super.key, required this.article});

  final ArticleItem article;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final related = article.related.isNotEmpty
        ? article.related
        : const [
            'Cara membedakan jerawat inflamasi dan non-inflamasi',
            'Kapan harus konsultasi ke dokter kulit',
            'Mitos skincare yang sering menyesatkan',
            'Peran sunscreen dalam mencegah bekas jerawat',
          ];

    return Scaffold(
      backgroundColor: AppColors.white,
      child: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 320 + top,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        article.image,
                        fit: BoxFit.cover,
                        alignment: const Alignment(0, -0.25),
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.ink.withValues(alpha: 0.25),
                              AppColors.ink.withValues(alpha: 0.05),
                              AppColors.white.withValues(alpha: 0.0),
                              AppColors.white,
                            ],
                            stops: const [0.0, 0.35, 0.72, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -28),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.brandBright,
                                AppColors.brand,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            (article.badge ?? article.category).toUpperCase(),
                            style: appFont(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.white,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        const Gap(14),
                        Text(
                          article.title,
                          style: appFont(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                            height: 1.2,
                          ),
                        ),
                        const Gap(12),
                        Text(
                          article.body,
                          style: appFont(
                            fontSize: 14.5,
                            color: AppColors.inkMuted,
                            height: 1.55,
                          ),
                        ),
                        const Gap(10),
                        Row(
                          children: [
                            const Icon(
                              LucideIcons.clock,
                              size: 13,
                              color: AppColors.inkMuted,
                            ),
                            const Gap(5),
                            Text(
                              'Bacaan ${article.readTime}',
                              style: appFont(
                                fontSize: 12,
                                color: AppColors.inkMuted,
                              ),
                            ),
                          ],
                        ),
                        const Gap(22),
                        Text(
                          'Bacaan terkait',
                          style: appFont(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        const Gap(12),
                        for (var i = 0; i < related.length; i++) ...[
                          Text(
                            related[i],
                            style: appFont(
                              fontSize: 14.5,
                              fontWeight:
                                  i == 0 ? FontWeight.w700 : FontWeight.w500,
                              fontStyle:
                                  i == 0 ? FontStyle.italic : FontStyle.normal,
                              color: i == 0
                                  ? AppColors.ink
                                  : AppColors.inkMuted,
                              height: 1.45,
                            ),
                          ),
                          if (i != related.length - 1) const Gap(14),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: top + 8,
            left: 16,
            right: 16,
            child: Row(
              children: [
                _GlassCircleButton(
                  icon: LucideIcons.arrowLeft,
                  onTap: () => context.pop(),
                ),
                const Gap(10),
                Expanded(
                  child: Container(
                    height: 42,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppColors.white.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.brandBright,
                                  AppColors.brand,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Pilihan',
                              style: appFont(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              'Singkat',
                              style: appFont(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Gap(10),
                _GlassCircleButton(
                  icon: LucideIcons.search,
                  onTap: () => showComingSoon(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassCircleButton extends StatelessWidget {
  const _GlassCircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.35),
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.white.withValues(alpha: 0.45),
          ),
        ),
        child: Icon(icon, size: 18, color: AppColors.white),
      ),
    );
  }
}
