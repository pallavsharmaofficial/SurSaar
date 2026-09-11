import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sursaar/models/strumming_pattern.dart';
import 'package:sursaar/teacher/analysis/onset_detector.dart';
import 'package:sursaar/teacher/analysis/timing_scorer.dart';
import 'package:sursaar/teacher/models/audio_frame.dart';
import 'package:sursaar/teacher/models/strum_event.dart';

Float32List strumsAt(List<int> onsetsMs, int sampleRate, int totalMs) {
  final n = sampleRate * totalMs ~/ 1000;
  final out = Float32List(n);
  final rng = math.Random(7);
  for (final onset in onsetsMs) {
    final start = sampleRate * onset ~/ 1000;
    for (var i = 0; i < sampleRate ~/ 4 && start + i < n; i++) {
      final t = i / sampleRate;
      final env = math.exp(-t * 14);
      var s = 0.0;
      for (final f in <double>[98, 123, 147, 196, 247, 294]) {
        s += math.sin(2 * math.pi * f * t + rng.nextDouble());
      }
      out[start + i] += (s / 8) * env;
    }
  }
  return out;
}

void main() {
  test('OnsetDetector finds four strums in two seconds', () {
    const sr = 16000;
    final detector = OnsetDetector(sampleRate: sr);
    final samples = strumsAt(<int>[200, 700, 1200, 1700], sr, 2200);
    final events = detector.feed(
      AudioFrame(samples: samples, sampleRate: sr, timestampMs: 0),
    );
    expect(events.length, 4);
    final times = events.map((e) => e.timestampMs).toList();
    for (var i = 0; i < 4; i++) {
      expect((times[i] - <int>[200, 700, 1200, 1700][i]).abs(), lessThan(70));
    }
  });

  group('TimingScorer', () {
    late TimingScorer scorer;

    setUp(() {
      scorer = TimingScorer(
        pattern: StrummingPattern.parse('D - D U - U D U'),
        bpm: 120, // beat 500 ms, slot 250 ms
      );
    });

    test('on-time strums are hits', () {
      final r = scorer.onStrum(
        const StrumEvent(timestampMs: 0, strength: 1),
        20,
      );
      expect(r.result, TimingResult.hit);
      expect(scorer.hits, 1);
    });

    test('late strums are flagged', () {
      final downs = TimingScorer(
        pattern: StrummingPattern.parse('D - D - D - D -'),
        bpm: 120,
      );
      final r = downs.onStrum(
        const StrumEvent(timestampMs: 0, strength: 1),
        660,
      );
      // slot 2 expected at 500 ms -> 160 ms late; slot 4 (1000 ms) is too far
      expect(r.result, TimingResult.late);
      expect(r.absoluteSlot, 2);
    });

    test('the nearest sounding slot wins', () {
      final r = scorer.onStrum(
        const StrumEvent(timestampMs: 0, strength: 1),
        660,
      );
      // slot 3 (up-stroke at 750 ms) is closer than slot 2 (500 ms)
      expect(r.result, TimingResult.hit);
      expect(r.absoluteSlot, 3);
    });

    test('missed slots are collected once time passes', () {
      final missed = scorer.collectMisses(2000);
      // slots 0,2,3,5,6,7 sound in the first bar (6 strokes)
      expect(missed.length, 6);
      expect(scorer.misses, 6);
    });

    test('strums on rests count as extras', () {
      final r = scorer.onStrum(
        const StrumEvent(timestampMs: 0, strength: 1),
        1000,
      );
      // slot 4 is a rest; nearest sounding slots (3 @750, 5 @1250) are > 2x tolerance away
      expect(r.result, TimingResult.extra);
    });
  });
}
