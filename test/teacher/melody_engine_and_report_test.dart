import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sursaar/data/content/chord_library.dart';
import 'package:sursaar/models/user_settings.dart';
import 'package:sursaar/teacher/engine/practice_plan.dart';
import 'package:sursaar/teacher/engine/teacher_engine.dart';
import 'package:sursaar/teacher/melody/melody_tab.dart';

import 'audio_fixtures.dart';
import 'melody_test.dart' show pluck;

void main() {
  const rate = 22050;
  late int now;

  TeacherEngine make(PracticePlan plan, {CoachingMode? mode}) {
    now = 10000;
    return TeacherEngine(
      plan: plan,
      chordLibrary: ChordLibrary(const []),
      settings: const UserSettings(metronomeEnabled: false),
      mode: mode ?? CoachingMode.learn,
      clock: () => now,
      autoTick: false,
    );
  }

  void feed(TeacherEngine engine, Float32List samples) {
    for (final frame in chunks(samples, rate, startMs: now)) {
      engine.onAudio(frame);
      now += (frame.samples.length * 1000 / rate).round();
    }
    engine.tick();
  }

  Float32List plucked(int midi, {double seconds = 0.8}) {
    final tone = pluck(NoteName.frequency(midi), rate, seconds);
    final silence = (rate * 0.25).round();
    return Float32List(silence + tone.length)..setAll(silence, tone);
  }

  void advance(TeacherEngine engine) {
    now += TeacherEngine.celebrateMs + 50;
    engine.tick();
  }

  group('melody learn mode', () {
    const notes = <TabNote>[
      TabNote(string: 4, fret: 1, section: 'Sthayi'), // C4
      TabNote(string: 4, fret: 3, section: 'Sthayi'), // D4
      TabNote(string: 5, fret: 0, section: 'Sthayi'), // E4
    ];
    PracticePlan plan() => PracticePlan.forMelody(notes, title: 'Scale');

    test('plan targets are note tokens with a one-finger-per-fret box', () {
      final p = plan();
      expect(p.isMelody, isTrue);
      expect(p.learnSteps, <String>['n:4:1', 'n:4:3', 'n:5:0']);
      expect(p.boxStart, 1);
      expect(p.copyWith(capo: 3).learnSteps, p.learnSteps);
    });

    test('accepts the right pitch, rejects a neighbour, and names it', () {
      final engine = make(plan());
      engine.start();
      expect(engine.snapshot.message!.text, contains('B string · 1st fret'));
      expect(engine.snapshot.targetVoicing!.frets[4], 1);

      // C#4 – one fret too high, held past the coach's message cooldown.
      feed(engine, plucked(61, seconds: 4.0));
      expect(engine.snapshot.cue, isNull);
      expect(engine.snapshot.message!.text, contains('1 fret lower'));

      feed(engine, plucked(60));
      expect(engine.snapshot.cue?.type, CueType.correct);
      advance(engine);
      expect(engine.snapshot.currentChord, 'n:4:3');
      engine.dispose();
    });

    test('finishing yields a report with transitions and pitch data', () {
      final engine = make(plan());
      engine.start();
      for (final midi in <int>[60, 62, 64]) {
        feed(engine, plucked(midi));
        advance(engine);
      }
      expect(engine.phase, TeacherPhase.finished);
      final report = engine.snapshot.report!;
      expect(report.isMelody, isTrue);
      expect(report.successes, 3);
      expect(report.transitions.map((t) => t.key), <String>[
        'n:4:1>n:4:3',
        'n:4:3>n:5:0',
      ]);
      expect(report.noteCentsOffsets.length, 3);
      expect(report.averageCents!.abs(), lessThan(20));
      expect(engine.snapshot.message!.text, 'You played every note!');
      engine.dispose();
    });
  });

  group('chord session report', () {
    test('records chord change times and confusions in learn mode', () {
      final engine = make(
        PracticePlan.forChords(
          <String>['G', 'C'],
          pattern: 'D D D D',
          bpm: 80,
          rounds: 1,
        ),
      );
      engine.start();
      feed(engine, strum(gMajor, rate, 1.0));
      advance(engine);
      // Plays E minor first while C is the target.
      feed(engine, strum(eMinor, rate, 1.0));
      feed(engine, strum(cMajor, rate, 1.0));
      advance(engine);
      engine.skip();
      advance(engine);
      engine.skip();
      advance(engine);
      expect(engine.phase, TeacherPhase.finished);

      final report = engine.snapshot.report!;
      final gToC = report.transitions.firstWhere((t) => t.key == 'G>C');
      expect(gToC.successes, 1);
      expect(gToC.averageMs, greaterThan(1000));
      expect(report.confusions['C'], <String, int>{'Em': 1});
      expect(report.topConfusions.single.heard, 'Em');
      expect(report.skips, 2);
      final cToG = report.transitions.firstWhere((t) => t.key == 'C>G');
      expect(cToG.fails, 1);
      expect(report.slowestTransitions.first.key, 'C>G');
      engine.dispose();
    });

    test('a restarted session starts a fresh report', () {
      final engine = make(
        PracticePlan.forChords(
          <String>['G'],
          pattern: 'D D D D',
          bpm: 80,
          rounds: 1,
        ),
      );
      engine.start();
      engine.stop();
      expect(engine.snapshot.report, isNotNull);
      engine.start();
      expect(engine.snapshot.report, isNull);
      engine.dispose();
    });
  });
}
