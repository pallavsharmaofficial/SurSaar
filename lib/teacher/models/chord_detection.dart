/// Result of analysing ~0.2 s of audio.
class ChordDetection {
  const ChordDetection({
    required this.timestampMs,
    required this.chroma,
    required this.rms,
    required this.isSilent,
    required this.scores,
    this.chord,
    this.confidence = 0,
    this.targetChord,
    this.targetScore = 0,
  });

  final int timestampMs;

  /// 12-bin pitch-class energy (C … B), L2-normalised.
  final List<double> chroma;
  final double rms;
  final bool isSilent;

  /// Cosine similarity of every candidate chord.
  final Map<String, double> scores;

  /// Best candidate (null when silent).
  final String? chord;

  /// Margin-based confidence 0..1.
  final double confidence;

  /// The chord the teacher expected, if any, and how well it matched.
  final String? targetChord;
  final double targetScore;

  bool get matchesTarget =>
      !isSilent && targetChord != null && chord == targetChord;

  double get rmsDb => rms <= 0 ? -120 : 20 * _log10(rms);

  static double _log10(double x) => x <= 0 ? -120 : (_ln(x) / _ln10);
  static double _ln(double x) => x <= 0 ? -120 : _naturalLog(x);
  static const double _ln10 = 2.302585092994046;
  static double _naturalLog(double x) {
    // dart:math is avoided here to keep this file dependency-free for tests.
    var result = 0.0;
    var value = x;
    while (value > 2) {
      value /= 2;
      result += 0.6931471805599453;
    }
    while (value < 0.5) {
      value *= 2;
      result -= 0.6931471805599453;
    }
    final t = (value - 1) / (value + 1);
    var term = t;
    var sum = 0.0;
    for (var n = 1; n < 40; n += 2) {
      sum += term / n;
      term *= t * t;
    }
    return result + 2 * sum;
  }
}
