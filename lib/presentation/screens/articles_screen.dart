import 'package:pbl_skin_problem_detector/presentation/theme/app_colors.dart';
import 'package:pbl_skin_problem_detector/presentation/widgets/app_widgets.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class ArticlesScreen extends StatelessWidget {
  const ArticlesScreen({super.key});

  static const _articles = <_Article>[
    _Article(
      icon: LucideIcons.activity,
      category: 'Edukasi',
      title: 'Mengenal Skala GEA',
      body:
          'Bagaimana dokter menilai tingkat keparahan jerawat dari grade 0 hingga 5.',
      readTime: '3 mnt',
      tint: AppColors.muted,
      tone: AppColors.ink,
    ),
    _Article(
      icon: LucideIcons.droplets,
      category: 'Perawatan',
      title: 'Tips Skincare Sehari-hari',
      body:
          'Rutinitas sederhana membersihkan, melembapkan, dan memakai sunscreen.',
      readTime: '4 mnt',
      tint: AppColors.muted,
      tone: AppColors.ink,
    ),
    _Article(
      icon: LucideIcons.apple,
      category: 'Nutrisi',
      title: 'Makanan yang Bisa Memicu Jerawat',
      body: 'Kaitan pola makan manis/gorengan dengan inflamasi kulit.',
      readTime: '5 mnt',
      tint: AppColors.muted,
      tone: AppColors.ink,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.paddingOf(context).top + 20,
        20,
        24,
      ),
      children: [
        const Text('Artikel').x2Large.bold,
        const Gap(4),
        const Text('Bacaan singkat untuk merawat kulitmu.').muted,
        const Gap(20),
        for (final item in _articles) ...[
          TapCard(
            onTap: () {},
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconTile(
                  icon: item.icon,
                  background: item.tint,
                  foreground: item.tone,
                  size: 40,
                  iconSize: 20,
                ),
                const Gap(14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          OutlineBadge(child: Text(item.category)),
                          const Gap(8),
                          const Icon(
                            LucideIcons.clock,
                            size: 12,
                            color: AppColors.inkMuted,
                          ),
                          const Gap(4),
                          Text(item.readTime).xSmall.muted,
                        ],
                      ),
                      const Gap(10),
                      Text(item.title).base.semiBold,
                      const Gap(4),
                      Text(item.body).small.muted,
                    ],
                  ),
                ),
                const Gap(8),
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    LucideIcons.chevronRight,
                    size: 18,
                    color: AppColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
          const Gap(12),
        ],
      ],
    );
  }
}

class _Article {
  const _Article({
    required this.icon,
    required this.category,
    required this.title,
    required this.body,
    required this.readTime,
    required this.tint,
    required this.tone,
  });

  final IconData icon;
  final String category;
  final String title;
  final String body;
  final String readTime;
  final Color tint;
  final Color tone;
}
