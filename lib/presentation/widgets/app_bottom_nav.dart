import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pbl_skin_problem_detector/business/cubit/scan_cubit.dart';
import 'package:pbl_skin_problem_detector/business/cubit/scan_state.dart';
import 'package:pbl_skin_problem_detector/presentation/theme/app_colors.dart';
import 'package:pbl_skin_problem_detector/presentation/theme/app_font.dart';
import 'package:pbl_skin_problem_detector/presentation/widgets/app_widgets.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onChanged,
  });

  /// Indeks item aktif; `-1` bila tidak ada item yang aktif.
  final int currentIndex;
  final ValueChanged<int> onChanged;

  static const _items = <(IconData, String)>[
    (LucideIcons.house, 'Beranda'),
    (LucideIcons.camera, 'Foto'),
    (LucideIcons.clipboardList, 'Wawancara'),
    (LucideIcons.chartColumn, 'Laporan GEA'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
      decoration: const BoxDecoration(
        color: AppColors.page,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            for (var i = 0; i < _items.length; i++)
              Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(i),
                  behavior: HitTestBehavior.opaque,
                  child: _NavItem(
                    icon: _items[i].$1,
                    label: _items[i].$2,
                    selected: i == currentIndex,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
  });

  final IconData icon;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.brand : AppColors.inkMuted;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20, color: color),
        const Gap(4),
        Text(
          label,
          maxLines: 1,
          style: appFont(
            fontSize: 10.5,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Indeks item di [AppBottomNav].
abstract final class NavIndex {
  static const home = 0;
  static const photo = 1;
  static const interview = 2;
  static const report = 3;
}

/// Navigasi bersama untuk bottom nav. [current] adalah item yang sedang
/// aktif; [onHome] menggantikan perpindahan ke `/home` bila layar saat ini
/// sudah berada di home.
void handleBottomNavTap(
  BuildContext context,
  int index, {
  required int current,
  VoidCallback? onHome,
}) {
  final scan = context.read<ScanCubit>();

  switch (index) {
    case NavIndex.home:
      if (onHome != null) {
        onHome();
      } else {
        context.go('/home');
      }
    case NavIndex.photo:
      if (current != NavIndex.photo) context.push('/scan');
    case NavIndex.interview:
      if (scan.state.phase == ScanPhase.interviewing) {
        context.go('/scan/interview');
      } else if (scan.state.session.hasAllPhotos) {
        scan.continueToInterview();
        context.go('/scan/interview');
      } else {
        showHint(context, 'Ambil ketiga foto wajah terlebih dahulu.');
      }
    case NavIndex.report:
      if (scan.state.result != null) {
        context.push('/scan/result');
      } else {
        showHint(context, 'Belum ada hasil. Selesaikan pemeriksaan dahulu.');
      }
  }
}
