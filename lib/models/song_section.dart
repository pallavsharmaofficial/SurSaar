import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'song_section.g.dart';

/// A chord placed above a lyric line at a character offset.
@JsonSerializable()
class ChordPlacement extends Equatable {
  const ChordPlacement({required this.chord, this.position = 0, this.beats});

  factory ChordPlacement.fromJson(Map<String, dynamic> json) =>
      _$ChordPlacementFromJson(json);

  final String chord;

  /// Character index in the lyric where the chord change happens.
  final int position;

  /// How many beats the chord is held (optional; defaults to an even split).
  final double? beats;

  Map<String, dynamic> toJson() => _$ChordPlacementToJson(this);

  @override
  List<Object?> get props => <Object?>[chord, position, beats];
}

/// One lyric line with its chord changes. The lyric may be empty when the
/// source only provides a progression (chord-only lines are the default for
/// bundled content so that no copyrighted lyrics ship with the app).
@JsonSerializable(explicitToJson: true)
class SongLine extends Equatable {
  const SongLine({this.lyric = '', this.chords = const <ChordPlacement>[]});

  factory SongLine.fromJson(Map<String, dynamic> json) =>
      _$SongLineFromJson(json);

  /// Convenience for progression-only lines.
  factory SongLine.chords(List<String> chords) => SongLine(
    chords: chords.map((c) => ChordPlacement(chord: c)).toList(growable: false),
  );

  final String lyric;
  final List<ChordPlacement> chords;

  Map<String, dynamic> toJson() => _$SongLineToJson(this);

  @override
  List<Object?> get props => <Object?>[lyric, chords];
}

/// A named part of a song (Intro, Verse, Chorus, Bridge…).
@JsonSerializable(explicitToJson: true)
class SongSection extends Equatable {
  const SongSection({
    required this.name,
    this.lines = const <SongLine>[],
    this.strumming,
    this.repeat = 1,
    this.barsPerChord,
  });

  factory SongSection.fromJson(Map<String, dynamic> json) =>
      _$SongSectionFromJson(json);

  final String name;
  final List<SongLine> lines;

  /// Section-specific strumming override (notation string).
  final String? strumming;

  /// How many times the section is played back to back.
  final int repeat;

  /// Bars each chord is held in this section when there are no lyrics
  /// to derive timing from (defaults to 1).
  final int? barsPerChord;

  Map<String, dynamic> toJson() => _$SongSectionToJson(this);

  /// All chord names in order of appearance.
  List<String> get chordSequence => <String>[
    for (final line in lines)
      for (final placement in line.chords) placement.chord,
  ];

  @override
  List<Object?> get props => <Object?>[
    name,
    lines,
    strumming,
    repeat,
    barsPerChord,
  ];
}
