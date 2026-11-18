import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pbl_skin_problem_detector/data/models/history_item.dart';
import 'package:pbl_skin_problem_detector/data/services/api_client.dart';
import 'package:pbl_skin_problem_detector/data/services/history/history_exception.dart';

class HistoryListResult {
  const HistoryListResult({
    required this.items,
    required this.total,
    required this.limit,
    required this.offset,
  });

  final List<HistoryItem> items;
  final int total;
  final int limit;
  final int offset;
}

/// `GET /history`
class HistoryList {
  HistoryList(this._api);

  final ApiClient _api;

  Future<HistoryListResult> call({int limit = 50, int offset = 0}) async {
    late final http.Response response;
    try {
      response = await _api.get(
        '/history?limit=$limit&offset=$offset',
        auth: true,
      );
    } catch (_) {
      throw HistoryException(
        'Tidak bisa memuat riwayat. Cek koneksi internet.',
      );
    }

    if (response.statusCode == 200) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final rawItems = decoded['items'];
          return HistoryListResult(
            items: [
              if (rawItems is List)
                for (final item in rawItems)
                  if (item is Map<String, dynamic>) HistoryItem.fromJson(item),
            ],
            total: decoded['total'] as int? ?? 0,
            limit: decoded['limit'] as int? ?? limit,
            offset: decoded['offset'] as int? ?? offset,
          );
        }
      } on FormatException {
        throw HistoryException('Respons daftar riwayat tidak dikenali.');
      }
    }

    debugPrint(
      'History API GET /history → HTTP ${response.statusCode}: ${response.body}',
    );
    throw HistoryException(
      _readDetail(response.body) ??
          'Gagal memuat riwayat (${response.statusCode}).',
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
