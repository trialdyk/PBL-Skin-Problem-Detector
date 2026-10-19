import 'package:pbl_skin_problem_detector/data/models/gea_result.dart';
import 'package:pbl_skin_problem_detector/data/models/interview_answers.dart';
import 'package:pbl_skin_problem_detector/data/models/scan_session.dart';
import 'package:pbl_skin_problem_detector/data/services/gea_diagnosis_service.dart';

class ScanRepository {
  ScanRepository(this._diagnosisService);

  final GeaDiagnosisService _diagnosisService;
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

  Future<GeaResult> diagnose() async {
    final result = await _diagnosisService.diagnose(_session.interview);
    _session = _session.copyWith(result: result);
    return result;
  }

  void reset() {
    _session = const ScanSession();
  }
}
