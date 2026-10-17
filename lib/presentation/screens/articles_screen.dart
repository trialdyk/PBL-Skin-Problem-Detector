import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pbl_skin_problem_detector/business/cubit/home_cubit.dart';
import 'package:pbl_skin_problem_detector/data/models/article_item.dart';
import 'package:pbl_skin_problem_detector/presentation/theme/app_colors.dart';
import 'package:pbl_skin_problem_detector/presentation/theme/app_font.dart';
import 'package:pbl_skin_problem_detector/presentation/widgets/app_widgets.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class ArticlesScreen extends StatefulWidget {
  const ArticlesScreen({super.key});

  @override
  State<ArticlesScreen> createState() => _ArticlesScreenState();
}

class _ArticlesScreenState extends State<ArticlesScreen> {
  static const _featured = <ArticleItem>[
    ArticleItem(
      category: 'Edukasi',
      badge: 'Update GEA',
      title: 'Mengenal Skala GEA untuk Jerawat',
      body:
          'Bagaimana dokter menilai tingkat keparahan jerawat dari grade 0 hingga 5 secara objektif.',
      readTime: '3 mnt',
      image: 'assets/images/acne_people.png',
      related: [
        'Grade 0–5: apa artinya untuk kulitmu',
        'Bedanya papula, pustula, dan nodus',
        'Kapan hasil scan perlu dikonfirmasi dokter',
      ],
    ),
    ArticleItem(
      category: 'Perawatan',
      badge: 'Panduan Scan',
      title: 'Cara Scan Wajah yang Benar',
      body:
          'Panduan selfie depan, kiri, dan kanan agar analisis GEA lebih akurat.',
      readTime: '4 mnt',
      image: 'assets/images/3791190.png',
    ),
    ArticleItem(
      category: 'Nutrisi',
      title: 'Makanan yang Bisa Memicu Jerawat',
      body: 'Kaitan pola makan manis dan gorengan dengan inflamasi kulit.',
      readTime: '5 mnt',
      image: 'assets/images/acne_people.png',
    ),
  ];

  static const _shorts = <ArticleItem>[
    ArticleItem(
      category: 'Tips',
      title: 'Sunscreen setiap hari',
      body: 'Lindungi barrier kulit dari UV, meski di dalam ruangan.',
      readTime: '1 mnt',
      image: 'assets/images/acne_people.png',
    ),
    ArticleItem(
      category: 'Tips',
      title: 'Jangan over-exfoliate',
      body: 'Kulit inflamasi butuh tenang, bukan scrub setiap malam.',
      readTime: '2 mnt',
      image: 'assets/images/3791190.png',
    ),
  ];

  void _openDetail(ArticleItem article) {
    context.push('/articles/detail', extra: article);
  }

  final _search = TextEditingController();
  final _pageController = PageController(viewportFraction: 0.92);
  int _tab = 0; // 0 = Pilihan, 1 = Singkat
  int _page = 0;

  @override
  void dispose() {
    _search.dispose();
    _pageController.dispose();
    super.dispose();
  }

  List<ArticleItem> get _items {
    final source = _tab == 0 ? _featured : _shorts;
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return source;
    return source
        .where(
          (a) =>
              a.title.toLowerCase().contains(q) ||
              a.body.toLowerCase().contains(q) ||
              a.category.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.muted, AppColors.page, Color(0xFFFFF8FA)],
        ),
      ),
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          0,
          MediaQuery.paddingOf(context).top + 12,
          0,
          28,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => context.read<HomeCubit>().setTab(2),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.brand,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.user,
                      size: 18,
                      color: AppColors.white,
                    ),
                  ),
                ),
                const Spacer(),
                _RoundIconButton(
                  icon: LucideIcons.sparkles,
                  onTap: () => showComingSoon(context),
                ),
                const Gap(10),
                _RoundIconButton(
                  icon: LucideIcons.bell,
                  onTap: () => showComingSoon(context),
                ),
              ],
            ),
          ),
          const Gap(18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Temukan Artikel\nTerbaru',
              style: appFont(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
                height: 1.15,
              ),
            ),
          ),
          const Gap(16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _TabSwitcher(
              index: _tab,
              onChanged: (i) {
                setState(() {
                  _tab = i;
                  _page = 0;
                });
                if (_pageController.hasClients) {
                  _pageController.jumpToPage(0);
                }
              },
            ),
          ),
          const Gap(14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.ink.withValues(alpha: 0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.search,
                          size: 18,
                          color: AppColors.inkMuted,
                        ),
                        const Gap(10),
                        Expanded(
                          child: TextField(
                            controller: _search,
                            placeholder: const Text('Cari artikel...'),
                            padding: EdgeInsets.zero,
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Gap(10),
                _RoundIconButton(
                  icon: LucideIcons.mic,
                  filled: true,
                  onTap: () => showComingSoon(context),
                ),
              ],
            ),
          ),
          const Gap(20),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: Text(
                'Tidak ada artikel yang cocok.',
                textAlign: TextAlign.center,
                style: appFont(fontSize: 14, color: AppColors.inkMuted),
              ),
            )
          else ...[
            SizedBox(
              height: 360,
              child: PageView.builder(
                controller: _pageController,
                itemCount: items.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: _FeaturedCard(
                      article: items[index],
                      onSeeMore: () => _openDetail(items[index]),
                    ),
                  );
                },
              ),
            ),
            const Gap(14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: i == _page ? 22 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: i == _page
                          ? AppColors.brand
                          : AppColors.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  if (i != items.length - 1) const Gap(6),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: filled ? AppColors.brand : AppColors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 18,
          color: filled ? AppColors.white : AppColors.ink,
        ),
      ),
    );
  }
}

class _TabSwitcher extends StatelessWidget {
  const _TabSwitcher({required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabChip(
              label: 'Pilihan',
              selected: index == 0,
              onTap: () => onChanged(0),
            ),
          ),
          Expanded(
            child: _TabChip(
              label: 'Singkat',
              selected: index == 1,
              onTap: () => onChanged(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [AppColors.brandBright, AppColors.brand],
                )
              : null,
          color: selected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: appFont(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.white : AppColors.ink,
          ),
        ),
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({
    required this.article,
    required this.onSeeMore,
  });

  final ArticleItem article;
  final VoidCallback onSeeMore;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSeeMore,
      child: Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.07),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 168,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  article.image,
                  fit: BoxFit.cover,
                  alignment: const Alignment(0, -0.2),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      article.category,
                      style: appFont(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brand,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  article.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: appFont(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                    height: 1.25,
                  ),
                ),
                const Gap(8),
                Text(
                  article.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: appFont(
                    fontSize: 12.5,
                    color: AppColors.inkMuted,
                    height: 1.4,
                  ),
                ),
                const Gap(10),
                Row(
                  children: [
                    GestureDetector(
                      onTap: onSeeMore,
                      child: Text(
                        'Lihat selengkapnya',
                        style: appFont(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.brand,
                        ),
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      LucideIcons.clock,
                      size: 12,
                      color: AppColors.inkMuted,
                    ),
                    const Gap(4),
                    Text(
                      article.readTime,
                      style: appFont(
                        fontSize: 11.5,
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
}
