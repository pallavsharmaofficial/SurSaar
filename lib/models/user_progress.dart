import 'package:equatable/equatable.dart';

class UserProgress extends Equatable {
  const UserProgress({
    required this.totalPracticeTime,
    required this.songsLearned,
    required this.currentStreak,
    required this.longestStreak,
    required this.averageAccuracy,
    required this.lessonsCompleted,
    required this.level,
    required this.xp,
  });

  factory UserProgress.initial() => const UserProgress(
        totalPracticeTime: 0,
        songsLearned: 0,
        currentStreak: 0,
        longestStreak: 0,
        averageAccuracy: 0.0,
        lessonsCompleted: 0,
        level: 1,
      xp: 0,
      );

  final int totalPracticeTime; // in minutes
  final int songsLearned;
  final int currentStreak; // days
  final int longestStreak; // days
  final double averageAccuracy; // 0.0 to 100.0
  final int lessonsCompleted;
  final int level;
  final int xp;

  UserProgress copyWith({
    int? totalPracticeTime,
    int? songsLearned,
    int? currentStreak,
    int? longestStreak,
    double? averageAccuracy,
    int? lessonsCompleted,
    int? level,
    int? xp,
  }) {
    return UserProgress(
      totalPracticeTime: totalPracticeTime ?? this.totalPracticeTime,
      songsLearned: songsLearned ?? this.songsLearned,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      averageAccuracy: averageAccuracy ?? this.averageAccuracy,
      lessonsCompleted: lessonsCompleted ?? this.lessonsCompleted,
      level: level ?? this.level,
      xp: xp ?? this.xp,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        totalPracticeTime,
        songsLearned,
        currentStreak,
        longestStreak,
        averageAccuracy,
        lessonsCompleted,
        level,
        xp,
      ];
}
