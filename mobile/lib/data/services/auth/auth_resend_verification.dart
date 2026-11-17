import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pbl_skin_problem_detector/data/models/register_pending.dart';
import 'package:pbl_skin_problem_detector/data/services/api_client.dart';
import 'package:pbl_skin_problem_detector/data/services/auth/auth_exception.dart';

/// `POST /auth/resend-verification` — public.
class AuthResendVerification {
  AuthResendVerification(this._api);

  final ApiClient _api;

  Future<RegisterPending> call({required String email}) async {
    late final http.Response response;
    try {
      response = await _api.post(
        '/auth/resend-verification',
        body: {'email': email.trim().toLowerCase()},
      );
    } catch (_) {
      throw AuthException(
        'Tidak bisa menghubungi server. Cek koneksi internet.',
      );
    }

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return RegisterPending.fromJson(decoded);
      }
    }

    debugPrint(
      'Auth API /auth/resend-verification → HTTP ${response.statusCode}: ${response.body}',
    );
    throw AuthException(
      _readDetail(response.body) ?? 'Gagal mengirim ulang kode. Coba lagi.',
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
