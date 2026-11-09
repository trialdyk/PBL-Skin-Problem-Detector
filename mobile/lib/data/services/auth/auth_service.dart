import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:pbl_skin_problem_detector/data/models/user_model.dart';
import 'package:pbl_skin_problem_detector/data/services/api_client.dart';
import 'package:pbl_skin_problem_detector/data/services/auth/auth_exception.dart';
import 'package:pbl_skin_problem_detector/data/services/auth/auth_google.dart';
import 'package:pbl_skin_problem_detector/data/services/auth/auth_login.dart';
import 'package:pbl_skin_problem_detector/data/services/auth/auth_register.dart';

/// Facade for auth endpoints. Prefer calling [login] / [register] / [loginWithGoogle];
/// underlying files live next to this one (`auth_login.dart`, …).
class AuthService {
  /// Akun demo lokal (hanya dipakai saat [mockRemoteAuth] = true di widget test).
  static const String demoEmail = 'pengguna@gmail.com';
  static const String demoPassword = 'skinscan123';

  /// Widget tests: skip Google SDK + HTTP ke backend.
  @visibleForTesting
  static bool mockRemoteAuth = false;

  /// Alias lama untuk kompatibilitas test.
  @visibleForTesting
  static bool get mockGoogleSignIn => mockRemoteAuth;
  @visibleForTesting
  static set mockGoogleSignIn(bool value) => mockRemoteAuth = value;

  AuthService({
    ApiClient? apiClient,
    http.Client? httpClient,
    GoogleSignIn? googleSignIn,
  }) : api = apiClient ?? ApiClient(httpClient: httpClient) {
    _login = AuthLogin(api);
    _register = AuthRegister(api);
    _google = AuthGoogle(api, googleSignIn: googleSignIn);
  }

  final ApiClient api;
  late final AuthLogin _login;
  late final AuthRegister _register;
  late final AuthGoogle _google;

  /// Simpan JWT setelah login supaya call protected (`auth: true`) otomatis.
  void setAccessToken(String? token) {
    api.accessToken = token;
  }

  void clearAccessToken() {
    api.accessToken = null;
  }

  /// Email/password → `POST /auth/login` (public).
  Future<UserModel> login({
    required String email,
    required String password,
    required bool acceptedTerms,
    bool viaGoogle = false,
  }) async {
    if (!acceptedTerms) {
      throw AuthException(
        'Centang Syarat & Ketentuan serta Kebijakan Privasi terlebih dahulu.',
      );
    }

    if (mockRemoteAuth || viaGoogle) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!viaGoogle && !_credentialsMatch(email, password)) {
        throw AuthException('Email atau kata sandi salah. Periksa kembali.');
      }
      final user = UserModel(email: email.trim(), accessToken: 'mock-token');
      setAccessToken(user.accessToken);
      return user;
    }

    final user = await _login(email: email, password: password);
    setAccessToken(user.accessToken);
    return user;
  }

  /// `POST /auth/register` (public).
  Future<UserModel> register({
    required String email,
    required String password,
    required bool acceptedTerms,
    String? fullName,
  }) async {
    if (!acceptedTerms) {
      throw AuthException(
        'Centang Syarat & Ketentuan serta Kebijakan Privasi terlebih dahulu.',
      );
    }

    if (mockRemoteAuth) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      final user = UserModel(
        email: email.trim(),
        fullName: fullName,
        accessToken: 'mock-token',
      );
      setAccessToken(user.accessToken);
      return user;
    }

    final user = await _register(
      email: email,
      password: password,
      fullName: fullName,
    );
    setAccessToken(user.accessToken);
    return user;
  }

  /// Google Sign-In → `POST /auth/google` (public).
  Future<UserModel> loginWithGoogle({required bool acceptedTerms}) async {
    if (!acceptedTerms) {
      throw AuthException(
        'Centang Syarat & Ketentuan serta Kebijakan Privasi terlebih dahulu.',
      );
    }

    if (mockRemoteAuth) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      const user = UserModel(email: demoEmail, accessToken: 'mock-google-token');
      setAccessToken(user.accessToken);
      return user;
    }

    final user = await _google();
    setAccessToken(user.accessToken);
    return user;
  }

  bool _credentialsMatch(String email, String password) {
    return email.trim().toLowerCase() == demoEmail && password == demoPassword;
  }
}
