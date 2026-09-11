import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'lesson_step.dart';

part 'lesson.g.dart';

enum LessonDifficulty { beginner, intermediate, advanced }

/// What the AI teacher should coach during the lesson.
enum LessonKind { chord, strumming, song, exercise, theory }

@JsonSerializable(explicitToJson: true)
class Lesson extends Equatable {
  const Lesson({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.duration,
    required this.topicsCount,
    required this.isCompleted,
    required this.progress,
    this.steps = const <LessonStep>[],
    this.thumbnailUrl,
    this.kind = LessonKind.exercise,
    this.instrument = 'guitar',
    this.category,
    this.targetChords = const <String>[],
    this.targetStrumming,
    this.targetBpm,
    this.songId,
    this.videoUrl,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) => _$LessonFromJson(json);

  final String id;
  final String title;
  final String description;
  @JsonKey(unknownEnumValue: LessonDifficulty.intermediate)
  final LessonDifficulty difficulty;
  final int duration; // in minutes
  final int topicsCount;
  final bool isCompleted;
  final double progress; // 0.0 to 1.0
  final List<LessonStep> steps;
  final String? thumbnailUrl;

  @JsonKey(unknownEnumValue: LessonKind.exercise)
  final LessonKind kind;
  final String instrument;
  final String? category;

  /// Chords the teacher drills in this lesson.
  final List<String> targetChords;

  /// Strumming notation the teacher drills in this lesson.
  final String? targetStrumming;
  final int? targetBpm;

  /// For [LessonKind.song], the song to practise.
  final String? songId;
  final String? videoUrl;

  /// True when the AI teacher can run this lesson as a practice session.
  bool get isPracticable =>
      targetChords.isNotEmpty || songId != null || targetStrumming != null;

  Lesson copyWith({
    String? id,
    String? title,
    String? description,
    LessonDifficulty? difficulty,
    int? duration,
    int? topicsCount,
    bool? isCompleted,
    double? progress,
    List<LessonStep>? steps,
    String? thumbnailUrl,
    LessonKind? kind,
    String? instrument,
    String? category,
    List<String>? targetChords,
    String? targetStrumming,
    int? targetBpm,
    String? songId,
    String? videoUrl,
  }) {
    return Lesson(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      difficulty: difficulty ?? this.difficulty,
      duration: duration ?? this.duration,
      topicsCount: topicsCount ?? this.topicsCount,
      isCompleted: isCompleted ?? this.isCompleted,
      progress: progress ?? this.progress,
      steps: steps ?? this.steps,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      kind: kind ?? this.kind,
      instrument: instrument ?? this.instrument,
      category: category ?? this.category,
      targetChords: targetChords ?? this.targetChords,
      targetStrumming: targetStrumming ?? this.targetStrumming,
      targetBpm: targetBpm ?? this.targetBpm,
      songId: songId ?? this.songId,
      videoUrl: videoUrl ?? this.videoUrl,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    title,
    description,
    difficulty,
    duration,
    topicsCount,
    isCompleted,
    progress,
    steps,
    thumbnailUrl,
    kind,
    instrument,
    category,
    targetChords,
    targetStrumming,
    targetBpm,
    songId,
    videoUrl,
  ];

  Map<String, dynamic> toJson() => _$LessonToJson(this);
}
