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
      version: json['version'] as String? ?? '1.0',
      lastUpdated: json['lastUpdated'] as String?,
    );

Map<String, dynamic> _$ContentBundleToJson(ContentBundle instance) =>
    <String, dynamic>{
      'lessons': instance.lessons.map((e) => e.toJson()).toList(),
      'songs': instance.songs.map((e) => e.toJson()).toList(),
      'version': instance.version,
      'lastUpdated': instance.lastUpdated,
    };
