import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pbl_skin_problem_detector/data/models/history_item.dart';
import 'package:pbl_skin_problem_detector/data/services/api_client.dart';
import 'package:pbl_skin_problem_detector/data/services/history/history_exception.dart';

/// `GET /history/{id}`
class HistoryDetail {
  HistoryDetail(this._api);

  final ApiClient _api;

  Future<HistoryItem> call(String id) async {
    late final http.Response response;
    try {
      response = await _api.get('/history/$id', auth: true);
    } catch (_) {
      throw HistoryException(
        'Tidak bisa memuat detail riwayat. Cek koneksi internet.',
      );
    }

    if (response.statusCode == 200) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return HistoryItem.fromJson(decoded);
        }
      } on FormatException {
        throw HistoryException('Respons detail riwayat tidak dikenali.');
      }
    }

    debugPrint(
      'History API GET /history/$id → HTTP ${response.statusCode}: ${response.body}',
    );
    throw HistoryException(
      _readDetail(response.body) ??
          'Gagal memuat detail (${response.statusCode}).',
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
