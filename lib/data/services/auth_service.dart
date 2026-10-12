import 'package:pbl_skin_problem_detector/data/models/user_model.dart';

class AuthException implements Exception {
  AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

class AuthService {
  /// Akun demo prototipe. Selain kombinasi ini login ditolak.
  static const String demoEmail = 'pengguna@gmail.com';
  static const String demoPassword = 'skinscan123';

  /// [viaGoogle] menandai login lewat tombol Google (mock OAuth) sehingga
  /// pemeriksaan kredensial demo dilewati.
  Future<UserModel> login({
    required String email,
    required String password,
    required bool acceptedTerms,
    bool viaGoogle = false,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));

    if (!acceptedTerms) {
      throw AuthException(
        'Centang Syarat & Ketentuan serta Kebijakan Privasi terlebih dahulu.',
      );
    }

    // Validasi "tidak boleh kosong" & format email dikerjakan di UI
    // (LoginScreen) agar pengguna mendapat umpan balik langsung. Di sini
    // hanya kredensial yang diperiksa, meniru respons server.
    if (!viaGoogle && !_credentialsMatch(email, password)) {
      throw AuthException('Email atau kata sandi salah. Periksa kembali.');
    }

    return UserModel(email: email.trim());
  }

  bool _credentialsMatch(String email, String password) {
    return email.trim().toLowerCase() == demoEmail && password == demoPassword;
  }
}
