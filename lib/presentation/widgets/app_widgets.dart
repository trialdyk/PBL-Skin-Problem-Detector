import 'package:pbl_skin_problem_detector/presentation/theme/app_colors.dart';
import 'package:pbl_skin_problem_detector/presentation/theme/app_font.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

/// Kotak ikon membulat — dipakai sebagai leading di card/list.
class IconTile extends StatelessWidget {
  const IconTile({
    super.key,
    required this.icon,
    this.background = AppColors.muted,
    this.foreground = AppColors.ink,
    this.size = 44,
    this.iconSize = 20,
    this.circle = false,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
  final double size;
  final double iconSize;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(10),
      ),
      child: Icon(icon, size: iconSize, color: foreground),
    );
  }
}

/// Card shadcn yang bisa ditekan.
class TapCard extends StatelessWidget {
  const TapCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.fillColor,
    this.borderColor,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? fillColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final card = Card(
      theme: CardTheme(
        padding: padding,
        filled: fillColor != null,
        fillColor: fillColor,
        borderColor: borderColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
    if (onTap == null) return card;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: card,
    );
  }
}

/// Judul section + aksi opsional.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ).large.semiBold,
        ),
        if (actionLabel != null)
          LinkButton(
            density: ButtonDensity.compact,
            onPressed: onAction,
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}

/// Toast untuk fitur yang belum tersedia di versi prototipe.
void showComingSoon(BuildContext context) {
  showToast(
    context: context,
    location: ToastLocation.bottomCenter,
    builder: (context, overlay) => const SurfaceCard(
      child: Text('Belum tersedia di versi prototipe.'),
    ),
  );
}

/// Link teks crimson tebal.
class AppTextLink extends StatelessWidget {
  const AppTextLink(
    this.label, {
    super.key,
    required this.onTap,
    this.fontSize = 14,
  });

  final String label;
  final VoidCallback? onTap;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Text(
        label,
        style: appFont(
          fontSize: fontSize,
          color: AppColors.brand,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Tombol penuh-lebar: gradien crimson (utama) atau blush ber-border (tonal).
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onTap,
    this.leading,
    this.trailingIcon,
    this.loading = false,
    this.tonal = false,
    this.height = 56,
    this.fontSize = 16,
    this.tonalForeground = AppColors.ink,
    this.dimmed = false,
  });

  final String label;
  final VoidCallback? onTap;
  final Widget? leading;
  final IconData? trailingIcon;
  final bool loading;
  final bool tonal;
  final double height;
  final double fontSize;
  final Color tonalForeground;

  /// Tampil pudar tetapi tetap menerima tap (mis. syarat belum terpenuhi).
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final foreground = tonal ? tonalForeground : AppColors.white;

    return GestureDetector(
      onTap: loading ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: Opacity(
        opacity: (onTap == null && !loading) || dimmed ? 0.55 : 1,
        child: Container(
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: tonal ? AppColors.muted : null,
            gradient: tonal
                ? null
                : const LinearGradient(
                    colors: [AppColors.brandBright, AppColors.brandDeep],
                  ),
            borderRadius: BorderRadius.circular(12),
            border: tonal ? Border.all(color: AppColors.border) : null,
            boxShadow: tonal
                ? null
                : const [
                    BoxShadow(
                      color: Color(0x4DBE185D),
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (loading) ...[
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    size: 18,
                    onSurface: !tonal,
                  ),
                ),
                const Gap(12),
              ] else if (leading != null) ...[
                leading!,
                const Gap(12),
              ],
              Text(
                label,
                style: appFont(
                  fontSize: fontSize,
                  fontWeight: tonal ? FontWeight.w500 : FontWeight.w600,
                  color: foreground,
                ),
              ),
              if (trailingIcon != null && !loading) ...[
                const Gap(10),
                Icon(trailingIcon, size: 20, color: foreground),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Toast singkat berisi petunjuk untuk pengguna.
void showHint(BuildContext context, String message) {
  showToast(
    context: context,
    location: ToastLocation.bottomCenter,
    builder: (context, overlay) => SurfaceCard(child: Text(message)),
  );
}

/// Header aplikasi: logo + nama + status AI, avatar di kanan.
class AppHeader extends StatelessWidget {
  const AppHeader({super.key, this.onProfile});

  /// Dipanggil saat avatar ditekan; `null` membuatnya non-interaktif.
  final VoidCallback? onProfile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.paddingOf(context).top + 10,
        16,
        10,
      ),
      decoration: const BoxDecoration(
        color: AppColors.page,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.brand,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              LucideIcons.scanFace,
              size: 18,
              color: AppColors.white,
            ),
          ),
          const Gap(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SkinScan ID',
                  style: appFont(fontSize: 15.5, fontWeight: FontWeight.w700),
                ),
                Row(
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: AppColors.brand,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const Gap(5),
                    Text(
                      'AI Diagnostik Aktif',
                      style: appFont(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.brand,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onProfile,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: AppColors.brand,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.user,
                size: 17,
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
