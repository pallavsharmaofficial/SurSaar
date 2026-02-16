import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'lesson_step.dart';

part 'lesson.g.dart';

enum LessonDifficulty {
  beginner,
  intermediate,
  advanced,
}

@JsonSerializable(explicitToJson: true)
class Lesson extends Equatable {
  const Lesson({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.duration,
    required this.topicsCount,
    required this.isCompleted,
    required this.progress,
    this.steps = const <LessonStep>[],
    this.thumbnailUrl,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) => _$LessonFromJson(json);

  final String id;
  final String title;
  final String description;
  @JsonKey(unknownEnumValue: LessonDifficulty.intermediate)
  final LessonDifficulty difficulty;
  final int duration; // in minutes
  final int topicsCount;
  final bool isCompleted;
  final double progress; // 0.0 to 1.0
  final List<LessonStep> steps;
  final String? thumbnailUrl;

  Lesson copyWith({
    String? id,
    String? title,
    String? description,
    LessonDifficulty? difficulty,
    int? duration,
    int? topicsCount,
    bool? isCompleted,
    double? progress,
    List<LessonStep>? steps,
    String? thumbnailUrl,
  }) {
    return Lesson(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      difficulty: difficulty ?? this.difficulty,
      duration: duration ?? this.duration,
      topicsCount: topicsCount ?? this.topicsCount,
      isCompleted: isCompleted ?? this.isCompleted,
      progress: progress ?? this.progress,
      steps: steps ?? this.steps,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        title,
        description,
        difficulty,
        duration,
        topicsCount,
        isCompleted,
        progress,
        steps,
        thumbnailUrl,
      ];

  Map<String, dynamic> toJson() => _$LessonToJson(this);
}
