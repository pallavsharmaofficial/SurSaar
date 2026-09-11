import 'package:equatable/equatable.dart';

class PracticeSession extends Equatable {
  const PracticeSession({
    required this.id,
    required this.songId,
    required this.startTime,
    required this.duration,
    required this.accuracyScore,
    required this.chordsPlayed,
    required this.mistakeCount,
    this.timingAccuracy,
    this.mode,
  });

  final String id;

  /// Song id, lesson id or "adhoc".
  final String songId;
  final DateTime startTime;
  final int duration; // in seconds
  final double accuracyScore; // 0.0 to 100.0
  final int chordsPlayed;
  final int mistakeCount;
  final double? timingAccuracy; // 0.0 to 100.0
  final String? mode; // song | lesson | adhoc

  @override
  List<Object?> get props => <Object?>[
    id,
    songId,
    startTime,
    duration,
    accuracyScore,
    chordsPlayed,
    mistakeCount,
    timingAccuracy,
    mode,
  ];
}
