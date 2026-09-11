// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'strumming_pattern.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StrummingPattern _$StrummingPatternFromJson(Map<String, dynamic> json) =>
    StrummingPattern(
      notation: json['notation'] as String,
      slots: (json['slots'] as List<dynamic>)
          .map((e) => $enumDecode(_$StrokeTypeEnumMap, e))
          .toList(),
      beatsPerBar: (json['beatsPerBar'] as num?)?.toInt() ?? 4,
    );

Map<String, dynamic> _$StrummingPatternToJson(StrummingPattern instance) =>
    <String, dynamic>{
      'notation': instance.notation,
      'slots': instance.slots.map((e) => _$StrokeTypeEnumMap[e]!).toList(),
      'beatsPerBar': instance.beatsPerBar,
    };

const _$StrokeTypeEnumMap = {
  StrokeType.down: 'down',
  StrokeType.up: 'up',
  StrokeType.mute: 'mute',
  StrokeType.rest: 'rest',
};
