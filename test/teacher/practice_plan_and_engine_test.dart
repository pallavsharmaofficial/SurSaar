import 'package:flutter_test/flutter_test.dart';
import 'package:sursaar/data/content/chord_library.dart';
import 'package:sursaar/models/lesson.dart';
import 'package:sursaar/models/song.dart';
import 'package:sursaar/models/song_section.dart';
import 'package:sursaar/teacher/engine/practice_plan.dart';
import 'package:sursaar/teacher/engine/teacher_engine.dart';

void main() {
  const song = Song(
    id: 'test',
    title: 'Test',
    artist: 'Tester',
    difficulty: SongDifficulty.beginner,
    strummingPattern: 'D DU UDU',
    originalChords: <String>['G', 'C'],
    bpm: 120,
    capo: 2,
    sections: <SongSection>[
      SongSection(
        name: 'Verse',
        repeat: 2,
        lines: <SongLine>[
          SongLine(
            chords: <ChordPlacement>[
              ChordPlacement(chord: 'G'),
              ChordPlacement(chord: 'C'),
            ],
          ),
        ],
      ),
    ],
  );

  group('PracticePlan', () {
    test(
      'song plan keeps sheet shapes at the sheet capo and honours repeats',
      () {
        final plan = PracticePlan.forSong(song);
        expect(plan.targets.length, 4);
        expect(plan.targets.first.chord, 'G'); // shapes as written, capo 2
        expect(plan.targets[1].chord, 'C');
        expect(plan.totalBeats, 16);
        expect(plan.bpm, 120);
      },
    );

    test('changing capo re-transposes', () {
      // capo 2 + G shape sounds like A, so without a capo you play A
      final plan = PracticePlan.forSong(song).copyWith(capo: 0);
      expect(plan.targets.first.chord, 'A');
      expect(plan.targets[1].chord, 'D');
      final back = plan.copyWith(capo: 2);
      expect(back.targets.first.chord, 'G');
    });

    test('chord plan loops rounds', () {
      final plan = PracticePlan.forChords(
        <String>['G', 'C'],
        pattern: 'D D D D',
        bpm: 80,
        rounds: 3,
      );
      expect(plan.targets.length, 6);
      expect(plan.targetAt(9)!.chord, 'C');
      expect(plan.nextAfter(0)!.chord, 'C');
    });

    test('lesson plan uses lesson targets', () {
      const lesson = Lesson(
        id: 'l',
        title: 'L',
        description: '',
        difficulty: LessonDifficulty.beginner,
        duration: 10,
        topicsCount: 1,
        isCompleted: false,
        progress: 0,
        kind: LessonKind.chord,
        targetChords: <String>['Em', 'Am'],
        targetBpm: 66,
      );
      final plan = PracticePlan.forLesson(lesson);
      expect(plan.chords, <String>['Em', 'Am']);
      expect(plan.bpm, 66);
      expect(plan.mode, PracticeMode.lesson);
    });
  });

  group('TeacherEngine', () {
    test('runs count-in, advances beats and finishes', () async {
      var now = 1000;
      final plan = PracticePlan.forChords(
        <String>['G'],
        pattern: 'D D D D',
        bpm: 120,
        rounds: 1,
        barsPerChord: 1,
      );
      final engine = TeacherEngine(
        plan: plan,
        chordLibrary: ChordLibrary(const []),
        clock: () => now,
        autoTick: false,
        countInBeats: 2,
      );
      final beats = <int>[];
      engine.onMetronomeBeat = (beat, accent) => beats.add(beat);

      engine.start();
      expect(engine.phase, TeacherPhase.countIn);
      engine.tick();
      now += 1000; // 2 beats of count-in at 120 BPM
      engine.tick();
      expect(engine.phase, TeacherPhase.running);
      now += 1000; // beat 2
      engine.tick();
      expect(engine.snapshot.beat, closeTo(2, 0.01));
      expect(engine.snapshot.currentTarget!.chord, 'G');
      now += 1100; // past 4 beats -> finished
      engine.tick();
      expect(engine.phase, TeacherPhase.finished);
      expect(beats, isNotEmpty);
      expect(
        engine.snapshot.targetVoicing,
        isNotNull,
      ); // derived from the barre template
      engine.dispose();
    });

    test('sameChordFamily is lenient on extensions and slash chords', () {
      expect(TeacherEngine.sameChordFamily('G', 'G/B'), isTrue);
      expect(TeacherEngine.sameChordFamily('Gmaj7', 'G'), isTrue);
      expect(TeacherEngine.sameChordFamily('Gm', 'G'), isFalse);
      expect(TeacherEngine.sameChordFamily('Bb', 'A#'), isTrue);
    });
  });
}
