// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'content_bundle.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ContentBundle _$ContentBundleFromJson(Map<String, dynamic> json) =>
    ContentBundle(
      lessons: (json['lessons'] as List<dynamic>)
          .map((e) => Lesson.fromJson(e as Map<String, dynamic>))
          .toList(),
      songs: (json['songs'] as List<dynamic>)
          .map((e) => Song.fromJson(e as Map<String, dynamic>))
          .toList(),
      courses:
          (json['courses'] as List<dynamic>?)
              ?.map((e) => Course.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <Course>[],
      chords:
          (json['chords'] as List<dynamic>?)
              ?.map((e) => ChordVoicing.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <ChordVoicing>[],
      version: json['version'] as String? ?? '2.0',
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 2,
      lastUpdated: json['lastUpdated'] as String?,
    );

Map<String, dynamic> _$ContentBundleToJson(ContentBundle instance) =>
    <String, dynamic>{
      'lessons': instance.lessons.map((e) => e.toJson()).toList(),
      'songs': instance.songs.map((e) => e.toJson()).toList(),
      'courses': instance.courses.map((e) => e.toJson()).toList(),
      'chords': instance.chords.map((e) => e.toJson()).toList(),
      'version': instance.version,
      'schemaVersion': instance.schemaVersion,
      'lastUpdated': instance.lastUpdated,
    };
