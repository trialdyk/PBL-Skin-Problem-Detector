import 'package:equatable/equatable.dart';

enum GenderOption { male, female, preferNotToSay }

enum SkinTypeOption { oily, dry, combination, sensitive, normal }

class InterviewAnswers extends Equatable {
  const InterviewAnswers({
    this.gender,
    this.age,
    this.usesSunscreen,
    this.skinType,
    this.unhealthyFoodOften,
    this.skipped = false,
  });

  final GenderOption? gender;
  final int? age;
  final bool? usesSunscreen;
  final SkinTypeOption? skinType;
  final bool? unhealthyFoodOften;
  final bool skipped;

  InterviewAnswers copyWith({
    GenderOption? gender,
    int? age,
    bool? usesSunscreen,
    SkinTypeOption? skinType,
    bool? unhealthyFoodOften,
    bool? skipped,
  }) {
    return InterviewAnswers(
      gender: gender ?? this.gender,
      age: age ?? this.age,
      usesSunscreen: usesSunscreen ?? this.usesSunscreen,
      skinType: skinType ?? this.skinType,
      unhealthyFoodOften: unhealthyFoodOften ?? this.unhealthyFoodOften,
      skipped: skipped ?? this.skipped,
    );
  }

  /// Payload JSON untuk `POST /history` (snake_case sesuai backend).
  Map<String, Object?> toApiJson() {
    return {
      'gender': switch (gender) {
        GenderOption.male => 'male',
        GenderOption.female => 'female',
        GenderOption.preferNotToSay => 'prefer_not_to_say',
        null => null,
      },
      'age': age,
      'uses_sunscreen': usesSunscreen,
      'skin_type': skinType?.name,
      'unhealthy_food_often': unhealthyFoodOften,
      'skipped': skipped,
    };
  }

  @override
  List<Object?> get props => [
        gender,
        age,
        usesSunscreen,
        skinType,
        unhealthyFoodOften,
        skipped,
      ];
}
