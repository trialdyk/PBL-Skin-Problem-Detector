import 'package:equatable/equatable.dart';

/// Hasil `POST /ml/predict` yang dipakai aplikasi.
///
/// Server mengirim prediksi per foto dan satu `aggregate` (rata-rata softmax).
/// Yang dipakai untuk GEA adalah `aggregate.grade` (0–5, model hanya bisa 0–4).
class MlPrediction extends Equatable {
  const MlPrediction({
    required this.grade,
    required this.topLabel,
    required this.model,
    this.probabilities = const [],
  });

  factory MlPrediction.fromJson(Map<String, dynamic> json) {
    final aggregate = json['aggregate'];
    if (aggregate is! Map<String, dynamic>) {
      throw const FormatException('aggregate tidak ditemukan');
    }

    final grade = aggregate['grade'];
    if (grade is! int || grade < 0 || grade > 5) {
      throw const FormatException('grade tidak valid');
    }

    final predictions = aggregate['predictions'];
    return MlPrediction(
      grade: grade,
      topLabel: aggregate['top_label'] as String? ?? 'IGA$grade',
      model: json['model'] as String? ?? 'unknown',
      probabilities: predictions is List
          ? [
              for (final item in predictions)
                if (item is Map<String, dynamic> && item['probability'] is num)
                  (item['probability'] as num).toDouble(),
            ]
          : const [],
    );
  }

  /// GEA 0–5 hasil rata-rata seluruh foto.
  final int grade;

  /// Label kelas teratas, mis. `IGA2`.
  final String topLabel;

  /// Identifier model di server, mis. `dermascan-custom-cnn-v1`.
  final String model;

  /// Probabilitas kelas IGA0–IGA4 (urut sesuai model).
  final List<double> probabilities;

  @override
  List<Object?> get props => [grade, topLabel, model, probabilities];
}