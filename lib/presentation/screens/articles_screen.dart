import 'package:pbl_skin_problem_detector/presentation/theme/app_colors.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class ArticlesScreen extends StatelessWidget {
  const ArticlesScreen({super.key});

  static const _articles = [
    (
      'Mengenal Skala GEA',
      'Bagaimana dokter menilai tingkat keparahan jerawat dari grade 0 hingga 5.'
    ),
    (
      'Tips Skincare Sehari-hari',
      'Rutinitas sederhana membersihkan, melembapkan, dan memakai sunscreen.'
    ),
    (
      'Makanan yang Bisa Memicu Jerawat',
      'Kaitan pola makan manis/gorengan dengan inflamasi kulit.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.paddingOf(context).top + 20,
        20,
        20,
      ),
      itemCount: _articles.length + 1,
      separatorBuilder: (_, _) => const Gap(12),
      itemBuilder: (context, index) {
        if (index == 0) {
          return const Text(
            'Artikel',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.slate,
            ),
          );
        }
        final item = _articles[index - 1];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E9EF)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 8,
                width: 56,
                decoration: BoxDecoration(
                  color: index.isEven ? AppColors.mint : AppColors.blush,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const Gap(12),
              Text(
                item.$1,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.slate,
                ),
              ),
              const Gap(6),
              Text(
                item.$2,
                style: const TextStyle(
                  color: Color(0xFF7A8494),
                  height: 1.4,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
