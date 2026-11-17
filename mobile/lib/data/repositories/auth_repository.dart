import 'package:pbl_skin_problem_detector/data/models/register_pending.dart';
import 'package:pbl_skin_problem_detector/data/models/user_model.dart';
import 'package:pbl_skin_problem_detector/data/services/api_client.dart';
import 'package:pbl_skin_problem_detector/data/services/auth/auth.dart';
import 'package:pbl_skin_problem_detector/data/services/user/user.dart';

class AuthRepository {
  AuthRepository(this._service, {UserService? userService})
      : _userService = userService ?? UserService(apiClient: _service.api);

  final AuthService _service;
  final UserService _userService;
  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

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

  Future<RegisterPending> register({
    required String email,
    required String password,
    required bool acceptedTerms,
    String? fullName,
  }) {
    return _service.register(
      email: email,
      password: password,
      acceptedTerms: acceptedTerms,
      fullName: fullName,
    );
  }

  Future<UserModel> verifyEmail({
    required String email,
    required String code,
  }) async {
    final user = await _service.verifyEmail(email: email, code: code);
    _currentUser = user;
    return user;
  }

  Future<RegisterPending> resendVerification({required String email}) {
    return _service.resendVerification(email: email);
  }

  Future<UserModel> loginWithGoogle({required bool acceptedTerms}) async {
    final user = await _service.loginWithGoogle(acceptedTerms: acceptedTerms);
    _currentUser = user;
    return user;
  }

  /// Mengambil profil terbaru pengguna dari `GET /users/me`.
  Future<UserModel> fetchProfile() async {
    final user = await _userService.getProfile(currentUser: _currentUser);
    _currentUser = user;
    return user;
  }

  /// Memperbarui nama dan email pengguna lewat `PATCH /users/me`.
  Future<UserModel> updateProfile({
    required String fullName,
    required String email,
  }) async {
    final user = await _userService.updateProfile(
      fullName: fullName,
      email: email,
      currentUser: _currentUser,
    );
    _currentUser = user;
    return user;
  }

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
