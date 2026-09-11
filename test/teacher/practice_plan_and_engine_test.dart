import 'package:flutter_test/flutter_test.dart';
import 'package:sursaar/data/content/chord_library.dart';
import 'package:sursaar/models/lesson.dart';
import 'package:sursaar/models/song.dart';
import 'package:sursaar/models/song_section.dart';
import 'package:sursaar/models/user_settings.dart';
import 'package:sursaar/teacher/engine/chord_speech.dart';
import 'package:sursaar/teacher/engine/practice_plan.dart';
import 'package:sursaar/teacher/engine/teacher_engine.dart';

import 'audio_fixtures.dart';

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
        expect(plan.targets.first.chord, 'G');
        expect(plan.targets[1].chord, 'C');
        expect(plan.totalBeats, 16);
        expect(plan.bpm, 120);
        expect(plan.learnSteps, <String>['G', 'C', 'G', 'C']);
      },
    );

    test('changing capo re-transposes', () {
      final plan = PracticePlan.forSong(song).copyWith(capo: 0);
      expect(plan.targets.first.chord, 'A');
      expect(plan.targets[1].chord, 'D');
      expect(plan.copyWith(capo: 2).targets.first.chord, 'G');
    });

    test('song learn steps merge back-to-back repeats', () {
      final plan = PracticePlan.forChords(
        <String>['G', 'G', 'C'],
        pattern: 'D D D D',
        bpm: 80,
        rounds: 1,
      );
      expect(plan.targets.map((t) => t.chord), <String>['G', 'G', 'C']);
      expect(plan.learnSteps, <String>['G', 'G', 'C', 'G', 'G', 'C']);
    });

    test('a single-chord drill is placed three times in learn mode', () {
      final plan = PracticePlan.forChords(
        <String>['Em'],
        pattern: 'D D D D',
        bpm: 70,
      );
      expect(plan.learnSteps, <String>['Em', 'Em', 'Em']);
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

  group('TeacherEngine play-along', () {
    test('runs count-in, advances beats and finishes', () {
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
        mode: CoachingMode.playAlong,
        clock: () => now,
        autoTick: false,
        countInBeats: 2,
      );
      final beats = <int>[];
      engine.onMetronomeBeat = (beat, accent) => beats.add(beat);

      engine.start();
      expect(engine.phase, TeacherPhase.countIn);
      engine.tick();
      now += 1000;
      engine.tick();
      expect(engine.phase, TeacherPhase.running);
      now += 1000;
      engine.tick();
      expect(engine.snapshot.beat, closeTo(2, 0.01));
      expect(engine.snapshot.currentChord, 'G');
      now += 1100;
      engine.tick();
      expect(engine.phase, TeacherPhase.finished);
      expect(beats, isNotEmpty);
      expect(engine.snapshot.targetVoicing, isNotNull);
      expect(engine.snapshot.cue?.type, CueType.finished);
      engine.dispose();
    });

    test('sameChordFamily is lenient on extensions and slash chords', () {
      expect(TeacherEngine.sameChordFamily('G', 'G/B'), isTrue);
      expect(TeacherEngine.sameChordFamily('Gmaj7', 'G'), isTrue);
      expect(TeacherEngine.sameChordFamily('Gm', 'G'), isFalse);
      expect(TeacherEngine.sameChordFamily('Bb', 'A#'), isTrue);
    });
  });

  group('TeacherEngine learn mode', () {
    const rate = 22050;
    late int now;

    TeacherEngine make(List<String> chords) {
      now = 10000;
      return TeacherEngine(
        plan: PracticePlan.forChords(chords, pattern: 'D D D D', bpm: 80),
        chordLibrary: ChordLibrary(const []),
        settings: const UserSettings(metronomeEnabled: false),
        mode: CoachingMode.learn,
        clock: () => now,
        autoTick: false,
      );
    }

    void play(TeacherEngine engine, List<int> midi, {double seconds = 1.0}) {
      for (final frame in chunks(
        strum(midi, rate, seconds),
        rate,
        startMs: now,
      )) {
        engine.onAudio(frame);
        now += (frame.samples.length * 1000 / rate).round();
      }
      engine.tick();
    }

    test('starts on the first chord without a count-in', () {
      final engine = make(<String>['G', 'C']);
      engine.start();
      expect(engine.phase, TeacherPhase.running);
      expect(engine.snapshot.currentChord, 'G');
      expect(engine.snapshot.nextChord, 'C');
      expect(engine.snapshot.targetCount, 4);
      expect(engine.snapshot.message?.speak, isTrue);
      engine.dispose();
    });

    test('waits for the right chord, celebrates, then moves on', () {
      final engine = make(<String>['G', 'C']);
      engine.start();
      play(engine, gMajor);
      expect(engine.snapshot.cue?.type, CueType.correct);
      expect(engine.snapshot.celebrating, isTrue);
      expect(engine.snapshot.combo, 1);

      now += TeacherEngine.celebrateMs + 50;
      engine.tick();
      expect(engine.snapshot.currentChord, 'C');
      expect(engine.snapshot.targetIndex, 1);
      expect(engine.snapshot.holdProgress, 0);
      engine.dispose();
    });

    test('a wrong chord does not advance and a tip follows', () {
      final engine = make(<String>['G', 'C']);
      engine.start();
      play(engine, eMinor);
      expect(engine.snapshot.currentChord, 'G');
      expect(engine.snapshot.cue, isNull);

      now += TeacherEngine.hintAfterMs;
      engine.tick();
      expect(engine.snapshot.hintLevel, 1);
      expect(engine.snapshot.message!.text, startsWith('Tip:'));
      engine.dispose();
    });

    test(
      'skip, repeat the same chord with a fresh strum, finish with stars',
      () {
        final engine = make(<String>['G']);
        engine.start();

        play(engine, gMajor);
        expect(engine.snapshot.cue?.type, CueType.correct);
        now += TeacherEngine.celebrateMs + 50;
        engine.tick();
        expect(engine.snapshot.targetIndex, 1);
        expect(engine.snapshot.message!.text, contains('Lift your fingers'));

        engine.skip();
        expect(engine.snapshot.cue?.type, CueType.skipped);
        now += TeacherEngine.skipPauseMs + 50;
        engine.tick();
        expect(engine.snapshot.targetIndex, 2);

        play(engine, gMajor);
        now += TeacherEngine.celebrateMs + 50;
        engine.tick();

        final snapshot = engine.snapshot;
        expect(engine.phase, TeacherPhase.finished);
        expect(snapshot.stats.single.attempts, 3);
        expect(snapshot.stats.single.successes, 2);
        expect(snapshot.stats.single.skips, 1);
        expect(snapshot.score, closeTo(66.7, 0.1));
        expect(snapshot.stars, 2);
        expect(snapshot.trickyChords.single.chord, 'G');
        engine.dispose();
      },
    );

    test('ignores the microphone while a reference chord plays', () {
      final engine = make(<String>['G', 'C']);
      engine.start();
      engine.suppressListening(const Duration(seconds: 3));
      play(engine, gMajor);
      expect(engine.snapshot.cue, isNull);
      expect(engine.snapshot.listeningPaused, isTrue);

      now += 2000;
      play(engine, gMajor);
      expect(engine.snapshot.cue?.type, CueType.correct);
      engine.dispose();
    });

    test('reports mic level and a heard strum before the session starts', () {
      final engine = make(<String>['G']);
      for (final frame in chunks(
        strum(gMajor, rate, 0.6),
        rate,
        startMs: now,
      )) {
        engine.onAudio(frame);
        now += 100;
      }
      expect(engine.phase, TeacherPhase.idle);
      expect(engine.snapshot.heardStrum, isTrue);
      expect(engine.snapshot.inputLevel, greaterThan(0.3));
      expect(engine.snapshot.detection?.chord, 'G');
      engine.dispose();
    });
  });

  test('chord names are spoken naturally', () {
    expect(ChordSpeech.name('C#m7'), 'C sharp minor seven');
    expect(ChordSpeech.name('G/B'), 'G over B');
    expect(ChordSpeech.name('Bb'), 'A sharp');
    expect(ChordSpeech.name('Dsus4'), 'D sus four');
  });
}
