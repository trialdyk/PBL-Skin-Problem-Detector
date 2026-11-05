class UserModel {
  const UserModel({
    required this.email,
    this.fullName,
    this.accessToken,
  });

  final String email;
  final String? fullName;
  final String? accessToken;

  factory UserModel.fromAuthJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? const {};
    return UserModel(
      email: user['email'] as String? ?? '',
      fullName: user['full_name'] as String?,
      accessToken: json['access_token'] as String?,
    );
  }
}
