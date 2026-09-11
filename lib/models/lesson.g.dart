// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lesson.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Lesson _$LessonFromJson(Map<String, dynamic> json) => Lesson(
  id: json['id'] as String,
  title: json['title'] as String,
  description: json['description'] as String,
  difficulty: $enumDecode(
    _$LessonDifficultyEnumMap,
    json['difficulty'],
    unknownValue: LessonDifficulty.intermediate,
  ),
  duration: (json['duration'] as num).toInt(),
  topicsCount: (json['topicsCount'] as num).toInt(),
  isCompleted: json['isCompleted'] as bool,
  progress: (json['progress'] as num).toDouble(),
  steps:
      (json['steps'] as List<dynamic>?)
          ?.map((e) => LessonStep.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <LessonStep>[],
  thumbnailUrl: json['thumbnailUrl'] as String?,
  kind:
      $enumDecodeNullable(
        _$LessonKindEnumMap,
        json['kind'],
        unknownValue: LessonKind.exercise,
      ) ??
      LessonKind.exercise,
  instrument: json['instrument'] as String? ?? 'guitar',
  category: json['category'] as String?,
  targetChords:
      (json['targetChords'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  targetStrumming: json['targetStrumming'] as String?,
  targetBpm: (json['targetBpm'] as num?)?.toInt(),
  songId: json['songId'] as String?,
  videoUrl: json['videoUrl'] as String?,
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
  'kind': _$LessonKindEnumMap[instance.kind]!,
  'instrument': instance.instrument,
  'category': instance.category,
  'targetChords': instance.targetChords,
  'targetStrumming': instance.targetStrumming,
  'targetBpm': instance.targetBpm,
  'songId': instance.songId,
  'videoUrl': instance.videoUrl,
};

const _$LessonDifficultyEnumMap = {
  LessonDifficulty.beginner: 'beginner',
  LessonDifficulty.intermediate: 'intermediate',
  LessonDifficulty.advanced: 'advanced',
};

const _$LessonKindEnumMap = {
  LessonKind.chord: 'chord',
  LessonKind.strumming: 'strumming',
  LessonKind.song: 'song',
  LessonKind.exercise: 'exercise',
  LessonKind.theory: 'theory',
};
