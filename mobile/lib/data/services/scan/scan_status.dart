import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:pbl_skin_problem_detector/data/services/api_client.dart';
import 'package:pbl_skin_problem_detector/data/services/auth/auth_exception.dart';

/// Contoh endpoint **protected**: `GET /users/status`
/// (butuh `Authorization: Bearer <access_token>`).
class ScanStatus {
  ScanStatus(this._api);

  final ApiClient _api;

  /// Returns server status map when authorized.
  Future<Map<String, dynamic>> call() async {
    late final http.Response response;
    try {
      response = await _api.get('/users/status', auth: true);
    } catch (_) {
      throw AuthException(
        'Tidak bisa menghubungi server. Cek koneksi internet.',
      );
    }

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
    }

    if (response.statusCode == 401) {
      throw AuthException('Sesi habis. Silakan login ulang.');
    }

    throw AuthException('Gagal memuat status (${response.statusCode}).');
  }
}
