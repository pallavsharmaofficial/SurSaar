import 'dart:math' as math;
import 'dart:typed_data';

/// One pitch estimate.
class PitchEstimate {
  const PitchEstimate({
    required this.frequency,
    required this.clarity,
    required this.rms,
  });

  /// Fundamental frequency in Hz.
  final double frequency;

  /// 0..1, how periodic the signal is (1 = perfectly periodic).
  final double clarity;

  final double rms;
}

/// YIN pitch detector tuned for a guitar (low E ≈ 82 Hz up to ≈ 1.2 kHz).
///
/// Pure Dart so it runs identically on web and mobile and is unit-tested
/// with synthetic plucked tones.
class PitchDetector {
  PitchDetector({
    required this.sampleRate,
    this.minHz = 70,
    this.maxHz = 1200,
    this.threshold = 0.15,
    this.silenceRms = 0.004,
  }) : windowSize = (sampleRate / minHz * 2).ceil();

  final int sampleRate;
  final double minHz;
  final double maxHz;
  final double threshold;
  final double silenceRms;

  /// Analysis window: two periods of the lowest detectable note.
  final int windowSize;

  int get tauMax => (sampleRate / minHz).ceil();

  int get tauMin => math.max(2, (sampleRate / maxHz).floor());

  /// Samples needed for one estimate.
  int get frameSize => windowSize + tauMax + 2;

  PitchEstimate? estimate(List<double> samples, [int offset = 0]) {
    if (samples.length - offset < frameSize) return null;

    var energy = 0.0;
    for (var i = 0; i < windowSize; i++) {
      final s = samples[offset + i];
      energy += s * s;
    }
    final rms = math.sqrt(energy / windowSize);
    if (rms < silenceRms) return null;

    final maxTau = tauMax;
    final difference = Float64List(maxTau + 1);
    for (var tau = 1; tau <= maxTau; tau++) {
      var acc = 0.0;
      for (var i = 0; i < windowSize; i++) {
        final delta = samples[offset + i] - samples[offset + i + tau];
        acc += delta * delta;
      }
      difference[tau] = acc;
    }

    // Cumulative mean normalised difference.
    final cmnd = Float64List(maxTau + 1)..[0] = 1;
    var running = 0.0;
    for (var tau = 1; tau <= maxTau; tau++) {
      running += difference[tau];
      cmnd[tau] = running == 0 ? 1 : difference[tau] * tau / running;
    }

    var tauEstimate = -1;
    for (var tau = tauMin; tau <= maxTau; tau++) {
      if (cmnd[tau] < threshold) {
        while (tau + 1 <= maxTau && cmnd[tau + 1] < cmnd[tau]) {
          tau++;
        }
        tauEstimate = tau;
        break;
      }
    }
    if (tauEstimate == -1) {
      var best = tauMin;
      for (var tau = tauMin; tau <= maxTau; tau++) {
        if (cmnd[tau] < cmnd[best]) best = tau;
      }
      if (cmnd[best] > 0.35) return null;
      tauEstimate = best;
    }

    var refined = tauEstimate.toDouble();
    if (tauEstimate > 1 && tauEstimate < maxTau) {
      final s0 = cmnd[tauEstimate - 1];
      final s1 = cmnd[tauEstimate];
      final s2 = cmnd[tauEstimate + 1];
      final denominator = 2 * (2 * s1 - s2 - s0);
      if (denominator.abs() > 1e-12) {
        refined = tauEstimate + (s2 - s0) / denominator;
      }
    }
    final frequency = sampleRate / refined;
    if (frequency < minHz || frequency > maxHz) return null;
    return PitchEstimate(
      frequency: frequency,
      clarity: (1 - cmnd[tauEstimate]).clamp(0.0, 1.0),
      rms: rms,
    );
  }
}
