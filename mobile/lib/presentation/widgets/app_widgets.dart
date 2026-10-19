import 'package:flutter_svg/flutter_svg.dart';
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
  showAppAlert(
    context,
    'Belum tersedia di versi prototipe.',
    icon: LucideIcons.info,
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

/// Kartu putih soft — sama bahasa visual home (radius besar + shadow tipis).
class SoftSurface extends StatelessWidget {
  const SoftSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = AppColors.white,
    this.radius = 22,
    this.border,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final double radius;
  final BoxBorder? border;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: border,
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
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

/// Latar halaman blush lembut (home / scan / interview / hasil).
class SoftPageBackground extends StatelessWidget {
  const SoftPageBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.muted, AppColors.page, Color(0xFFFFF8FA)],
        ),
      ),
      child: child,
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
            color: tonal ? AppColors.muted : AppColors.brand,
            borderRadius: BorderRadius.circular(16),
            border: tonal ? Border.all(color: AppColors.border) : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (loading) ...[
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(size: 18, onSurface: !tonal),
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
  showAppAlert(context, message);
}

/// Alert toast polished: ikon warning + gradient pink, ukuran responsif.
void showAppAlert(
  BuildContext context,
  String message, {
  IconData icon = LucideIcons.triangleAlert,
}) {
  showToast(
    context: context,
    location: ToastLocation.topRight,
    builder: (context, overlay) =>
        AppAlertToast(message: message, icon: icon, onClose: overlay.close),
  );
}

/// Kartu alert toast — proporsional di layar sempit & lebar.
class AppAlertToast extends StatelessWidget {
  const AppAlertToast({
    super.key,
    required this.message,
    this.icon = LucideIcons.triangleAlert,
    this.onClose,
  });

  final String message;
  final IconData icon;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    // Sisakan margin aman di kanan supaya tidak kepotong oleh edge / safe area.
    final maxWidth = (size.width - padding.right - 28).clamp(220.0, 300.0);
    final padH = size.width < 360 ? 12.0 : 14.0;
    final padV = size.width < 360 ? 11.0 : 13.0;
    final iconBox = size.width < 360 ? 32.0 : 36.0;
    final iconSize = size.width < 360 ? 15.0 : 17.0;
    final fontSize = size.width < 360 ? 12.5 : 13.5;

    return Padding(
      padding: EdgeInsets.only(top: padding.top > 0 ? 4 : 12, right: 12),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          padding: EdgeInsets.fromLTRB(padH, padV, padH, padV),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.brandBright,
                AppColors.brand,
                AppColors.brandDeep,
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.brand.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: iconBox,
                height: iconBox,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: iconSize, color: AppColors.white),
              ),
              SizedBox(width: padH),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 6, right: 6),
                  child: Text(
                    message,
                    style: appFont(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                      height: 1.35,
                    ),
                  ),
                ),
              ),
              const Gap(4),
              GestureDetector(
                onTap: onClose,
                behavior: HitTestBehavior.opaque,
                child: ClipOval(
                  child: Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.28),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.white.withValues(alpha: 0.55),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      LucideIcons.x,
                      size: 12,
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

/// Header aplikasi: logo + nama + notifikasi/avatar di kanan.
///
/// Pakai di dalam [Stack] (di atas konten). Satu gradient continuous
/// (solid → transparan) di bawah logo — tanpa tepi kotak keras.
class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    this.onProfile,
    this.onNotify,
    this.backgroundColor = AppColors.page,
    this.fadeHeight = defaultFadeHeight,
  });

  /// Dipanggil saat avatar ditekan; `null` membuatnya non-interaktif.
  final VoidCallback? onProfile;
  final VoidCallback? onNotify;

  /// Warna solid bar navbar (samakan dengan top background halaman).
  final Color backgroundColor;

  /// Tinggi zona fade di bawah bar (overlay ke konten).
  final double fadeHeight;

  /// Cuma tepi bawah navbar — soft tapi tidak merambah jauh ke konten.
  static const defaultFadeHeight = 28.0;
  static const _markAsset = 'assets/images/dermascan-mark-color.svg';
  static const _rowHeight = 40.0;
  static const _padTop = 12.0;
  static const _padBottom = 8.0;
  static const _fadeSamples = 24;

  /// Tinggi area solid (logo row).
  static double barHeight(BuildContext context) =>
      MediaQuery.paddingOf(context).top + _padTop + _rowHeight + _padBottom;

  /// Gradient soft (ease-in) tapi zona pendek — hanya di bawah navbar.
  static (List<Color>, List<double>) _softVeilGradient({
    required Color color,
    required double fadeStart,
  }) {
    final fadeSpan = 1.0 - fadeStart;
    final colors = <Color>[color, color];
    final stops = <double>[0.0, fadeStart];

    for (var i = 1; i <= _fadeSamples; i++) {
      final t = i / _fadeSamples;
      final eased = Curves.easeIn.transform(t);
      colors.add(color.withValues(alpha: (1.0 - eased).clamp(0.0, 1.0)));
      stops.add(fadeStart + fadeSpan * t);
    }
    return (colors, stops);
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final solidH = top + _padTop + _rowHeight + _padBottom;
    final totalH = solidH + fadeHeight;
    final fadeStart = solidH / totalH;
    final (veilColors, veilStops) = _softVeilGradient(
      color: backgroundColor,
      fadeStart: fadeStart,
    );

    return SizedBox(
      height: totalH,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: veilColors,
                    stops: veilStops,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, top + _padTop, 20, _padBottom),
            child: SizedBox(
              height: _rowHeight,
              child: Row(
                children: [
                  SvgPicture.asset(
                    _markAsset,
                    width: 36,
                    height: 36,
                    fit: BoxFit.contain,
                  ),
                  const Gap(10),
                  Text(
                    'DermaScan',
                    style: appFont(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: onNotify ?? () => showComingSoon(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.ink.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        LucideIcons.bell,
                        size: 18,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  const Gap(10),
                  GestureDetector(
                    onTap: onProfile,
                    behavior: HitTestBehavior.opaque,
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
