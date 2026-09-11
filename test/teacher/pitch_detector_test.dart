import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sursaar/teacher/analysis/pitch_detector.dart';
import 'package:sursaar/teacher/analysis/tuner.dart';
import 'package:sursaar/teacher/models/audio_frame.dart';

Float32List pluckedTone(
  double hz,
  int sampleRate,
  double seconds, {
  List<double> harmonics = const <double>[1, 0.6, 0.35, 0.2],
}) {
  final n = (sampleRate * seconds).round();
  final out = Float32List(n);
  for (var i = 0; i < n; i++) {
    final t = i / sampleRate;
    var s = 0.0;
    for (var h = 0; h < harmonics.length; h++) {
      s += harmonics[h] * math.sin(2 * math.pi * hz * (h + 1) * t);
    }
    out[i] = (0.4 * s / harmonics.length) * math.exp(-t * 1.2);
  }
  return out;
}

void main() {
  for (final rate in const <int>[48000, 22050]) {
    group('PitchDetector @ $rate Hz', () {
      final detector = PitchDetector(sampleRate: rate);

      for (final string in Tuner.standard) {
        test('detects the open ${string.label} string', () {
          final tone = pluckedTone(string.frequency, rate, 0.4);
          final estimate = detector.estimate(tone);
          expect(estimate, isNotNull);
          expect(
            centsBetween(estimate!.frequency, string.frequency).abs(),
            lessThan(3),
          );
          expect(estimate.clarity, greaterThan(0.8));
        });
      }

      test('does not jump an octave when the 2nd harmonic dominates', () {
        final tone = pluckedTone(
          82.41,
          rate,
          0.4,
          harmonics: const <double>[0.45, 1, 0.6, 0.3],
        );
        final estimate = detector.estimate(tone)!;
        expect(centsBetween(estimate.frequency, 82.41).abs(), lessThan(5));
      });

      test('reports silence as no pitch', () {
        expect(detector.estimate(Float32List(detector.frameSize)), isNull);
      });
    });
  }

  group('Tuner', () {
    test('finds the nearest string and how far off it is', () {
      final sharpA = 110 * math.pow(2, 15 / 1200).toDouble();
      final reading = Tuner.reading(sharpA);
      expect(reading.string.label, 'A');
      expect(reading.centsFromString, closeTo(15, 0.5));
      expect(reading.isSharp, isTrue);
      expect(reading.noteName, 'A');
      expect(reading.octave, 2);
    });

    test('a flat high e asks to tune up', () {
      final reading = Tuner.reading(329.63 * math.pow(2, -20 / 1200));
      expect(reading.string.label, 'High e');
      expect(reading.isFlat, isTrue);
      expect(reading.inTune, isFalse);
    });

    test('locking to a string measures against it', () {
      final reading = Tuner.reading(130, lockTo: Tuner.standard[2]);
      expect(reading.string.label, 'D');
      expect(reading.centsFromString, lessThan(-100));
    });
  });

  test('PitchTracker streams chunks into smoothed readings', () {
    const rate = 48000;
    final tracker = PitchTracker();
    final tone = pluckedTone(196.0, rate, 1.0);
    final readings = <TunerReading>[];
    for (var start = 0; start + 2048 <= tone.length; start += 2048) {
      readings.addAll(
        tracker.feed(
          AudioFrame(
            samples: Float32List.sublistView(tone, start, start + 2048),
            sampleRate: rate,
            timestampMs: 0,
          ),
        ),
      );
    }
    expect(readings, isNotEmpty);
    expect(tracker.lastReading!.string.label, 'G');
    expect(tracker.lastReading!.inTune, isTrue);
  });
}
