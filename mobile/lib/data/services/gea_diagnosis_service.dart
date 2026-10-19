import 'package:pbl_skin_problem_detector/data/models/gea_result.dart';
import 'package:pbl_skin_problem_detector/data/models/interview_answers.dart';

/// Rule-based mock diagnosis. Foto belum dianalisis (ML menyusul).
class GeaDiagnosisService {
  Future<GeaResult> diagnose(InterviewAnswers answers) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));

    if (answers.skipped) {
      return GeaResult.fromGrade(2);
    }

    var score = 1.0;

    switch (answers.skinType) {
      case SkinTypeOption.oily:
      case SkinTypeOption.sensitive:
        score += 1.5;
      case SkinTypeOption.combination:
        score += 1.0;
      case SkinTypeOption.dry:
        score += 0.5;
      case SkinTypeOption.normal:
        score += 0.0;
      case null:
        score += 0.5;
    }

    if (answers.usesSunscreen == false) score += 1.0;
    if (answers.usesSunscreen == true) score -= 0.5;

    if (answers.unhealthyFoodOften == true) score += 1.0;
    if (answers.unhealthyFoodOften == false) score -= 0.3;

    final age = answers.age;
    if (age != null) {
      if (age < 18) {
        score += 0.5;
      } else if (age >= 18 && age <= 25) {
        score += 1.0;
      } else if (age > 35) {
        score -= 0.3;
      }
    }

    final grade = score.round().clamp(0, 5);
    return GeaResult.fromGrade(grade);
  }
}
