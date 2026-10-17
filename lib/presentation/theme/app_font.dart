import 'package:flutter/painting.dart';
import 'package:google_fonts/google_fonts.dart';

/// Gaya teks Plus Jakarta Sans untuk `TextStyle` manual.
///
/// google_fonts memuat tiap bobot sebagai file terpisah, jadi bobot harus
/// diberikan di sini (bukan lewat `TextStyle.copyWith(fontWeight:)`) agar
/// tidak jatuh ke faux-bold.
TextStyle appFont({
  double? fontSize,
  FontWeight fontWeight = FontWeight.w400,
  Color? color,
  double? height,
  double? letterSpacing,
  FontStyle? fontStyle,
}) {
  return GoogleFonts.plusJakartaSans(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
    fontStyle: fontStyle,
  );
}
