import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pbl_skin_problem_detector/data/services/api_client.dart';
import 'package:pbl_skin_problem_detector/data/services/ml/ml_exception.dart';
import 'package:pbl_skin_problem_detector/data/services/ml/ml_prediction.dart';

/// Kontrak prediksi, supaya repository bisa diuji dengan fake tanpa HTTP.
abstract interface class MlPredictor {
  Future<MlPrediction> call(List<String> photoPaths);
}

/// `POST /ml/predict` — protected (butuh `Authorization: Bearer <jwt>`).
///
/// ```dart
/// final ml = MlPredict(auth.api); // ApiClient yang sama dengan AuthService
/// final prediction = await ml(['/path/front.jpg', '/path/left.jpg']);
/// ```
class MlPredict implements MlPredictor {
  MlPredict(this._api);

  /// Nama field multipart yang diharapkan backend (`files: list[UploadFile]`).
  static const String fileField = 'files';

  final ApiClient _api;

  @override
  Future<MlPrediction> call(List<String> photoPaths) async {
    if (photoPaths.isEmpty) {
      throw MlException('Belum ada foto untuk dianalisis.');
    }

    late final http.Response response;
    try {
      response = await _api.postMultipart(
        '/ml/predict',
        files: {fileField: photoPaths},
        auth: true,
      );
    } catch (_) {
      throw MlException(
        'Tidak bisa menghubungi server. Cek koneksi internet.',
      );
    }

    if (response.statusCode == 200) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return MlPrediction.fromJson(decoded);
        }
      } on FormatException {
        throw MlException('Respons analisis tidak dikenali.');
      }
    }

    debugPrint(
      'ML API /ml/predict → HTTP ${response.statusCode}: ${response.body}',
    );
    throw MlException(
      _readDetail(response.body) ??
          'Gagal menganalisis foto (${response.statusCode}).',
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