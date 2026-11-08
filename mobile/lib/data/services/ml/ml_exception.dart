/// Kegagalan saat memanggil `POST /ml/predict`.
///
/// Repository menangkap exception ini lalu jatuh ke diagnosa rule-based, jadi
/// pesan di sini hanya untuk log — bukan untuk ditampilkan apa adanya.
class MlException implements Exception {
  MlException(this.message);
  final String message;

  @override
  String toString() => message;
}