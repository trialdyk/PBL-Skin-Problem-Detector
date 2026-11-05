import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:pbl_skin_problem_detector/core/api_config.dart';
import 'package:pbl_skin_problem_detector/data/models/user_model.dart';

class AuthException implements Exception {
  AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

class AuthService {
  /// Akun demo prototipe (email/password lokal). Selain kombinasi ini login ditolak.
  static const String demoEmail = 'pengguna@gmail.com';
  static const String demoPassword = 'skinscan123';

  /// Widget tests set this so Google SDK + network are skipped.
  @visibleForTesting
  static bool mockGoogleSignIn = false;

  final http.Client _http;
  final GoogleSignIn _googleSignIn;

  AuthService({
    http.Client? httpClient,
    GoogleSignIn? googleSignIn,
  })  : _http = httpClient ?? http.Client(),
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              serverClientId: ApiConfig.googleServerClientId,
              scopes: const ['email', 'profile'],
            );

  /// [viaGoogle] menandai jalur mock lama (tes / fallback). Prefer
  /// [loginWithGoogle] untuk OAuth sungguhan.
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

    if (!viaGoogle && !_credentialsMatch(email, password)) {
      throw AuthException('Email atau kata sandi salah. Periksa kembali.');
    }

    return UserModel(email: email.trim());
  }

  /// Google Sign-In → `id_token` → `POST /auth/google` → JWT DermaScan.
  Future<UserModel> loginWithGoogle({required bool acceptedTerms}) async {
    if (!acceptedTerms) {
      throw AuthException(
        'Centang Syarat & Ketentuan serta Kebijakan Privasi terlebih dahulu.',
      );
    }

    if (mockGoogleSignIn) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      return const UserModel(email: demoEmail, accessToken: 'mock-google-token');
    }

    final account = await _googleSignIn.signIn();
    if (account == null) {
      throw AuthException('Login Google dibatalkan.');
    }

    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw AuthException('Token Google tidak tersedia. Coba lagi.');
    }

    return _exchangeGoogleIdToken(idToken);
  }

  Future<UserModel> _exchangeGoogleIdToken(String idToken) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/auth/google');
    late final http.Response response;
    try {
      response = await _http
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'id_token': idToken,
              'accepted_terms': true,
              'accepted_privacy': true,
            }),
          )
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      throw AuthException(
        'Tidak bisa menghubungi server. Pastikan backend berjalan.',
      );
    }

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return UserModel.fromAuthJson(body);
    }

    final detail = _readDetail(response.body);
    if (response.statusCode == 400 || response.statusCode == 401) {
      throw AuthException(detail ?? 'Login Google gagal. Coba lagi.');
    }
    throw AuthException(detail ?? 'Login Google gagal. Coba lagi.');
  }

  String? _readDetail(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic> && decoded['detail'] is String) {
        return decoded['detail'] as String;
      }
    } catch (_) {}
    return null;
  }

  bool _credentialsMatch(String email, String password) {
    return email.trim().toLowerCase() == demoEmail && password == demoPassword;
  }
}
