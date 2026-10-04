import 'package:pbl_skin_problem_detector/data/models/user_model.dart';

class AuthException implements Exception {
  AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

class AuthService {
  Future<UserModel> login({
    required String email,
    required String password,
    required bool acceptedTerms,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));

    if (!acceptedTerms) {
      throw AuthException(
        'Centang Syarat & Ketentuan serta Kebijakan Privasi terlebih dahulu.',
      );
    }
    if (email.trim().isEmpty || password.trim().isEmpty) {
      throw AuthException('Email dan password tidak boleh kosong.');
    }

    return UserModel(email: email.trim());
  }
}
