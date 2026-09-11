// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chord_voicing.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Barre _$BarreFromJson(Map<String, dynamic> json) => Barre(
  fret: (json['fret'] as num).toInt(),
  startString: (json['startString'] as num).toInt(),
  endString: (json['endString'] as num).toInt(),
  finger: (json['finger'] as num?)?.toInt() ?? 1,
);

Map<String, dynamic> _$BarreToJson(Barre instance) => <String, dynamic>{
  'fret': instance.fret,
  'startString': instance.startString,
  'endString': instance.endString,
  'finger': instance.finger,
};

ChordVoicing _$ChordVoicingFromJson(Map<String, dynamic> json) => ChordVoicing(
  name: json['name'] as String,
  frets: (json['frets'] as List<dynamic>)
      .map((e) => (e as num).toInt())
      .toList(),
  fingers:
      (json['fingers'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
      const <int>[0, 0, 0, 0, 0, 0],
  baseFret: (json['baseFret'] as num?)?.toInt() ?? 1,
  barres:
      (json['barres'] as List<dynamic>?)
          ?.map((e) => Barre.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <Barre>[],
  label: json['label'] as String?,
);

Map<String, dynamic> _$ChordVoicingToJson(ChordVoicing instance) =>
    <String, dynamic>{
      'name': instance.name,
      'frets': instance.frets,
      'fingers': instance.fingers,
      'baseFret': instance.baseFret,
      'barres': instance.barres.map((e) => e.toJson()).toList(),
      'label': instance.label,
    };
