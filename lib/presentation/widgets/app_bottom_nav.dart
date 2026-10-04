import 'package:pbl_skin_problem_detector/presentation/theme/app_colors.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onChanged,
  });

  final int currentIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = <(IconData, String)>[
      (LucideIcons.house, 'Beranda'),
      (LucideIcons.newspaper, 'Artikel'),
      (LucideIcons.user, 'Profil'),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E9EF))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: List.generate(items.length, (index) {
            final selected = index == currentIndex;
            final item = items[index];
            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(index),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: EdgeInsets.symmetric(
                    horizontal: selected ? 12 : 8,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.slate : null,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item.$1,
                        size: 20,
                        color: selected
                            ? AppColors.white
                            : const Color(0xFF9AA3B0),
                      ),
                      if (selected) ...[
                        const Gap(6),
                        Flexible(
                          child: Text(
                            item.$2,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
