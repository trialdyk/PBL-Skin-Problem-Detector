/// Error thrown by `UserService` endpoints with ready-to-display Indonesian text.
class UserException implements Exception {
  UserException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}
