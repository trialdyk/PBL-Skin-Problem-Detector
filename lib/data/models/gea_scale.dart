class GeaGradeInfo {
  const GeaGradeInfo({
    required this.grade,
    required this.labelEn,
    required this.labelId,
    required this.description,
  });

  final int grade;
  final String labelEn;
  final String labelId;
  final String description;
}

abstract final class GeaScale {
  static const List<GeaGradeInfo> grades = [
    GeaGradeInfo(
      grade: 0,
      labelEn: 'Clear',
      labelId: 'Bersih',
      description: 'Kulit bersih, tidak ada lesi sama sekali.',
    ),
    GeaGradeInfo(
      grade: 1,
      labelEn: 'Almost clear',
      labelId: 'Hampir bersih',
      description:
          'Hampir bersih; hanya ada beberapa komedo atau papula kecil.',
    ),
    GeaGradeInfo(
      grade: 2,
      labelEn: 'Mild',
      labelId: 'Ringan',
      description:
          'Ringan; mengenai kurang dari setengah wajah dengan komedo, papula, dan sedikit pustula.',
    ),
    GeaGradeInfo(
      grade: 3,
      labelEn: 'Moderate',
      labelId: 'Sedang',
      description:
          'Sedang; mengenai lebih dari setengah wajah dengan banyak komedo, papula, pustula, dan kadang 1 nodul.',
    ),
    GeaGradeInfo(
      grade: 4,
      labelEn: 'Severe',
      labelId: 'Berat',
      description:
          'Berat; jerawat inflamasi luas disertai banyak komedo, papula, pustula, serta nodul dan kista.',
    ),
    GeaGradeInfo(
      grade: 5,
      labelEn: 'Very severe',
      labelId: 'Sangat berat',
      description:
          'Sangat berat; jerawat meradang parah yang menutupi area luas dengan dominasi nodul dan kista.',
    ),
  ];

  static GeaGradeInfo byGrade(int grade) {
    final clamped = grade.clamp(0, 5);
    return grades[clamped];
  }
}
