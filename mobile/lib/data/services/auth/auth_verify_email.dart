import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pbl_skin_problem_detector/data/models/user_model.dart';
import 'package:pbl_skin_problem_detector/data/services/api_client.dart';
import 'package:pbl_skin_problem_detector/data/services/auth/auth_exception.dart';

/// `POST /auth/verify-email` — public. Returns JWT like login.
class AuthVerifyEmail {
  AuthVerifyEmail(this._api);

  final ApiClient _api;

  Future<UserModel> call({
    required String email,
    required String code,
  }) async {
    late final http.Response response;
    try {
      response = await _api.post(
        '/auth/verify-email',
        body: {
          'email': email.trim().toLowerCase(),
          'code': code.trim(),
        },
      );
    } catch (_) {
      throw AuthException(
        'Tidak bisa menghubungi server. Cek koneksi internet.',
      );
    }

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return UserModel.fromAuthJson(decoded);
      }
    }

    debugPrint(
      'Auth API /auth/verify-email → HTTP ${response.statusCode}: ${response.body}',
    );
    throw AuthException(
      _readDetail(response.body) ?? 'Kode verifikasi salah. Coba lagi.',
      statusCode: response.statusCode,
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
