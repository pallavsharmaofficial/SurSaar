import '../data/local/app_database.dart';
import '../models/course.dart';
import '../models/lesson.dart';
import 'content_repository.dart';

/// A course together with the learner's progress through it.
class CourseProgress {
  const CourseProgress({
    required this.course,
    required this.lessons,
    required this.completedCount,
  });

  final Course course;
  final List<Lesson> lessons;
  final int completedCount;

  double get fraction => lessons.isEmpty ? 0 : completedCount / lessons.length;

  bool get isCompleted =>
      lessons.isNotEmpty && completedCount == lessons.length;

  /// The first lesson that is not completed yet (or null when done).
  Lesson? get nextLesson {
    for (final lesson in lessons) {
      if (!lesson.isCompleted) return lesson;
    }
    return null;
  }
}

class CourseRepository {
  const CourseRepository({
    required AppDatabase database,
    required ContentRepository content,
  }) : _database = database,
       _content = content;

  final AppDatabase _database;
  final ContentRepository _content;

  Future<List<CourseProgress>> getCourses() async {
    final bundle = await _content.ensureLoaded();
    final progressMap = await _database.getLessonProgress();
    final lessonsById = <String, Lesson>{
      for (final lesson in bundle.lessons) lesson.id: lesson,
    };
    return bundle.courses
        .map((course) {
          final lessons = <Lesson>[];
          for (final id in course.lessonIds) {
            final lesson = lessonsById[id];
            if (lesson == null) continue;
            final progress = progressMap[id];
            lessons.add(
              progress == null
                  ? lesson
                  : lesson.copyWith(
                      progress: progress.progress,
                      isCompleted: progress.isCompleted,
                    ),
            );
          }
          return CourseProgress(
            course: course,
            lessons: lessons,
            completedCount: lessons.where((l) => l.isCompleted).length,
          );
        })
        .toList(growable: false);
  }

  Future<CourseProgress?> getCourseById(String id) async {
    final courses = await getCourses();
    for (final course in courses) {
      if (course.course.id == id) return course;
    }
    return null;
  }
}
