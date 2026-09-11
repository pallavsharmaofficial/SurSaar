import 'dart:math' as math;
import 'dart:typed_data';

/// Iterative radix-2 real-input FFT with cached twiddles.
class FFT {
  FFT(this.size)
    : assert(size > 0 && (size & (size - 1)) == 0, 'size must be 2^n'),
      _cos = Float64List(size ~/ 2),
      _sin = Float64List(size ~/ 2),
      _rev = Int32List(size) {
    for (var i = 0; i < size ~/ 2; i++) {
      final angle = -2 * math.pi * i / size;
      _cos[i] = math.cos(angle);
      _sin[i] = math.sin(angle);
    }
    final bits = _log2(size);
    for (var i = 0; i < size; i++) {
      var r = 0;
      var v = i;
      for (var b = 0; b < bits; b++) {
        r = (r << 1) | (v & 1);
        v >>= 1;
      }
      _rev[i] = r;
    }
  }

  final int size;
  final Float64List _cos;
  final Float64List _sin;
  final Int32List _rev;

  static int _log2(int n) {
    var bits = 0;
    while ((1 << bits) < n) {
      bits++;
    }
    return bits;
  }

  /// Hann window of [size].
  static Float64List hann(int size) {
    final w = Float64List(size);
    for (var i = 0; i < size; i++) {
      w[i] = 0.5 - 0.5 * math.cos(2 * math.pi * i / (size - 1));
    }
    return w;
  }

  /// In-place complex FFT.
  void transform(Float64List re, Float64List im) {
    final n = size;
    for (var i = 0; i < n; i++) {
      final j = _rev[i];
      if (j > i) {
        final tr = re[i];
        re[i] = re[j];
        re[j] = tr;
        final ti = im[i];
        im[i] = im[j];
        im[j] = ti;
      }
    }
    for (var len = 2; len <= n; len <<= 1) {
      final half = len >> 1;
      final step = n ~/ len;
      for (var i = 0; i < n; i += len) {
        var k = 0;
        for (var j = 0; j < half; j++) {
          final c = _cos[k];
          final s = _sin[k];
          final a = i + j;
          final b = a + half;
          final xr = re[b] * c - im[b] * s;
          final xi = re[b] * s + im[b] * c;
          re[b] = re[a] - xr;
          im[b] = im[a] - xi;
          re[a] += xr;
          im[a] += xi;
          k += step;
        }
      }
    }
  }

  /// Magnitude spectrum (size/2 bins) of a real frame, optionally windowed.
  Float64List magnitudes(Float32List frame, {Float64List? window}) {
    final re = Float64List(size);
    final im = Float64List(size);
    final n = math.min(frame.length, size);
    for (var i = 0; i < n; i++) {
      re[i] = window == null ? frame[i] : frame[i] * window[i];
    }
    transform(re, im);
    final out = Float64List(size ~/ 2);
    for (var i = 0; i < size ~/ 2; i++) {
      out[i] = math.sqrt(re[i] * re[i] + im[i] * im[i]);
    }
    return out;
  }
}
