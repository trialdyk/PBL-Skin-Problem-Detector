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

  void logout() {
    _currentUser = null;
    _service.clearAccessToken();
  }
}
