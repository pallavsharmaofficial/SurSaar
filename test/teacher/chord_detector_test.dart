import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sursaar/teacher/analysis/chord_detector.dart';
import 'package:sursaar/teacher/analysis/fft.dart';
import 'package:sursaar/teacher/models/audio_frame.dart';

/// Synthesises a plucked-string-like chord: several notes, each with a few
/// decaying harmonics.
Float32List synthChord(List<double> freqs, int sampleRate, double seconds) {
  final n = (sampleRate * seconds).round();
  final out = Float32List(n);
  for (var i = 0; i < n; i++) {
    final t = i / sampleRate;
    var s = 0.0;
    for (final f in freqs) {
      for (var h = 1; h <= 4; h++) {
        s +=
            math.sin(2 * math.pi * f * h * t) *
            (1 / (h * h)) *
            math.exp(-t * 0.8);
      }
    }
    out[i] = (s / (freqs.length * 1.5)).clamp(-1.0, 1.0);
  }
  return out;
}

List<double> midiToHz(List<int> midi) =>
    midi.map((m) => 440 * math.pow(2, (m - 69) / 12).toDouble()).toList();

void main() {
  test('FFT resolves a pure tone', () {
    const sr = 8000;
    final fft = FFT(1024);
    final frame = Float32List(1024);
    for (var i = 0; i < 1024; i++) {
      frame[i] = math.sin(2 * math.pi * 1000 * i / sr);
    }
    final mags = fft.magnitudes(frame, window: FFT.hann(1024));
    var best = 0;
    for (var i = 1; i < mags.length; i++) {
      if (mags[i] > mags[best]) best = i;
    }
    expect((best * sr / 1024 - 1000).abs(), lessThan(10));
  });

  group('ChordDetector', () {
    const sr = 22050;

    ChordDetector make() => ChordDetector(
      sampleRate: sr,
      candidates: const <String>['G', 'C', 'D', 'Em', 'Am'],
    );

    String? detect(List<int> midi) {
      final detector = make();
      final samples = synthChord(midiToHz(midi), sr, 1.0);
      final results = detector.feed(
        AudioFrame(samples: samples, sampleRate: sr, timestampMs: 0),
      );
      return results.last.chord;
    }

    test('recognises open G major (3 2 0 0 0 3)', () {
      expect(detect(<int>[43, 47, 50, 55, 59, 67]), 'G');
    });

    test('recognises open C major (x 3 2 0 1 0)', () {
      expect(detect(<int>[48, 52, 55, 60, 64]), 'C');
    });

    test('recognises E minor (0 2 2 0 0 0)', () {
      expect(detect(<int>[40, 47, 52, 55, 59, 64]), 'Em');
    });

    test('recognises A minor (x 0 2 2 1 0)', () {
      expect(detect(<int>[45, 52, 57, 60, 64]), 'Am');
    });

    test('silence is reported as silent', () {
      final detector = make();
      final results = detector.feed(
        AudioFrame(samples: Float32List(sr), sampleRate: sr, timestampMs: 0),
      );
      expect(results, isNotEmpty);
      expect(results.every((r) => r.isSilent), isTrue);
    });

    test('target score is reported', () {
      final detector = make()..target = 'G';
      final samples = synthChord(
        midiToHz(<int>[43, 47, 50, 55, 59, 67]),
        sr,
        0.6,
      );
      final results = detector.feed(
        AudioFrame(samples: samples, sampleRate: sr, timestampMs: 0),
      );
      expect(results.last.targetChord, 'G');
      expect(results.last.targetScore, greaterThan(0.7));
      expect(results.last.matchesTarget, isTrue);
    });
  });
}
