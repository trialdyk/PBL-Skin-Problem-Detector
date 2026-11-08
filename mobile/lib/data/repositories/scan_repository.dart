import 'package:flutter/foundation.dart';
import 'package:pbl_skin_problem_detector/data/models/gea_result.dart';
import 'package:pbl_skin_problem_detector/data/models/interview_answers.dart';
import 'package:pbl_skin_problem_detector/data/models/result_source.dart';
import 'package:pbl_skin_problem_detector/data/models/scan_session.dart';
import 'package:pbl_skin_problem_detector/data/services/gea_diagnosis_service.dart';
import 'package:pbl_skin_problem_detector/data/services/ml/ml.dart';

class ScanRepository {
  ScanRepository(this._diagnosisService, {this.mlPredict});

  final GeaDiagnosisService _diagnosisService;

  /// CNN di backend. Null di test lama / saat ML sengaja dimatikan.
  final MlPredictor? mlPredict;

  ScanSession _session = const ScanSession();

  ScanSession get session => _session;

  void setPhoto(SelfieAngle angle, String path) {
    _session = switch (angle) {
      SelfieAngle.front => _session.copyWith(frontPath: path),
      SelfieAngle.left => _session.copyWith(leftPath: path),
      SelfieAngle.right => _session.copyWith(rightPath: path),
    };
  }

  void clearPhotos() {
    _session = _session.copyWith(clearPhotos: true, clearResult: true);
  }

  void setInterview(InterviewAnswers answers) {
    _session = _session.copyWith(interview: answers);
  }

  /// Diagnosa GEA: foto → `POST /ml/predict`, lalu simpan hasil ke sesi.
  Future<GeaResult> diagnose() async {
    final result = await _diagnoseWithFallback();
    _session = _session.copyWith(result: result);
    return result;
  }

  /// CNN dulu; kalau gagal (offline, 4xx/5xx, model mati) pakai rule-based
  /// dari interview supaya pengguna tetap mendapat hasil.
  Future<GeaResult> _diagnoseWithFallback() async {
    final photos = _session.photoPaths;
    final predictor = mlPredict;

    if (predictor != null && photos.isNotEmpty) {
      try {
        final prediction = await predictor(photos);
        return GeaResult.fromGrade(
          prediction.grade,
          source: ResultSource.ml,
        );
      } catch (error) {
        debugPrint('Prediksi ML gagal, memakai rule-based: $error');
      }
    }

    return _diagnosisService.diagnose(_session.interview);
  }

  void reset() {
    _session = const ScanSession();
  }
}
