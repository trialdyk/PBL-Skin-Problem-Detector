import 'package:equatable/equatable.dart';
import 'package:pbl_skin_problem_detector/data/models/gea_scale.dart';
import 'package:pbl_skin_problem_detector/data/models/result_source.dart';

class GeaResult extends Equatable {
  const GeaResult({
    required this.grade,
    required this.labelId,
    required this.labelEn,
    required this.description,
    this.source = ResultSource.ruleBased,
  });

  factory GeaResult.fromGrade(
    int grade, {
    ResultSource source = ResultSource.ruleBased,
  }) {
    final info = GeaScale.byGrade(grade);
    return GeaResult(
      grade: info.grade,
      labelId: info.labelId,
      labelEn: info.labelEn,
      description: info.description,
      source: source,
    );
  }

  final int grade;
  final String labelId;
  final String labelEn;
  final String description;
  final ResultSource source;

  String get badgeTitle => 'GEA $grade';
  String get badgeSubtitle => 'TINGKAT ${labelId.toUpperCase()}';

  @override
  List<Object?> get props => [grade, labelId, labelEn, description, source];
}
