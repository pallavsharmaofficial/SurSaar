import '../data/local/app_database.dart';
import '../models/user_progress.dart';

class ProgressRepository {
  const ProgressRepository({required AppDatabase database})
    : _database = database;

  final AppDatabase _database;

  Future<UserProgress> getProgress() async {
    final row = await _database.getUserProgress();
    return UserProgress(
      totalPracticeTime: row.totalPracticeTime,
      songsLearned: row.songsLearned,
      currentStreak: row.currentStreak,
      longestStreak: row.longestStreak,
      averageAccuracy: row.averageAccuracy,
      lessonsCompleted: row.lessonsCompleted,
      level: row.level,
      xp: row.xp,
    );
  }

  Future<void> saveProgress(UserProgress progress, {String? lastDay}) async {
    final existing = await _database.getUserProgress();
    await _database.saveUserProgress(
      UserProgressRow(
        totalPracticeTime: progress.totalPracticeTime,
        songsLearned: progress.songsLearned,
        currentStreak: progress.currentStreak,
        longestStreak: progress.longestStreak,
        averageAccuracy: progress.averageAccuracy,
        lessonsCompleted: progress.lessonsCompleted,
        level: progress.level,
        xp: progress.xp,
        lastPracticeDay: lastDay ?? existing.lastPracticeDay,
      ),
    );
  }

  Future<void> updatePracticeTime(int additionalMinutes) async {
    final progress = await getProgress();
    await saveProgress(
      progress.copyWith(
        totalPracticeTime: progress.totalPracticeTime + additionalMinutes,
      ),
    );
  }

  Future<void> incrementSongsLearned() async {
    final progress = await getProgress();
    await saveProgress(
      progress.copyWith(songsLearned: progress.songsLearned + 1),
    );
  }

  Future<void> incrementLessonsCompleted() async {
    final progress = await getProgress();
    await saveProgress(
      progress.copyWith(
        lessonsCompleted: progress.lessonsCompleted + 1,
        xp: progress.xp + 20,
        level: ((progress.xp + 20) / 100).floor() + 1,
      ),
    );
  }

  Future<void> updateStreak(int newStreak) async {
    final progress = await getProgress();
    final longestStreak = newStreak > progress.longestStreak
        ? newStreak
        : progress.longestStreak;
    await saveProgress(
      progress.copyWith(currentStreak: newStreak, longestStreak: longestStreak),
    );
  }

  /// Records a finished teacher session: time, accuracy, XP, streak and
  /// achievements.
  Future<void> recordPracticeSession({
    required int durationInSeconds,
    required double accuracy,
    DateTime? now,
  }) async {
    final today = now ?? DateTime.now();
    final row = await _database.getUserProgress();
    final progress = await getProgress();

    final totalMinutes =
        progress.totalPracticeTime + (durationInSeconds / 60).round();
    final updatedCount = progress.songsLearned + 1;
    final newAverage =
        ((progress.averageAccuracy * progress.songsLearned) + accuracy) /
        updatedCount;
    final xpGained = accuracy.round() + 5;
    final newXp = progress.xp + xpGained;
    final newLevel = (newXp / 100).floor() + 1;

    // Streak: consecutive calendar days with a saved session.
    final todayKey = _dayKey(today);
    final yesterdayKey = _dayKey(today.subtract(const Duration(days: 1)));
    var streak = progress.currentStreak;
    if (row.lastPracticeDay == todayKey) {
      // already counted today
    } else if (row.lastPracticeDay == yesterdayKey) {
      streak += 1;
    } else {
      streak = 1;
    }
    final longest = streak > progress.longestStreak
        ? streak
        : progress.longestStreak;

    await saveProgress(
      progress.copyWith(
        totalPracticeTime: totalMinutes,
        songsLearned: updatedCount,
        averageAccuracy: newAverage,
        xp: newXp,
        level: newLevel,
        currentStreak: streak,
        longestStreak: longest,
      ),
      lastDay: todayKey,
    );

    final sessionCount = await _database.getPracticeSessionCount();
    await _maybeAwardAchievements(sessionCount, newLevel, streak);
  }

  static String _dayKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  Future<void> _maybeAwardAchievements(
    int sessionCount,
    int level,
    int streak,
  ) async {
    Future<void> award(
      String id,
      String title,
      String description,
      String icon,
    ) {
      return _database.insertAchievement(
        AchievementRow(
          id: id,
          title: title,
          description: description,
          iconAsset: icon,
          earnedAt: DateTime.now(),
        ),
      );
    }

    if (sessionCount >= 1) {
      await award(
        'first_practice',
        'First Jam',
        'Completed your first practice session.',
        'assets/images/skill_progress_ribbon.svg',
      );
    }
    if (sessionCount >= 5) {
      await award(
        'five_sessions',
        'Consistency Starts',
        'Finished 5 practice sessions.',
        'assets/images/skill_progress_ribbon.svg',
      );
    }
    if (sessionCount >= 10) {
      await award(
        'ten_sessions',
        'Rhythm Builder',
        'Completed 10 practice sessions.',
        'assets/images/strumming_visualizer.svg',
      );
    }
    if (level >= 3) {
      await award(
        'level_three',
        'Rising Artist',
        'Reached level 3.',
        'assets/images/ai_vision_scanner.svg',
      );
    }
    if (streak >= 7) {
      await award(
        'week_streak',
        'Seven Days Strong',
        'Practised 7 days in a row.',
        'assets/images/mic_ai.svg',
      );
    }
  }
}
