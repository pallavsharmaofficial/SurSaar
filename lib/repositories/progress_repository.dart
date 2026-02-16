import '../data/local/app_database.dart';
import '../models/user_progress.dart';

class ProgressRepository {
  const ProgressRepository({
    required AppDatabase database,
  }) : _database = database;

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

  Future<void> saveProgress(UserProgress progress) async {
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
      ),
    );
  }

  Future<void> updatePracticeTime(int additionalMinutes) async {
    final progress = await getProgress();
    final updated = progress.copyWith(
      totalPracticeTime: progress.totalPracticeTime + additionalMinutes,
    );
    await saveProgress(updated);
  }

  Future<void> incrementSongsLearned() async {
    final progress = await getProgress();
    final updated = progress.copyWith(
      songsLearned: progress.songsLearned + 1,
    );
    await saveProgress(updated);
  }

  Future<void> updateStreak(int newStreak) async {
    final progress = await getProgress();
    final longestStreak = newStreak > progress.longestStreak
        ? newStreak
        : progress.longestStreak;
    final updated = progress.copyWith(
      currentStreak: newStreak,
      longestStreak: longestStreak,
    );
    await saveProgress(updated);
  }

  Future<void> recordPracticeSession({
    required int durationInSeconds,
    required double accuracy,
  }) async {
    final progress = await getProgress();
    final totalMinutes =
        progress.totalPracticeTime + (durationInSeconds / 60).round();
    final updatedCount = progress.songsLearned + 1;
    final newAverage = ((progress.averageAccuracy * progress.songsLearned) +
            accuracy) /
        updatedCount;
    final xpGained = accuracy.round() + 5;
    final newXp = progress.xp + xpGained;
    final newLevel = (newXp / 100).floor() + 1;

    final updated = progress.copyWith(
      totalPracticeTime: totalMinutes,
      songsLearned: updatedCount,
      averageAccuracy: newAverage,
      xp: newXp,
      level: newLevel,
    );

    await saveProgress(updated);

    final sessionCount = await _database.getPracticeSessionCount();
    await _maybeAwardAchievements(sessionCount, newLevel);
  }

  Future<void> _maybeAwardAchievements(int sessionCount, int level) async {
    if (sessionCount >= 1) {
      await _database.insertAchievement(
        AchievementRow(
          id: 'first_practice',
          title: 'First Jam',
          description: 'Completed your first practice session.',
          iconAsset: 'assets/images/skill_progress_ribbon.svg',
          earnedAt: DateTime.now(),
        ),
      );
    }
    if (sessionCount >= 5) {
      await _database.insertAchievement(
        AchievementRow(
          id: 'five_sessions',
          title: 'Consistency Starts',
          description: 'Finished 5 practice sessions.',
          iconAsset: 'assets/images/skill_progress_ribbon.svg',
          earnedAt: DateTime.now(),
        ),
      );
    }
    if (sessionCount >= 10) {
      await _database.insertAchievement(
        AchievementRow(
          id: 'ten_sessions',
          title: 'Rhythm Builder',
          description: 'Completed 10 practice sessions.',
          iconAsset: 'assets/images/strumming_visualizer.svg',
          earnedAt: DateTime.now(),
        ),
      );
    }
    if (level >= 3) {
      await _database.insertAchievement(
        AchievementRow(
          id: 'level_three',
          title: 'Rising Artist',
          description: 'Reached level 3.',
          iconAsset: 'assets/images/ai_vision_scanner.svg',
          earnedAt: DateTime.now(),
        ),
      );
    }
  }
}
