import 'dart:math' as math;
import 'dart:typed_data';

import 'package:sursaar/teacher/models/audio_frame.dart';

const List<int> gMajor = <int>[43, 47, 50, 55, 59, 67];
const List<int> cMajor = <int>[48, 52, 55, 60, 64];
const List<int> eMinor = <int>[40, 47, 52, 55, 59, 64];

/// A strummed-chord-like signal: each note with a few decaying harmonics.
Float32List synthChord(List<int> midi, int sampleRate, double seconds) {
  final n = (sampleRate * seconds).round();
  final out = Float32List(n);
  final freqs = midi
      .map((m) => 440 * math.pow(2, (m - 69) / 12).toDouble())
      .toList();
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

/// Silence followed by a chord, so an onset (a new strum) is detectable.
Float32List strum(List<int> midi, int sampleRate, double seconds) {
  final silence = (sampleRate * 0.3).round();
  final chord = synthChord(midi, sampleRate, seconds);
  return Float32List(silence + chord.length)..setAll(silence, chord);
}

List<AudioFrame> chunks(
  Float32List samples,
  int sampleRate, {
  int size = 2048,
  int startMs = 0,
}) {
  final frames = <AudioFrame>[];
  for (var start = 0; start < samples.length; start += size) {
    final end = math.min(samples.length, start + size);
    frames.add(
      AudioFrame(
        samples: Float32List.sublistView(samples, start, end),
        sampleRate: sampleRate,
        timestampMs: startMs + (start * 1000 / sampleRate).round(),
      ),
    );
  }
  return frames;
}
