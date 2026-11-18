import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pbl_skin_problem_detector/data/services/api_client.dart';
import 'package:pbl_skin_problem_detector/data/services/history/history_exception.dart';

/// `DELETE /history/{id}`
class HistoryDelete {
  HistoryDelete(this._api);

  final ApiClient _api;

  Future<void> call(String id) async {
    late final http.Response response;
    try {
      response = await _api.delete('/history/$id', auth: true);
    } catch (_) {
      throw HistoryException(
        'Tidak bisa menghapus riwayat. Cek koneksi internet.',
      );
    }

    if (response.statusCode == 200) return;

    debugPrint(
      'History API DELETE /history/$id → HTTP ${response.statusCode}: ${response.body}',
    );
    throw HistoryException(
      _readDetail(response.body) ??
          'Gagal menghapus riwayat (${response.statusCode}).',
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
