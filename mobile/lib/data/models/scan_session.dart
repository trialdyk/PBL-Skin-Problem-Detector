import 'package:equatable/equatable.dart';
import 'package:pbl_skin_problem_detector/data/models/gea_result.dart';
import 'package:pbl_skin_problem_detector/data/models/history_item.dart';
import 'package:pbl_skin_problem_detector/data/models/interview_answers.dart';

enum SelfieAngle { front, left, right }

class ScanSession extends Equatable {
  const ScanSession({
    this.frontPath,
    this.leftPath,
    this.rightPath,
    this.interview = const InterviewAnswers(),
    this.result,
    this.historyId,
    this.recommendation,
  });

  final String? frontPath;
  final String? leftPath;
  final String? rightPath;
  final InterviewAnswers interview;
  final GeaResult? result;
  final String? historyId;
  final HistoryRecommendation? recommendation;

  bool get hasAllPhotos =>
      frontPath != null && leftPath != null && rightPath != null;

  /// Foto yang sudah diambil, urut depan → kiri → kanan.
  ///
  /// `POST /ml/predict` menerima 1–3 berkas, jadi daftar ini bisa lebih pendek
  /// dari tiga bila pengguna baru mengambil sebagian.
  List<String> get photoPaths => [?frontPath, ?leftPath, ?rightPath];

  String? pathFor(SelfieAngle angle) {
    return switch (angle) {
      SelfieAngle.front => frontPath,
      SelfieAngle.left => leftPath,
      SelfieAngle.right => rightPath,
    };
  }

  ScanSession copyWith({
    String? frontPath,
    String? leftPath,
    String? rightPath,
    InterviewAnswers? interview,
    GeaResult? result,
    String? historyId,
    HistoryRecommendation? recommendation,
    bool clearPhotos = false,
    bool clearResult = false,
    bool clearHistory = false,
  }) {
    return ScanSession(
      frontPath: clearPhotos ? null : (frontPath ?? this.frontPath),
      leftPath: clearPhotos ? null : (leftPath ?? this.leftPath),
      rightPath: clearPhotos ? null : (rightPath ?? this.rightPath),
      interview: interview ?? this.interview,
      result: clearResult ? null : (result ?? this.result),
      historyId: clearHistory ? null : (historyId ?? this.historyId),
      recommendation:
          clearHistory ? null : (recommendation ?? this.recommendation),
    );
  }

  @override
  List<Object?> get props => [
        frontPath,
        leftPath,
        rightPath,
        interview,
        result,
        historyId,
        recommendation,
      ];
}
