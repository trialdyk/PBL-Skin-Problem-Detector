import 'package:shadcn_flutter/shadcn_flutter.dart';

/// Brand palette — latar blush pink + card putih + teks plum + crimson/pink.
abstract final class AppColors {
  // Netral (blush / plum)
  static const Color white = Color(0xFFFFFFFF);
  static const Color page = Color(0xFFFFF8FA);
  static const Color muted = Color(0xFFFFF0F4);
  static const Color border = Color(0xFFF8DCE5);
  static const Color ink = Color(0xFF1F1A1D);
  static const Color inkMuted = Color(0xFF5E4553);

  // Brand (crimson pink)
  static const Color brand = Color(0xFFBE185D);
  static const Color brandBright = Color(0xFFD63A6A);
  static const Color brandDeep = Color(0xFFA8154F);
  static const Color brandSoft = Color(0xFFFFE4EC);
  static const Color brandLight = Color(0xFFF9A8C4);

  // Aksen pendukung
  static const Color accent = Color(0xFFF97316);
  static const Color accentSoft = Color(0xFFFFEDD5);
  static const Color amber = Color(0xFFF59E0B);

  // Layar kamera (gelap netral)
  static const Color cameraBg = Color(0xFF18181B);
  static const Color cameraOverlay = Color(0xFF09090B);
  static const Color cameraMuted = Color(0xFFA1A1AA);

  /// Warna tingkat keparahan GEA 0–5 (hijau → merah tua).
  static const List<Color> grade = [
    Color(0xFF86C99B),
    Color(0xFFB7C77A),
    Color(0xFFEAC95B),
    Color(0xFFEE9B4E),
    Color(0xFFE0603F),
    Color(0xFFB4342B),
  ];

  static Color gradeColor(int g) => grade[g.clamp(0, 5)];

  /// Warna teks yang terbaca di atas [gradeColor].
  static Color onGrade(int g) => g >= 4 ? white : ink;
}
