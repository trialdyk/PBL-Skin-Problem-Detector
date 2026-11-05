import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:pbl_skin_problem_detector/core/api_config.dart';
import 'package:pbl_skin_problem_detector/data/models/user_model.dart';
import 'package:pbl_skin_problem_detector/data/services/api_client.dart';
import 'package:pbl_skin_problem_detector/data/services/auth/auth_exception.dart';

/// Google Sign-In → `id_token` → `POST /auth/google` — public (no Bearer).
class AuthGoogle {
  AuthGoogle(this._api, {GoogleSignIn? this._googleSignIn});

  final ApiClient _api;
  GoogleSignIn? _googleSignIn;

  GoogleSignIn get _google =>
      _googleSignIn ??= GoogleSignIn(
        serverClientId: ApiConfig.googleServerClientId,
        scopes: const ['email', 'profile'],
      );

  Future<UserModel> call() async {
    final account = await _google.signIn();
    if (account == null) {
      throw AuthException('Login Google dibatalkan.');
    }

    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw AuthException('Token Google tidak tersedia. Coba lagi.');
    }

    late final http.Response response;
    try {
      response = await _api.post(
        '/auth/google',
        body: {
          'id_token': idToken,
          'accepted_terms': true,
          'accepted_privacy': true,
        },
      );
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
    }

    debugPrint(
      'Auth API /auth/google → HTTP ${response.statusCode}: ${response.body}',
    );
    throw AuthException(
      _readDetail(response.body) ?? 'Login Google gagal. Coba lagi.',
    );
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
}
