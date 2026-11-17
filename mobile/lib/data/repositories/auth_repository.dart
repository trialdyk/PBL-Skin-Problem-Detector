import 'package:pbl_skin_problem_detector/data/models/user_model.dart';
import 'package:pbl_skin_problem_detector/data/services/api_client.dart';
import 'package:pbl_skin_problem_detector/data/services/auth/auth.dart';

class AuthRepository {
  AuthRepository(this._service);

  final AuthService _service;
  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  /// Shared API client (sudah berisi Bearer setelah login).
  ApiClient get api => _service.api;

  Future<UserModel> login({
    required String email,
    required String password,
    required bool acceptedTerms,
    bool viaGoogle = false,
  }) async {
    final user = await _service.login(
      email: email,
      password: password,
      acceptedTerms: acceptedTerms,
      viaGoogle: viaGoogle,
    );
    _currentUser = user;
    return user;
  }

  Future<UserModel> register({
    required String email,
    required String password,
    required bool acceptedTerms,
    String? fullName,
  }) async {
    final user = await _service.register(
      email: email,
      password: password,
      acceptedTerms: acceptedTerms,
      fullName: fullName,
    );
    _currentUser = user;
    return user;
  }

  Future<UserModel> loginWithGoogle({required bool acceptedTerms}) async {
    final user = await _service.loginWithGoogle(acceptedTerms: acceptedTerms);
    _currentUser = user;
    return user;
  }

  /// Memperbarui nama dan email pengguna pada sesi aktif di memori aplikasi.
  UserModel? updateProfile({
    required String fullName,
    required String email,
  }) {
    final current = _currentUser;
    if (current == null) return null;
    final trimmedName = fullName.trim();
    final normalizedEmail = email.trim().toLowerCase();
    if (trimmedName.isEmpty || normalizedEmail.isEmpty) return current;
    final updated = current.copyWith(
      fullName: trimmedName,
      email: normalizedEmail,
    );
    _currentUser = updated;
    return updated;
  }

  /// Menyimpan pembaruan kata sandi pada sesi aktif (menunggu endpoint backend).
  bool changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    if (_currentUser == null) return false;
    if (currentPassword.isEmpty ||
        newPassword.length < 8 ||
        newPassword.length > 128) {
      return false;
    }
    return true;
  }

  void logout() {
    _currentUser = null;
    _service.clearAccessToken();
  }
}
