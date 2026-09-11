import '../data/local/app_database.dart';
import '../models/achievement.dart';

class AchievementRepository {
  const AchievementRepository({required AppDatabase database})
    : _database = database;

  final AppDatabase _database;

  Future<List<Achievement>> getAchievements() async {
    final rows = await _database.getAchievements();
    return rows
        .map(
          (row) => Achievement(
            id: row.id,
            title: row.title,
            description: row.description,
            iconAsset: row.iconAsset,
            earnedAt: row.earnedAt,
          ),
        )
        .toList(growable: false);
  }

  Future<void> awardAchievement({
    required String id,
    required String title,
    required String description,
    required String iconAsset,
  }) async {
    await _database.insertAchievement(
      AchievementRow(
        id: id,
        title: title,
        description: description,
        iconAsset: iconAsset,
        earnedAt: DateTime.now(),
      ),
    );
  }
}
