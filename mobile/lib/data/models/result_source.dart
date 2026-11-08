/// Asal sebuah [GeaResult]: model CNN di backend atau aturan interview.
///
/// Dipakai layar hasil untuk memilih catatan yang ditampilkan dan oleh
/// `ScanRepository` untuk menandai hasil fallback.
enum ResultSource {
  /// `POST /ml/predict` berhasil (foto dianalisis CNN).
  ml,

  /// `GeaDiagnosisService` — rule-based dari jawaban interview.
  ruleBased,
}