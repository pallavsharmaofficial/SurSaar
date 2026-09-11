import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'lesson_step.g.dart';

@JsonSerializable()
class LessonStep extends Equatable {
  const LessonStep({
    required this.title,
    required this.description,
    required this.durationMinutes,
  });

  factory LessonStep.fromJson(Map<String, dynamic> json) =>
      _$LessonStepFromJson(json);

  final String title;
  final String description;
  final int durationMinutes;

  @override
  List<Object?> get props => <Object?>[title, description, durationMinutes];

  Map<String, dynamic> toJson() => _$LessonStepToJson(this);
}
