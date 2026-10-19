import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pbl_skin_problem_detector/business/cubit/scan_cubit.dart';
import 'package:pbl_skin_problem_detector/business/cubit/scan_state.dart';
import 'package:pbl_skin_problem_detector/presentation/theme/app_colors.dart';
import 'package:pbl_skin_problem_detector/presentation/widgets/app_widgets.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

/// Floating pill bottom bar + FAB scan di tengah.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onChanged,
    this.onProfile,
    this.profileSelected = false,
  });

  /// Indeks item aktif; `-1` bila tidak ada item yang aktif.
  final int currentIndex;
  final ValueChanged<int> onChanged;

  /// Slot kanan (profil). Opsional.
  final VoidCallback? onProfile;
  final bool profileSelected;

  static const double _barHeight = 62;
  static const double _fabSize = 62;
  static const double _fabOverlap = 18;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final totalHeight = _barHeight + _fabOverlap;

    return ColoredBox(
      color: Colors.transparent,
      child: Padding(
        padding: EdgeInsets.fromLTRB(22, 8, 22, bottom > 0 ? bottom : 14),
        child: SizedBox(
          height: totalHeight,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              // Pill bar
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: _barHeight,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.ink.withValues(alpha: 0.10),
                        blurRadius: 28,
                        spreadRadius: 0,
                        offset: const Offset(0, 10),
                      ),
                      BoxShadow(
                        color: AppColors.brand.withValues(alpha: 0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: _NavIcon(
                            icon: LucideIcons.house,
                            selected: currentIndex == NavIndex.home,
                            onTap: () => onChanged(NavIndex.home),
                          ),
                        ),
                        Expanded(
                          child: _NavIcon(
                            icon: LucideIcons.clipboardList,
                            selected: currentIndex == NavIndex.interview,
                            onTap: () => onChanged(NavIndex.interview),
                          ),
                        ),
                        const Expanded(child: SizedBox()),
                        Expanded(
                          child: _NavIcon(
                            icon: LucideIcons.chartColumn,
                            selected: currentIndex == NavIndex.report,
                            onTap: () => onChanged(NavIndex.report),
                          ),
                        ),
                        Expanded(
                          child: _NavIcon(
                            icon: LucideIcons.user,
                            selected: profileSelected,
                            onTap: onProfile,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // FAB scan — mengambang di atas pill
              Positioned(
                top: 0,
                child: GestureDetector(
                  onTap: () => onChanged(NavIndex.photo),
                  child: Container(
                    width: _fabSize,
                    height: _fabSize,
                    decoration: BoxDecoration(
                      color: AppColors.brand,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brand.withValues(alpha: 0.40),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      LucideIcons.scanFace,
                      size: 26,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({required this.icon, required this.selected, this.onTap});

  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.brand : AppColors.ink;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: AnimatedScale(
          scale: selected ? 1.08 : 1.0,
          duration: const Duration(milliseconds: 180),
          child: Icon(icon, size: 23, color: color),
        ),
      ),
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
