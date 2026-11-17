/// Response from `POST /auth/register` and `POST /auth/resend-verification`.
class RegisterPending {
  const RegisterPending({
    required this.email,
    required this.message,
    required this.expiresIn,
  });

  final String email;
  final String message;
  final int expiresIn;

  factory RegisterPending.fromJson(Map<String, dynamic> json) {
    return RegisterPending(
      email: json['email'] as String? ?? '',
      message: json['message'] as String? ?? '',
      expiresIn: json['expires_in'] as int? ?? 900,
    );
  }
}
