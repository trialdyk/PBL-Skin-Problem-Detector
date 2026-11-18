/// Kegagalan saat memanggil endpoint `/history`.
class HistoryException implements Exception {
  HistoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
