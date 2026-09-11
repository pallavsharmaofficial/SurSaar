// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Course _$CourseFromJson(Map<String, dynamic> json) => Course(
  id: json['id'] as String,
  title: json['title'] as String,
  description: json['description'] as String,
  difficulty: $enumDecode(
    _$LessonDifficultyEnumMap,
    json['difficulty'],
    unknownValue: LessonDifficulty.beginner,
  ),
  lessonIds: (json['lessonIds'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  emoji: json['emoji'] as String? ?? '🎸',
  estimatedMinutes: (json['estimatedMinutes'] as num?)?.toInt() ?? 0,
  instrument: json['instrument'] as String? ?? 'guitar',
);

Map<String, dynamic> _$CourseToJson(Course instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'description': instance.description,
  'difficulty': _$LessonDifficultyEnumMap[instance.difficulty]!,
  'lessonIds': instance.lessonIds,
  'emoji': instance.emoji,
  'estimatedMinutes': instance.estimatedMinutes,
  'instrument': instance.instrument,
};

const _$LessonDifficultyEnumMap = {
  LessonDifficulty.beginner: 'beginner',
  LessonDifficulty.intermediate: 'intermediate',
  LessonDifficulty.advanced: 'advanced',
};
