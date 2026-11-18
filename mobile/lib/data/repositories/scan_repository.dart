import 'package:flutter/foundation.dart';
import 'package:pbl_skin_problem_detector/data/models/gea_result.dart';
import 'package:pbl_skin_problem_detector/data/models/history_item.dart';
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

  bool get hasHistoryService => historyService != null;

  void setPhoto(SelfieAngle angle, String path) {
    _session = switch (angle) {
      SelfieAngle.front => _session.copyWith(frontPath: path),
      SelfieAngle.left => _session.copyWith(leftPath: path),
      SelfieAngle.right => _session.copyWith(rightPath: path),
    };
  }

  void clearPhotos() {
    _session = _session.copyWith(
      clearPhotos: true,
      clearResult: true,
      clearHistory: true,
    );
  }

  void setInterview(InterviewAnswers answers) {
    _session = _session.copyWith(interview: answers);
  }

  /// Diagnosa GEA: foto → `POST /ml/predict`, lalu simpan hasil ke sesi.
  Future<GeaResult> diagnose() async {
    final result = await _diagnoseWithFallback();
    _session = _session.copyWith(result: result, clearHistory: true);
    return result;
  }

  /// Simpan sesi selesai ke server (foto + grade + interview) lalu simpan
  /// `historyId` dan slot `recommendation` awal ke sesi.
  Future<HistoryItem?> persistHistory() async {
    final history = historyService;
    final result = _session.result;
    final front = _session.frontPath;
    final left = _session.leftPath;
    final right = _session.rightPath;
    if (history == null || result == null) return null;
    if (front == null || left == null || right == null) return null;

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

    final created = await history.create(
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
    _session = _session.copyWith(
      historyId: created.id,
      recommendation: created.recommendation,
    );
    return created;
  }

  /// Ambil status/teks rekomendasi terbaru dari `GET /history/{id}`.
  Future<HistoryRecommendation?> refreshRecommendation(String historyId) async {
    final history = historyService;
    if (history == null) return null;
    final detail = await history.detail(historyId);
    _session = _session.copyWith(
      historyId: detail.id,
      recommendation: detail.recommendation,
    );
    return detail.recommendation;
  }

  /// Minta ulang generasi rekomendasi LLM lewat `POST /history/{id}/recommendation/retry`.
  Future<HistoryRecommendation?> retryRecommendation(String historyId) async {
    final history = historyService;
    if (history == null) return null;
    final updated = await history.retryRecommendation(historyId);
    _session = _session.copyWith(
      historyId: updated.id,
      recommendation: updated.recommendation,
    );
    return updated.recommendation;
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
