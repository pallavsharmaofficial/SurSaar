import 'dart:math' as math;
import 'dart:typed_data';

/// Folds a magnitude spectrum into 12 pitch classes.
///
/// Lower octaves get more weight so the fundamentals of a strummed chord
/// dominate the harmonics; the result is L2-normalised for cosine matching.
class ChromaExtractor {
  ChromaExtractor({
    required this.sampleRate,
    required this.fftSize,
    this.minHz = 70,
    this.maxHz = 2200,
  }) {
    final bins = fftSize ~/ 2;
    _pitchClass = Int8List(bins);
    _weight = Float64List(bins);
    for (var k = 0; k < bins; k++) {
      final hz = k * sampleRate / fftSize;
      if (hz < minHz || hz > maxHz) {
        _pitchClass[k] = -1;
        continue;
      }
      final midi = 69 + 12 * (math.log(hz / 440) / math.ln2);
      final rounded = midi.round();
      final centsOff = (midi - rounded).abs(); // 0..0.5 semitone
      _pitchClass[k] = rounded % 12;
      final octave = ((rounded - 40) / 12).clamp(0, 5); // low E = octave 0
      // Taper by octave and by how far the bin is from the note centre.
      _weight[k] = (1.0 / (1.0 + 0.55 * octave)) * (1.0 - centsOff);
    }
  }

  final int sampleRate;
  final int fftSize;
  final double minHz;
  final double maxHz;

  late final Int8List _pitchClass;
  late final Float64List _weight;

  /// 12-bin chroma (C=0 … B=11), L2-normalised (all zeros for silence).
  List<double> extract(Float64List magnitudes) {
    final chroma = List<double>.filled(12, 0);
    final bins = math.min(magnitudes.length, _pitchClass.length);
    for (var k = 0; k < bins; k++) {
      final pc = _pitchClass[k];
      if (pc < 0) continue;
      final m = magnitudes[k];
      // log compression flattens the loud/quiet string imbalance
      chroma[pc] += math.log(1 + 8 * m) * _weight[k];
    }
    return normalize(chroma);
  }

  static List<double> normalize(List<double> v) {
    var sum = 0.0;
    for (final x in v) {
      sum += x * x;
    }
    if (sum <= 1e-12) return List<double>.filled(v.length, 0);
    final norm = math.sqrt(sum);
    return v.map((x) => x / norm).toList(growable: false);
  }

  static double cosine(List<double> a, List<double> b) {
    var dot = 0.0, na = 0.0, nb = 0.0;
    for (var i = 0; i < a.length && i < b.length; i++) {
      dot += a[i] * b[i];
      na += a[i] * a[i];
      nb += b[i] * b[i];
    }
    if (na <= 1e-12 || nb <= 1e-12) return 0;
    return dot / (math.sqrt(na) * math.sqrt(nb));
  }
}
