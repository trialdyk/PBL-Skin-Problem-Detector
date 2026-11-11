import 'package:flutter_test/flutter_test.dart';
import 'package:pbl_skin_problem_detector/data/models/result_source.dart';
import 'package:pbl_skin_problem_detector/data/models/scan_session.dart';
import 'package:pbl_skin_problem_detector/data/repositories/scan_repository.dart';
import 'package:pbl_skin_problem_detector/data/services/gea_diagnosis_service.dart';
import 'package:pbl_skin_problem_detector/data/services/ml/ml.dart';

/// Pengganti CNN: mengembalikan grade tetap atau melempar error.
class _FakeMlPredictor implements MlPredictor {
  _FakeMlPredictor({this.grade = 3, this.error});

  final int grade;
  final Object? error;

  /// Foto yang diterima pada panggilan terakhir (`null` = tidak dipanggil).
  List<String>? received;

  @override
  Future<MlPrediction> call(List<String> photoPaths) async {
    received = photoPaths;
    final failure = error;
    if (failure != null) throw failure;
    return MlPrediction(grade: grade, topLabel: 'IGA$grade', model: 'fake');
  }
}

ScanRepository _repositoryWithPhotos({MlPredictor? mlPredict}) {
  final repository = ScanRepository(
    GeaDiagnosisService(),
    mlPredict: mlPredict,
  );
  repository.setPhoto(SelfieAngle.front, '/tmp/front.jpg');
  repository.setPhoto(SelfieAngle.left, '/tmp/left.jpg');
  repository.setPhoto(SelfieAngle.right, '/tmp/right.jpg');
  return repository;
}

void main() {
  test('memakai grade dari CNN saat prediksi berhasil', () async {
    final predictor = _FakeMlPredictor(grade: 3);
    final repository = _repositoryWithPhotos(mlPredict: predictor);

    final result = await repository.diagnose();

    expect(result.grade, 3);
    expect(result.source, ResultSource.ml);
    expect(result.labelId, 'Sedang');
    expect(predictor.received, hasLength(3));
    expect(repository.session.result?.source, ResultSource.ml);
  });

  test('fallback rule-based saat ML gagal', () async {
    final predictor = _FakeMlPredictor(error: MlException('offline'));
    final repository = _repositoryWithPhotos(mlPredict: predictor);

    final result = await repository.diagnose();

    expect(result.source, ResultSource.ruleBased);
    expect(result.grade, inInclusiveRange(0, 5));
    expect(predictor.received, hasLength(3));
  });

  test('tanpa foto langsung rule-based, ML tidak dipanggil', () async {
    final predictor = _FakeMlPredictor();
    final repository = ScanRepository(
      GeaDiagnosisService(),
      mlPredict: predictor,
    );

    final result = await repository.diagnose();

    expect(result.source, ResultSource.ruleBased);
    expect(predictor.received, isNull);
  });

  test('tanpa layanan ML tetap rule-based', () async {
    final repository = _repositoryWithPhotos();

    final result = await repository.diagnose();

    expect(result.source, ResultSource.ruleBased);
  });

  test('photoPaths hanya berisi foto yang sudah diambil', () {
    final repository = ScanRepository(GeaDiagnosisService());
    repository.setPhoto(SelfieAngle.front, '/tmp/front.jpg');
    repository.setPhoto(SelfieAngle.left, '/tmp/left.jpg');

    expect(repository.session.photoPaths, ['/tmp/front.jpg', '/tmp/left.jpg']);
  });

  test('clearPhotos dan reset mengosongkan sesi', () async {
    final repository = _repositoryWithPhotos(mlPredict: _FakeMlPredictor());
    await repository.diagnose();

    repository.clearPhotos();

    expect(repository.session.photoPaths, isEmpty);
    expect(repository.session.result, isNull);

    repository.setPhoto(SelfieAngle.front, '/tmp/front.jpg');
    repository.reset();

    expect(repository.session.photoPaths, isEmpty);
  });
}