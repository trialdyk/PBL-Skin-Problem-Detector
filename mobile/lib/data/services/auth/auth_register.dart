import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pbl_skin_problem_detector/data/models/user_model.dart';
import 'package:pbl_skin_problem_detector/data/services/api_client.dart';
import 'package:pbl_skin_problem_detector/data/services/auth/auth_exception.dart';

/// `POST /auth/register` — public (no Bearer). Returns same shape as login.
class AuthRegister {
  AuthRegister(this._api);

  final ApiClient _api;

  Future<UserModel> call({
    required String email,
    required String password,
    String? fullName,
  }) async {
    late final http.Response response;
    try {
      response = await _api.post(
        '/auth/register',
        body: {
          'email': email.trim(),
          'password': password,
          if (fullName != null && fullName.trim().isNotEmpty)
            'full_name': fullName.trim(),
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
      'Auth API /auth/register → HTTP ${response.statusCode}: ${response.body}',
    );
    throw AuthException(
      _readDetail(response.body) ?? 'Registrasi gagal. Coba lagi.',
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
