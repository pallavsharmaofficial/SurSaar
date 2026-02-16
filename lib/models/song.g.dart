// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'song.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SongPerformanceMetrics _$SongPerformanceMetricsFromJson(
        Map<String, dynamic> json,) =>
    SongPerformanceMetrics(
      accuracy: (json['accuracy'] as num).toDouble(),
      timing: (json['timing'] as num).toDouble(),
      clarity: (json['clarity'] as num).toDouble(),
    );

Map<String, dynamic> _$SongPerformanceMetricsToJson(
        SongPerformanceMetrics instance,) =>
    <String, dynamic>{
      'accuracy': instance.accuracy,
      'timing': instance.timing,
      'clarity': instance.clarity,
    };

Song _$SongFromJson(Map<String, dynamic> json) => Song(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      difficulty: $enumDecode(_$SongDifficultyEnumMap, json['difficulty'],
          unknownValue: SongDifficulty.intermediate,),
      strummingPattern: json['strummingPattern'] as String,
      originalChords: (json['originalChords'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      tutorialUrl: json['tutorialUrl'] as String,
      bpm: (json['bpm'] as num?)?.toInt(),
      duration: (json['duration'] as num?)?.toInt(),
      thumbnailUrl: json['thumbnailUrl'] as String?,
      lyrics: json['lyrics'] as String?,
      isFavorite: json['isFavorite'] as bool? ?? false,
      practiceCount: (json['practiceCount'] as num?)?.toInt() ?? 0,
      performanceMetrics: json['performanceMetrics'] == null
          ? null
          : SongPerformanceMetrics.fromJson(
              json['performanceMetrics'] as Map<String, dynamic>,),
    );

Map<String, dynamic> _$SongToJson(Song instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'artist': instance.artist,
      'difficulty': _$SongDifficultyEnumMap[instance.difficulty]!,
      'strummingPattern': instance.strummingPattern,
      'originalChords': instance.originalChords,
      'tutorialUrl': instance.tutorialUrl,
      'bpm': instance.bpm,
      'duration': instance.duration,
      'thumbnailUrl': instance.thumbnailUrl,
      'lyrics': instance.lyrics,
      'isFavorite': instance.isFavorite,
      'practiceCount': instance.practiceCount,
      'performanceMetrics': instance.performanceMetrics?.toJson(),
    };

const _$SongDifficultyEnumMap = {
  SongDifficulty.beginner: 'beginner',
  SongDifficulty.intermediate: 'intermediate',
  SongDifficulty.advanced: 'advanced',
};
