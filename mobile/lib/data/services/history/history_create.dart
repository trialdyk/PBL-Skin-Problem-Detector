import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pbl_skin_problem_detector/data/models/history_item.dart';
import 'package:pbl_skin_problem_detector/data/services/api_client.dart';
import 'package:pbl_skin_problem_detector/data/services/history/history_exception.dart';

/// `POST /history` — one-shot simpan foto + grade + interview.
class HistoryCreate {
  HistoryCreate(this._api);

  final ApiClient _api;

  Future<HistoryItem> call({
    required String frontPath,
    required String leftPath,
    required String rightPath,
    required int grade,
    required String gradeLabel,
    required String modelId,
    required String resultSource,
    required Map<String, Object?> interview,
    String? topLabel,
    Map<String, Object?>? aggregate,
  }) async {
    late final http.Response response;
    try {
      response = await _api.postMultipart(
        '/history',
        files: {
          'front': [frontPath],
          'left': [leftPath],
          'right': [rightPath],
        },
        fields: {
          'grade': '$grade',
          'grade_label': gradeLabel,
          'model_id': modelId,
          'result_source': resultSource,
          'interview': jsonEncode(interview),
          if (topLabel != null && topLabel.isNotEmpty) 'top_label': topLabel,
          if (aggregate != null) 'aggregate': jsonEncode(aggregate),
        },
        auth: true,
      );
    } catch (_) {
      throw HistoryException(
        'Tidak bisa menyimpan riwayat. Cek koneksi internet.',
      );
    }

    if (response.statusCode == 201) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return HistoryItem.fromJson(decoded);
        }
      } on FormatException {
        throw HistoryException('Respons riwayat tidak dikenali.');
      }
    }

    debugPrint(
      'History API POST /history → HTTP ${response.statusCode}: ${response.body}',
    );
    throw HistoryException(
      _readDetail(response.body) ??
          'Gagal menyimpan riwayat (${response.statusCode}).',
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
