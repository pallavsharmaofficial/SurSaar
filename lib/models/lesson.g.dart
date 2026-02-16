// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lesson.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Lesson _$LessonFromJson(Map<String, dynamic> json) => Lesson(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      difficulty: $enumDecode(_$LessonDifficultyEnumMap, json['difficulty'],
          unknownValue: LessonDifficulty.intermediate,),
      duration: (json['duration'] as num).toInt(),
      topicsCount: (json['topicsCount'] as num).toInt(),
      isCompleted: json['isCompleted'] as bool,
      progress: (json['progress'] as num).toDouble(),
      steps: (json['steps'] as List<dynamic>?)
              ?.map((e) => LessonStep.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <LessonStep>[],
      thumbnailUrl: json['thumbnailUrl'] as String?,
    );

Map<String, dynamic> _$LessonToJson(Lesson instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'difficulty': _$LessonDifficultyEnumMap[instance.difficulty]!,
      'duration': instance.duration,
      'topicsCount': instance.topicsCount,
      'isCompleted': instance.isCompleted,
      'progress': instance.progress,
      'steps': instance.steps.map((e) => e.toJson()).toList(),
      'thumbnailUrl': instance.thumbnailUrl,
    };

const _$LessonDifficultyEnumMap = {
  LessonDifficulty.beginner: 'beginner',
  LessonDifficulty.intermediate: 'intermediate',
  LessonDifficulty.advanced: 'advanced',
};
