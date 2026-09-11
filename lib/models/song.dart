import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'song_section.dart';
import 'strumming_pattern.dart';

part 'song.g.dart';

enum SongDifficulty { beginner, intermediate, advanced }

@JsonSerializable()
class SongPerformanceMetrics extends Equatable {
  const SongPerformanceMetrics({
    required this.accuracy,
    required this.timing,
    required this.clarity,
  });

  factory SongPerformanceMetrics.fromJson(Map<String, dynamic> json) =>
      _$SongPerformanceMetricsFromJson(json);

  final double accuracy; // 0.0 to 1.0
  final double timing; // 0.0 to 1.0
  final double clarity; // 0.0 to 1.0

  @override
  List<Object?> get props => <Object?>[accuracy, timing, clarity];

  Map<String, dynamic> toJson() => _$SongPerformanceMetricsToJson(this);
}

/// A song in the SurSaar catalogue (content schema v2).
///
/// v1 fields are kept so older bundles still parse; v2 adds the key, capo,
/// structured sections (chords over lyric lines), tags and provenance.
@JsonSerializable(explicitToJson: true)
class Song extends Equatable {
  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.difficulty,
    required this.strummingPattern,
    required this.originalChords,
    this.tutorialUrl = '',
    this.bpm,
    this.duration,
    this.thumbnailUrl,
    this.lyrics,
    this.isFavorite = false,
    this.practiceCount = 0,
    this.performanceMetrics,
    this.key,
    this.capo = 0,
    this.sections = const <SongSection>[],
    this.tags = const <String>[],
    this.album,
    this.language,
    this.sourceUrl,
    this.instrument = 'guitar',
    this.tabs,
    this.notes,
  });

  factory Song.fromJson(Map<String, dynamic> json) => _$SongFromJson(json);

  final String id;
  final String title;
  final String artist;
  @JsonKey(unknownEnumValue: SongDifficulty.intermediate)
  final SongDifficulty difficulty;

  /// Strumming in guitarist notation, e.g. "D DU UDU".
  final String strummingPattern;

  /// Chord shapes as written on the sheet – played with the capo on [capo].
  /// (With capo 2 a "C" shape sounds like D; [key] is the sounding key.)
  final List<String> originalChords;
  final String tutorialUrl;
  final int? bpm;
  final int? duration; // in seconds
  final String? thumbnailUrl;
  final String? lyrics;
  final bool isFavorite;
  final int practiceCount;
  final SongPerformanceMetrics? performanceMetrics;

  /// Key of the recording, e.g. "G" or "Am".
  final String? key;

  /// Suggested capo fret (0 = none).
  final int capo;

  /// Song structure with chord changes.
  final List<SongSection> sections;
  final List<String> tags;

  /// Album or film the song is from.
  final String? album;
  final String? language;

  /// Where the chord sheet was sourced from (attribution).
  final String? sourceUrl;
  final String instrument;

  /// Optional ASCII tab block.
  final String? tabs;

  /// Free-form notes ("verify against the tutorial", capo tips…).
  final String? notes;

  /// Parsed strumming grid.
  StrummingPattern get strumming => StrummingPattern.parse(strummingPattern);

  /// Full chord order through the song, or the base progression when the
  /// song has no sections.
  List<String> get chordSequence {
    final fromSections = <String>[
      for (final section in sections)
        for (var i = 0; i < section.repeat; i++) ...section.chordSequence,
    ];
    return fromSections.isNotEmpty ? fromSections : originalChords;
  }

  /// Unique chords needed to play the song.
  List<String> get uniqueChords {
    final seen = <String>{};
    final result = <String>[];
    for (final chord in <String>[...originalChords, ...chordSequence]) {
      if (seen.add(chord)) result.add(chord);
    }
    return result;
  }

  Song copyWith({
    String? id,
    String? title,
    String? artist,
    SongDifficulty? difficulty,
    String? strummingPattern,
    List<String>? originalChords,
    String? tutorialUrl,
    int? bpm,
    int? duration,
    String? thumbnailUrl,
    String? lyrics,
    bool? isFavorite,
    int? practiceCount,
    SongPerformanceMetrics? performanceMetrics,
    String? key,
    int? capo,
    List<SongSection>? sections,
    List<String>? tags,
    String? album,
    String? language,
    String? sourceUrl,
    String? instrument,
    String? tabs,
    String? notes,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      difficulty: difficulty ?? this.difficulty,
      strummingPattern: strummingPattern ?? this.strummingPattern,
      originalChords: originalChords ?? this.originalChords,
      tutorialUrl: tutorialUrl ?? this.tutorialUrl,
      bpm: bpm ?? this.bpm,
      duration: duration ?? this.duration,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      lyrics: lyrics ?? this.lyrics,
      isFavorite: isFavorite ?? this.isFavorite,
      practiceCount: practiceCount ?? this.practiceCount,
      performanceMetrics: performanceMetrics ?? this.performanceMetrics,
      key: key ?? this.key,
      capo: capo ?? this.capo,
      sections: sections ?? this.sections,
      tags: tags ?? this.tags,
      album: album ?? this.album,
      language: language ?? this.language,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      instrument: instrument ?? this.instrument,
      tabs: tabs ?? this.tabs,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    title,
    artist,
    difficulty,
    strummingPattern,
    originalChords,
    tutorialUrl,
    bpm,
    duration,
    thumbnailUrl,
    lyrics,
    isFavorite,
    practiceCount,
    performanceMetrics,
    key,
    capo,
    sections,
    tags,
    album,
    language,
    sourceUrl,
    instrument,
    tabs,
    notes,
  ];

  Map<String, dynamic> toJson() => _$SongToJson(this);
}
