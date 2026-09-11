// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'song_section.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChordPlacement _$ChordPlacementFromJson(Map<String, dynamic> json) =>
    ChordPlacement(
      chord: json['chord'] as String,
      position: (json['position'] as num?)?.toInt() ?? 0,
      beats: (json['beats'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$ChordPlacementToJson(ChordPlacement instance) =>
    <String, dynamic>{
      'chord': instance.chord,
      'position': instance.position,
      'beats': instance.beats,
    };

SongLine _$SongLineFromJson(Map<String, dynamic> json) => SongLine(
  lyric: json['lyric'] as String? ?? '',
  chords:
      (json['chords'] as List<dynamic>?)
          ?.map((e) => ChordPlacement.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <ChordPlacement>[],
);

Map<String, dynamic> _$SongLineToJson(SongLine instance) => <String, dynamic>{
  'lyric': instance.lyric,
  'chords': instance.chords.map((e) => e.toJson()).toList(),
};

SongSection _$SongSectionFromJson(Map<String, dynamic> json) => SongSection(
  name: json['name'] as String,
  lines:
      (json['lines'] as List<dynamic>?)
          ?.map((e) => SongLine.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <SongLine>[],
  strumming: json['strumming'] as String?,
  repeat: (json['repeat'] as num?)?.toInt() ?? 1,
  barsPerChord: (json['barsPerChord'] as num?)?.toInt(),
);

Map<String, dynamic> _$SongSectionToJson(SongSection instance) =>
    <String, dynamic>{
      'name': instance.name,
      'lines': instance.lines.map((e) => e.toJson()).toList(),
      'strumming': instance.strumming,
      'repeat': instance.repeat,
      'barsPerChord': instance.barsPerChord,
    };
