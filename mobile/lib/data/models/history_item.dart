import 'package:equatable/equatable.dart';

/// Status slot rekomendasi LLM (diisi teman nanti).
enum RecommendationStatus { pending, ready, failed }

RecommendationStatus recommendationStatusFrom(String? raw) {
  return switch (raw) {
    'ready' => RecommendationStatus.ready,
    'failed' => RecommendationStatus.failed,
    _ => RecommendationStatus.pending,
  };
}

class HistoryRecommendation extends Equatable {
  const HistoryRecommendation({
    required this.status,
    this.text,
    this.updatedAt,
  });

  factory HistoryRecommendation.fromJson(Map<String, dynamic> json) {
    return HistoryRecommendation(
      status: recommendationStatusFrom(json['status'] as String?),
      text: json['text'] as String?,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  final RecommendationStatus status;
  final String? text;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [status, text, updatedAt];
}

class HistoryPhotos extends Equatable {
  const HistoryPhotos({
    required this.front,
    required this.left,
    required this.right,
  });

  factory HistoryPhotos.fromJson(Map<String, dynamic> json) {
    return HistoryPhotos(
      front: json['front'] as String,
      left: json['left'] as String,
      right: json['right'] as String,
    );
  }

  final String front;
  final String left;
  final String right;

  List<String> get all => [front, left, right];

  @override
  List<Object?> get props => [front, left, right];
}

/// Item list / detail riwayat scan.
class HistoryItem extends Equatable {
  const HistoryItem({
    required this.id,
    required this.createdAt,
    required this.modelId,
    required this.grade,
    required this.gradeLabel,
    required this.resultSource,
    required this.recommendation,
    required this.photos,
    this.topLabel,
    this.interview = const {},
    this.aggregate,
  });

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    final recommendation = json['recommendation'];
    final photos = json['photos'];
    return HistoryItem(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      modelId: json['model_id'] as String? ?? 'unknown',
      grade: json['grade'] as int,
      gradeLabel: json['grade_label'] as String? ?? '',
      topLabel: json['top_label'] as String?,
      resultSource: json['result_source'] as String? ?? 'ml',
      recommendation: recommendation is Map<String, dynamic>
          ? HistoryRecommendation.fromJson(recommendation)
          : const HistoryRecommendation(status: RecommendationStatus.pending),
      photos: photos is Map<String, dynamic>
          ? HistoryPhotos.fromJson(photos)
          : const HistoryPhotos(front: '', left: '', right: ''),
      interview: json['interview'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['interview'] as Map)
          : const {},
      aggregate: json['aggregate'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['aggregate'] as Map)
          : null,
    );
  }

  final String id;
  final DateTime createdAt;
  final String modelId;
  final int grade;
  final String gradeLabel;
  final String? topLabel;
  final String resultSource;
  final HistoryRecommendation recommendation;
  final HistoryPhotos photos;
  final Map<String, dynamic> interview;
  final Map<String, dynamic>? aggregate;

  @override
  List<Object?> get props => [
        id,
        createdAt,
        modelId,
        grade,
        gradeLabel,
        topLabel,
        resultSource,
        recommendation,
        photos,
        interview,
        aggregate,
      ];
}
