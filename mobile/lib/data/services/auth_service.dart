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

  http.Client? _http;
  GoogleSignIn? _googleSignIn;

  AuthService({
    http.Client? httpClient,
    GoogleSignIn? googleSignIn,
  })  : _http = httpClient,
        _googleSignIn = googleSignIn;

  http.Client get _client => _http ??= http.Client();

  GoogleSignIn get _google =>
      _googleSignIn ??= GoogleSignIn(
        serverClientId: ApiConfig.googleServerClientId,
        scopes: const ['email', 'profile'],
      );

  /// Email/password → `POST /auth/login` (production by default).
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
      return UserModel(email: email.trim(), accessToken: 'mock-token');
    }

    return _postAuth(
      path: '/auth/login',
      body: {
        'email': email.trim(),
        'password': password,
        'accepted_terms': true,
        'accepted_privacy': true,
      },
      fallbackError: 'Email atau kata sandi salah. Periksa kembali.',
    );
  }

  /// Google Sign-In → `id_token` → `POST /auth/google`.
  Future<UserModel> loginWithGoogle({required bool acceptedTerms}) async {
    if (!acceptedTerms) {
      throw AuthException(
        'Centang Syarat & Ketentuan serta Kebijakan Privasi terlebih dahulu.',
      );
    }

    if (mockRemoteAuth) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      return const UserModel(email: demoEmail, accessToken: 'mock-google-token');
    }

    final account = await _google.signIn();
    if (account == null) {
      throw AuthException('Login Google dibatalkan.');
    }

    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw AuthException('Token Google tidak tersedia. Coba lagi.');
    }

    return _postAuth(
      path: '/auth/google',
      body: {
        'id_token': idToken,
        'accepted_terms': true,
        'accepted_privacy': true,
      },
      fallbackError: 'Login Google gagal. Coba lagi.',
    );
  }

  Future<UserModel> _postAuth({
    required String path,
    required Map<String, Object?> body,
    required String fallbackError,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    late final http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      throw AuthException(
        'Tidak bisa menghubungi server. Cek koneksi internet.',
      );
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return UserModel.fromAuthJson(decoded);
      }
      throw AuthException(fallbackError);
    }

    throw AuthException(_readDetail(response.body) ?? fallbackError);
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
