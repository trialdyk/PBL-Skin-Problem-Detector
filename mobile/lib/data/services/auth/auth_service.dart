import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:pbl_skin_problem_detector/data/models/register_pending.dart';
import 'package:pbl_skin_problem_detector/data/models/user_model.dart';
import 'package:pbl_skin_problem_detector/data/services/api_client.dart';
import 'package:pbl_skin_problem_detector/data/services/auth/auth_exception.dart';
import 'package:pbl_skin_problem_detector/data/services/auth/auth_google.dart';
import 'package:pbl_skin_problem_detector/data/services/auth/auth_login.dart';
import 'package:pbl_skin_problem_detector/data/services/auth/auth_register.dart';
import 'package:pbl_skin_problem_detector/data/services/auth/auth_resend_verification.dart';
import 'package:pbl_skin_problem_detector/data/services/auth/auth_verify_email.dart';

/// Facade for auth endpoints.
class AuthService {
  /// Akun demo lokal (hanya dipakai saat [mockRemoteAuth] = true di widget test).
  static const String demoEmail = 'pengguna@gmail.com';
  static const String demoPassword = 'skinscan123';
  static String _activeDemoPassword = demoPassword;

  @visibleForTesting
  static void resetDemoPassword() {
    _activeDemoPassword = demoPassword;
  }

  /// Widget tests: skip Google SDK + HTTP ke backend.
  @visibleForTesting
  static bool mockRemoteAuth = false;

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
    _verifyEmail = AuthVerifyEmail(api);
    _resend = AuthResendVerification(api);
    _google = AuthGoogle(api, googleSignIn: googleSignIn);
  }

  final ApiClient api;
  late final AuthLogin _login;
  late final AuthRegister _register;
  late final AuthVerifyEmail _verifyEmail;
  late final AuthResendVerification _resend;
  late final AuthGoogle _google;

  void setAccessToken(String? token) {
    api.accessToken = token;
  }

  void clearAccessToken() {
    api.accessToken = null;
  }

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

  /// `POST /auth/register` — returns pending OTP info (no JWT).
  Future<RegisterPending> register({
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
      return RegisterPending(
        email: email.trim().toLowerCase(),
        message: 'Kode verifikasi telah dikirim ke email Anda.',
        expiresIn: 900,
      );
    }

    return _register(
      email: email,
      password: password,
      fullName: fullName,
    );
  }

  Future<UserModel> verifyEmail({
    required String email,
    required String code,
  }) async {
    if (mockRemoteAuth) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      final user = UserModel(
        email: email.trim().toLowerCase(),
        accessToken: 'mock-token',
      );
      setAccessToken(user.accessToken);
      return user;
    }

    final user = await _verifyEmail(email: email, code: code);
    setAccessToken(user.accessToken);
    return user;
  }

  Future<RegisterPending> resendVerification({required String email}) async {
    if (mockRemoteAuth) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      return RegisterPending(
        email: email.trim().toLowerCase(),
        message: 'Jika email terdaftar dan belum diverifikasi, kode baru telah dikirim.',
        expiresIn: 900,
      );
    }
    return _resend(email: email);
  }

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

  /// Memverifikasi kata sandi saat ini dan memperbarui kata sandi.
  Future<bool> changePassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    if (mockRemoteAuth) {
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (!_credentialsMatch(email, currentPassword)) {
        throw AuthException('Kata sandi saat ini salah.');
      }
      _activeDemoPassword = newPassword;
      return true;
    }

    try {
      final user = await _login(email: email, password: currentPassword);
      setAccessToken(user.accessToken);
      return true;
    } on AuthException catch (e) {
      if (e.statusCode == 401 ||
          e.statusCode == 400 ||
          e.message.toLowerCase().contains('sandi')) {
        throw AuthException('Kata sandi saat ini salah.');
      }
      rethrow;
    }
  }

  bool _credentialsMatch(String email, String password) {
    return email.trim().toLowerCase() == demoEmail &&
        password == _activeDemoPassword;
  }
}
