class AuthException implements Exception {
  AuthException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isEmailUnverified =>
      statusCode == 403 ||
      message.toLowerCase().contains('belum diverifikasi');

  @override
  String toString() => message;
}
