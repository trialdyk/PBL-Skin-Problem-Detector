import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pbl_skin_problem_detector/data/models/user_model.dart';
import 'package:pbl_skin_problem_detector/data/services/user/user_exception.dart';

/// Shared parser for `GET /users/me` and `PATCH /users/me` (`UserProfileResponse`).
UserModel parseUserProfileResponse(
  http.Response response, {
  required String endpoint,
  required String fallbackError,
  String? accessToken,
}) {
  if (response.statusCode == 200) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return UserModel.fromProfileJson(decoded, accessToken: accessToken);
      }
    } on FormatException {
      throw UserException('Respons profil tidak dikenali.');
    }
    throw UserException('Respons profil tidak dikenali.');
  }

  if (response.statusCode >= 500) {
    debugPrint('$endpoint → HTTP ${response.statusCode}');
    throw UserException(
      'Terjadi kesalahan pada server. Coba lagi nanti.',
      statusCode: response.statusCode,
    );
  }

  debugPrint('$endpoint → HTTP ${response.statusCode}: ${response.body}');

  if (response.statusCode == 401) {
    throw UserException(
      _readDetail(response.body) ??
          'Sesi tidak valid atau sudah berakhir. Silakan masuk kembali.',
      statusCode: 401,
    );
  }

  if (response.statusCode == 422) {
    throw UserException(
      'Periksa kembali nama dan email yang dimasukkan.',
      statusCode: 422,
    );
  }

  throw UserException(
    _readDetail(response.body) ?? fallbackError,
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
