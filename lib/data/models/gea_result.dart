import 'package:equatable/equatable.dart';
import 'package:pbl_skin_problem_detector/data/models/gea_scale.dart';

class GeaResult extends Equatable {
  const GeaResult({
    required this.grade,
    required this.labelId,
    required this.labelEn,
    required this.description,
  });

  factory GeaResult.fromGrade(int grade) {
    final info = GeaScale.byGrade(grade);
    return GeaResult(
      grade: info.grade,
      labelId: info.labelId,
      labelEn: info.labelEn,
      description: info.description,
    );
  }

  final int grade;
  final String labelId;
  final String labelEn;
  final String description;

  String get badgeTitle => 'GEA $grade';
  String get badgeSubtitle => 'TINGKAT ${labelId.toUpperCase()}';

  @override
  List<Object?> get props => [grade, labelId, labelEn, description];
}
