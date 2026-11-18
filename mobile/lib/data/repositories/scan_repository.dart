import 'package:flutter/foundation.dart';
import 'package:pbl_skin_problem_detector/data/models/gea_result.dart';
import 'package:pbl_skin_problem_detector/data/models/interview_answers.dart';
import 'package:pbl_skin_problem_detector/data/models/result_source.dart';
import 'package:pbl_skin_problem_detector/data/models/scan_session.dart';
import 'package:pbl_skin_problem_detector/data/services/gea_diagnosis_service.dart';
import 'package:pbl_skin_problem_detector/data/services/history/history.dart';
import 'package:pbl_skin_problem_detector/data/services/ml/ml.dart';

class ScanRepository {
  ScanRepository(
    this._diagnosisService, {
    this.mlPredict,
    this.historyService,
  });

  final GeaDiagnosisService _diagnosisService;

  /// CNN di backend. Null di test lama / saat ML sengaja dimatikan.
  final MlPredictor? mlPredict;

  /// Persist one-shot ke `POST /history`. Null = skip (tests).
  final HistoryService? historyService;

  ScanSession _session = const ScanSession();

  String? _lastModelId;
  String? _lastTopLabel;
  List<double> _lastProbabilities = const [];

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

  /// Simpan sesi selesai ke server (foto + grade + interview).
  ///
  /// Tidak melempar ke UI flow — caller boleh tangkap error untuk toast.
  Future<void> persistHistory() async {
    final history = historyService;
    final result = _session.result;
    final front = _session.frontPath;
    final left = _session.leftPath;
    final right = _session.rightPath;
    if (history == null || result == null) return;
    if (front == null || left == null || right == null) return;

    final source = result.source == ResultSource.ml ? 'ml' : 'rule_based';
    final modelId = result.source == ResultSource.ml
        ? (_lastModelId ?? 'dermascan-custom-cnn-v1')
        : 'rule-based';

    Map<String, Object?>? aggregate;
    if (_lastProbabilities.isNotEmpty) {
      aggregate = {
        'grade': result.grade,
        'top_label': _lastTopLabel,
        'predictions': _lastProbabilities,
      };
    }

    await history.create(
      frontPath: front,
      leftPath: left,
      rightPath: right,
      grade: result.grade,
      gradeLabel: result.labelId,
      modelId: modelId,
      resultSource: source,
      interview: _session.interview.toApiJson(),
      topLabel: _lastTopLabel,
      aggregate: aggregate,
    );
  }

  /// CNN dulu; kalau gagal (offline, 4xx/5xx, model mati) pakai rule-based
  /// dari interview supaya pengguna tetap mendapat hasil.
  Future<GeaResult> _diagnoseWithFallback() async {
    final photos = _session.photoPaths;
    final predictor = mlPredict;

    _lastModelId = null;
    _lastTopLabel = null;
    _lastProbabilities = const [];

    if (predictor != null && photos.isNotEmpty) {
      try {
        final prediction = await predictor(photos);
        _lastModelId = prediction.model;
        _lastTopLabel = prediction.topLabel;
        _lastProbabilities = prediction.probabilities;
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
    _lastModelId = null;
    _lastTopLabel = null;
    _lastProbabilities = const [];
  }
}
