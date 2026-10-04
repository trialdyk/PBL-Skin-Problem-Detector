import 'package:equatable/equatable.dart';
import 'package:pbl_skin_problem_detector/data/models/gea_result.dart';
import 'package:pbl_skin_problem_detector/data/models/interview_answers.dart';

enum SelfieAngle { front, left, right }

class ScanSession extends Equatable {
  const ScanSession({
    this.frontPath,
    this.leftPath,
    this.rightPath,
    this.interview = const InterviewAnswers(),
    this.result,
  });

  final String? frontPath;
  final String? leftPath;
  final String? rightPath;
  final InterviewAnswers interview;
  final GeaResult? result;

  bool get hasAllPhotos =>
      frontPath != null && leftPath != null && rightPath != null;

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
    bool clearPhotos = false,
    bool clearResult = false,
  }) {
    return ScanSession(
      frontPath: clearPhotos ? null : (frontPath ?? this.frontPath),
      leftPath: clearPhotos ? null : (leftPath ?? this.leftPath),
      rightPath: clearPhotos ? null : (rightPath ?? this.rightPath),
      interview: interview ?? this.interview,
      result: clearResult ? null : (result ?? this.result),
    );
  }

  @override
  List<Object?> get props =>
      [frontPath, leftPath, rightPath, interview, result];
}
