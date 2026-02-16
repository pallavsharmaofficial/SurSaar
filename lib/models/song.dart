import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'song.g.dart';

enum SongDifficulty {
  beginner,
  intermediate,
  advanced,
}

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

@JsonSerializable(explicitToJson: true)
class Song extends Equatable {
  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.difficulty,
    required this.strummingPattern,
    required this.originalChords,
    required this.tutorialUrl,
    this.bpm,
    this.duration,
    this.thumbnailUrl,
    this.lyrics,
    this.isFavorite = false,
    this.practiceCount = 0,
    this.performanceMetrics,
  });

  factory Song.fromJson(Map<String, dynamic> json) => _$SongFromJson(json);

  final String id;
  final String title;
  final String artist;
  @JsonKey(unknownEnumValue: SongDifficulty.intermediate)
  final SongDifficulty difficulty;
  final String strummingPattern;
  final List<String> originalChords;
  final String tutorialUrl;
  final int? bpm;
  final int? duration; // in seconds
  final String? thumbnailUrl;
  final String? lyrics;
  final bool isFavorite;
  final int practiceCount;
  final SongPerformanceMetrics? performanceMetrics;

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
      ];

  Map<String, dynamic> toJson() => _$SongToJson(this);
}
