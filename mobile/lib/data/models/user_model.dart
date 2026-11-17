import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  const UserModel({
    required this.email,
    this.fullName,
    this.accessToken,
  });

  final String email;
  final String? fullName;
  final String? accessToken;

  /// Nama tampilan: memakai [fullName] bila terisi, atau bagian lokal [email].
  String get displayName {
    final trimmed = fullName?.trim();
    if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    if (email.isEmpty) return 'Pengguna';
    final local = email.contains('@') ? email.split('@').first : email;
    if (local.isEmpty) return 'Pengguna';
    return local[0].toUpperCase() + local.substring(1);
  }

  UserModel copyWith({
    String? email,
    String? fullName,
    String? accessToken,
    bool clearFullName = false,
  }) {
    return UserModel(
      email: email ?? this.email,
      fullName: clearFullName ? null : (fullName ?? this.fullName),
      accessToken: accessToken ?? this.accessToken,
    );
  }

  factory UserModel.fromAuthJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? const {};
    return UserModel(
      email: user['email'] as String? ?? '',
      fullName: user['full_name'] as String?,
      accessToken: json['access_token'] as String?,
    );
  }

  @override
  List<Object?> get props => [email, fullName, accessToken];
}
