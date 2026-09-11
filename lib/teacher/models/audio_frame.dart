import 'dart:typed_data';

/// A chunk of mono PCM audio in the range -1..1.
class AudioFrame {
  const AudioFrame({
    required this.samples,
    required this.sampleRate,
    required this.timestampMs,
  });

  final Float32List samples;
  final int sampleRate;

  /// Capture time of the *first* sample, in the engine's clock.
  final int timestampMs;

  double get durationMs => samples.length * 1000 / sampleRate;
}
