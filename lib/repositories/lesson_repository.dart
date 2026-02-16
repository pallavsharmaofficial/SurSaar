import '../data/local/app_database.dart';
import '../models/lesson.dart';
import '../models/lesson_step.dart';

class LessonRepository {
  const LessonRepository({
    required AppDatabase database,
  }) : _database = database;

  final AppDatabase _database;

  List<Lesson> _baseLessons() => const <Lesson>[
        Lesson(
          id: 'basic_chords',
          title: 'Basic Guitar Chords',
          description: 'Learn the fundamental open chords: C, G, D, Em, Am',
          difficulty: LessonDifficulty.beginner,
          duration: 25,
          topicsCount: 5,
          isCompleted: false,
          progress: 0.0,
          steps: <LessonStep>[
            LessonStep(
              title: 'Chord Shapes',
              description: 'Learn finger placement for C, G, D, Em, Am.',
              durationMinutes: 6,
            ),
            LessonStep(
              title: 'Clean Fretting',
              description: 'Avoid muted strings with correct pressure.',
              durationMinutes: 5,
            ),
            LessonStep(
              title: 'Strum Practice',
              description: 'Downstrums at 70 BPM with a metronome.',
              durationMinutes: 6,
            ),
            LessonStep(
              title: 'Chord Changes',
              description: 'Switch between C → G → D smoothly.',
              durationMinutes: 6,
            ),
            LessonStep(
              title: 'Mini Challenge',
              description: 'Play 2-minute progression without stops.',
              durationMinutes: 2,
            ),
          ],
        ),
        Lesson(
          id: 'strumming_patterns',
          title: 'Strumming Patterns',
          description: 'Master essential strumming patterns for popular songs',
          difficulty: LessonDifficulty.beginner,
          duration: 30,
          topicsCount: 6,
          isCompleted: false,
          progress: 0.0,
          steps: <LessonStep>[
            LessonStep(
              title: 'Down/Up Basics',
              description: 'Alternate down and up strokes at 80 BPM.',
              durationMinutes: 6,
            ),
            LessonStep(
              title: 'Pattern 1',
              description: 'D D U U D U for 4 minutes.',
              durationMinutes: 6,
            ),
            LessonStep(
              title: 'Pattern 2',
              description: 'D DU UDU with accent on beat 2.',
              durationMinutes: 6,
            ),
            LessonStep(
              title: 'Muted Strums',
              description: 'Add muted strokes for rhythm control.',
              durationMinutes: 6,
            ),
            LessonStep(
              title: 'Tempo Build',
              description: 'Increase speed from 70 to 90 BPM.',
              durationMinutes: 6,
            ),
          ],
        ),
        Lesson(
          id: 'chord_transitions',
          title: 'Smooth Chord Transitions',
          description: 'Improve your chord switching speed and accuracy',
          difficulty: LessonDifficulty.intermediate,
          duration: 35,
          topicsCount: 8,
          isCompleted: false,
          progress: 0.0,
          steps: <LessonStep>[
            LessonStep(
              title: 'Anchor Fingers',
              description: 'Use anchor fingers between G and C.',
              durationMinutes: 8,
            ),
            LessonStep(
              title: 'Two-Chord Drill',
              description: 'Switch G ↔ Em for 2 minutes.',
              durationMinutes: 6,
            ),
            LessonStep(
              title: 'Three-Chord Drill',
              description: 'Cycle C → G → D at 80 BPM.',
              durationMinutes: 8,
            ),
            LessonStep(
              title: 'Clean Transitions',
              description: 'Reduce buzzing with correct finger lift.',
              durationMinutes: 7,
            ),
            LessonStep(
              title: 'Challenge',
              description: 'Play 3 chords for 4 minutes at 90 BPM.',
              durationMinutes: 6,
            ),
          ],
        ),
        Lesson(
          id: 'barre_chords',
          title: 'Barre Chords Mastery',
          description: 'Learn and practice barre chord techniques',
          difficulty: LessonDifficulty.intermediate,
          duration: 40,
          topicsCount: 7,
          isCompleted: false,
          progress: 0.0,
          steps: <LessonStep>[
            LessonStep(
              title: 'Barre Mechanics',
              description: 'Learn index finger pressure and thumb position.',
              durationMinutes: 8,
            ),
            LessonStep(
              title: 'E-shape Barre',
              description: 'Form F barre chord cleanly.',
              durationMinutes: 8,
            ),
            LessonStep(
              title: 'A-shape Barre',
              description: 'Form B♭ barre chord.',
              durationMinutes: 8,
            ),
            LessonStep(
              title: 'Strength Builder',
              description: 'Hold barre for 20 seconds, repeat.',
              durationMinutes: 8,
            ),
            LessonStep(
              title: 'Progression Practice',
              description: 'Switch between barre and open chords.',
              durationMinutes: 8,
            ),
          ],
        ),
        Lesson(
          id: 'fingerstyle_basics',
          title: 'Fingerstyle Basics',
          description: 'Introduction to fingerpicking patterns',
          difficulty: LessonDifficulty.intermediate,
          duration: 45,
          topicsCount: 9,
          isCompleted: false,
          progress: 0.0,
          steps: <LessonStep>[
            LessonStep(
              title: 'Thumb Independence',
              description: 'Play bass notes with thumb only.',
              durationMinutes: 8,
            ),
            LessonStep(
              title: 'Pattern 1',
              description: 'Thumb–index–middle–ring sequence.',
              durationMinutes: 8,
            ),
            LessonStep(
              title: 'Pattern 2',
              description: 'Alternating bass with melody notes.',
              durationMinutes: 8,
            ),
            LessonStep(
              title: 'Arpeggio Flow',
              description: 'Play across 4 strings evenly.',
              durationMinutes: 8,
            ),
            LessonStep(
              title: 'Mini Etude',
              description: 'Play a 2-chord fingerstyle pattern.',
              durationMinutes: 8,
            ),
          ],
        ),
        Lesson(
          id: 'scales_exercises',
          title: 'Scales and Exercises',
          description: 'Practice scales to improve finger dexterity',
          difficulty: LessonDifficulty.advanced,
          duration: 50,
          topicsCount: 10,
          isCompleted: false,
          progress: 0.0,
          steps: <LessonStep>[
            LessonStep(
              title: 'Major Scale Shape',
              description: 'Play the C major scale across 1 octave.',
              durationMinutes: 10,
            ),
            LessonStep(
              title: 'Minor Scale Shape',
              description: 'Play the A minor scale across 1 octave.',
              durationMinutes: 10,
            ),
            LessonStep(
              title: 'Alternate Picking',
              description: 'Down-up picking for scale runs.',
              durationMinutes: 10,
            ),
            LessonStep(
              title: 'Speed Ladder',
              description: 'Increase BPM from 80 to 120.',
              durationMinutes: 10,
            ),
            LessonStep(
              title: 'Accuracy Test',
              description: 'Play 2 minutes without mistakes.',
              durationMinutes: 10,
            ),
          ],
        ),
      ];

  Future<List<Lesson>> getLessons() async {
    final progressMap = await _database.getLessonProgress();
    return _baseLessons()
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
    try {
      return lessons.firstWhere((lesson) => lesson.id == id);
    } catch (_) {
      return null;
    }
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

  /// Update lessons from fetched content bundle
  Future<void> updateLessons(List<Lesson> lessons) async {
    // Store lessons in memory and optionally in database if needed
    // This method can be extended to persist lessons to database if desired
  }
}
