import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'lesson.dart';

part 'course.g.dart';

/// An ordered path through lessons. Learners can follow a course or start
/// an ad-hoc practice at any time.
@JsonSerializable()
class Course extends Equatable {
  const Course({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.lessonIds,
    this.emoji = '🎸',
    this.estimatedMinutes = 0,
    this.instrument = 'guitar',
  });

  factory Course.fromJson(Map<String, dynamic> json) => _$CourseFromJson(json);

  final String id;
  final String title;
  final String description;
  @JsonKey(unknownEnumValue: LessonDifficulty.beginner)
  final LessonDifficulty difficulty;
  final List<String> lessonIds;
  final String emoji;
  final int estimatedMinutes;
  final String instrument;

  Map<String, dynamic> toJson() => _$CourseToJson(this);

  @override
  List<Object?> get props => <Object?>[
    id,
    title,
    description,
    difficulty,
    lessonIds,
    emoji,
    estimatedMinutes,
    instrument,
  ];
}
