import '../data/local/app_database.dart';
import '../models/lesson.dart';
import 'content_repository.dart';

class LessonRepository {
  const LessonRepository({
    required AppDatabase database,
    required ContentRepository content,
  }) : _database = database,
       _content = content;

  final AppDatabase _database;
  final ContentRepository _content;

  Future<List<Lesson>> getLessons() async {
    final bundle = await _content.ensureLoaded();
    final progressMap = await _database.getLessonProgress();
    return bundle.lessons
        .map((lesson) {
          final progress = progressMap[lesson.id];
          if (progress == null) return lesson;
          return lesson.copyWith(
            progress: progress.progress,
            isCompleted: progress.isCompleted,
          );
        })
        .toList(growable: false);
  }

  Future<List<Lesson>> getLessonsByDifficulty(
    LessonDifficulty difficulty,
  ) async {
    final lessons = await getLessons();
    return lessons
        .where((lesson) => lesson.difficulty == difficulty)
        .toList(growable: false);
  }

  Future<Lesson?> getLessonById(String id) async {
    final lessons = await getLessons();
    for (final lesson in lessons) {
      if (lesson.id == id) return lesson;
    }
    return null;
  }

  Future<void> updateLessonProgress({
    required String lessonId,
    required double progress,
    required bool isCompleted,
  }) async {
    await _database.upsertLessonProgress(
      LessonProgressRow(
        lessonId: lessonId,
        progress: progress,
        isCompleted: isCompleted,
        updatedAt: DateTime.now(),
      ),
    );
  }
}
