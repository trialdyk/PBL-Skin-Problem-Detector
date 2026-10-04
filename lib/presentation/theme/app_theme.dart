import 'package:pbl_skin_problem_detector/presentation/theme/app_colors.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

abstract final class AppTheme {
  static ThemeData get light {
    return ThemeData(
      colorScheme: brandLightScheme,
      radius: 0.4,
      typography: const Typography.geist(),
    );
  }

  static const ColorScheme brandLightScheme = ColorScheme(
    brightness: Brightness.light,
    background: AppColors.surface,
    foreground: AppColors.slate,
    card: AppColors.white,
    cardForeground: AppColors.slate,
    popover: AppColors.white,
    popoverForeground: AppColors.slate,
    primary: AppColors.mint,
    primaryForeground: AppColors.slate,
    secondary: AppColors.sand,
    secondaryForeground: AppColors.slate,
    muted: Color(0xFFEEF1F3),
    mutedForeground: Color(0xFF7A8494),
    accent: AppColors.blush,
    accentForeground: AppColors.slate,
    destructive: AppColors.blush,
    destructiveForeground: AppColors.slate,
    border: Color(0xFFD5DBE3),
    input: Color(0xFFD5DBE3),
    ring: AppColors.mint,
    chart1: AppColors.mint,
    chart2: AppColors.blush,
    chart3: AppColors.sand,
    chart4: AppColors.slate,
    chart5: Color(0xFF8BC4C7),
  );
}
