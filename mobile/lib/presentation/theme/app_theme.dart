import 'package:google_fonts/google_fonts.dart';
import 'package:pbl_skin_problem_detector/presentation/theme/app_colors.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

abstract final class AppTheme {
  static ThemeData get light {
    return ThemeData(
      colorScheme: brandLightScheme,
      radius: 0.6,
      typography: _typography,
    );
  }

  /// Geist untuk ukuran/struktur, tetapi family-nya Plus Jakarta Sans.
  /// Tiap bobot didaftarkan terpisah supaya google_fonts memuat file bobot
  /// yang tepat (bukan faux-bold).
  static Typography get _typography {
    TextStyle weight(FontWeight w) => GoogleFonts.plusJakartaSans(fontWeight: w);

    return const Typography.geist().copyWith(
      sans: () => GoogleFonts.plusJakartaSans(),
      extraLight: () => weight(FontWeight.w200),
      light: () => weight(FontWeight.w300),
      normal: () => weight(FontWeight.w400),
      medium: () => weight(FontWeight.w500),
      semiBold: () => weight(FontWeight.w600),
      bold: () => weight(FontWeight.w700),
      extraBold: () => weight(FontWeight.w800),
    );
  }

  static const ColorScheme brandLightScheme = ColorScheme(
    brightness: Brightness.light,
    background: AppColors.page,
    foreground: AppColors.ink,
    card: AppColors.white,
    cardForeground: AppColors.ink,
    popover: AppColors.white,
    popoverForeground: AppColors.ink,
    primary: AppColors.brand,
    primaryForeground: AppColors.white,
    secondary: AppColors.muted,
    secondaryForeground: AppColors.ink,
    muted: AppColors.muted,
    mutedForeground: AppColors.inkMuted,
    accent: AppColors.brandSoft,
    accentForeground: AppColors.ink,
    destructive: Color(0xFFDC2626),
    destructiveForeground: AppColors.white,
    border: AppColors.border,
    // shadcn_flutter mengisi input/tombol outline dengan `input` @ alpha 0.3;
    // putih = field tetap putih bersih, border tetap dari `border`.
    input: AppColors.white,
    ring: AppColors.brandLight,
    chart1: AppColors.brand,
    chart2: AppColors.accent,
    chart3: AppColors.amber,
    chart4: AppColors.brandLight,
    chart5: AppColors.border,
  );
}
