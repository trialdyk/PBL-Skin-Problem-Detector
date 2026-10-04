import 'package:pbl_skin_problem_detector/data/models/user_model.dart';
import 'package:pbl_skin_problem_detector/data/services/auth_service.dart';

class AuthRepository {
  AuthRepository(this._service);

  final AuthService _service;
  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  Future<UserModel> login({
    required String email,
    required String password,
    required bool acceptedTerms,
  }) async {
    final user = await _service.login(
      email: email,
      password: password,
      acceptedTerms: acceptedTerms,
    );
    _currentUser = user;
    return user;
  }

  void logout() {
    _currentUser = null;
  }
}
