import 'dart:math' as math;
import 'dart:typed_data';

import '../models/audio_frame.dart';
import '../models/strum_event.dart';
import 'fft.dart';

/// Spectral-flux onset detector tuned for strummed guitar.
class OnsetDetector {
  OnsetDetector({
    required int sampleRate,
    this.frameSize = 1024,
    this.hopSize = 512,
    this.minIntervalMs = 90,
    this.sensitivity = 1.6,
  }) : _sampleRate = sampleRate,
       _fft = FFT(frameSize),
       _window = FFT.hann(frameSize);

  final int frameSize;
  final int hopSize;

  /// Two strums closer than this are treated as one.
  final int minIntervalMs;

  /// Threshold multiplier over the running median flux.
  final double sensitivity;

  int _sampleRate;
  FFT _fft;
  Float64List _window;

  final List<double> _buffer = <double>[];
  int _bufferStartMs = 0;
  Float64List? _prevLogMag;
  final List<double> _flux = <double>[];
  final List<int> _fluxTimes = <int>[];
  int _lastOnsetMs = -100000;

  void reset() {
    _buffer.clear();
    _prevLogMag = null;
    _flux.clear();
    _fluxTimes.clear();
    _lastOnsetMs = -100000;
  }

  List<StrumEvent> feed(AudioFrame frame) {
    if (frame.sampleRate != _sampleRate) {
      _sampleRate = frame.sampleRate;
      _fft = FFT(frameSize);
      _window = FFT.hann(frameSize);
      reset();
    }
    if (_buffer.isEmpty) _bufferStartMs = frame.timestampMs;
    _buffer.addAll(frame.samples);

    final events = <StrumEvent>[];
    while (_buffer.length >= frameSize) {
      final chunk = Float32List(frameSize);
      for (var i = 0; i < frameSize; i++) {
        chunk[i] = _buffer[i];
      }
      final frameMs = _bufferStartMs + (frameSize * 500 / _sampleRate).round();
      final onset = _process(chunk, frameMs);
      if (onset != null) events.add(onset);
      _buffer.removeRange(0, hopSize);
      _bufferStartMs += (hopSize * 1000 / _sampleRate).round();
    }
    return events;
  }

  StrumEvent? _process(Float32List chunk, int timestampMs) {
    final mags = _fft.magnitudes(chunk, window: _window);
    final logMag = Float64List(mags.length);
    for (var i = 0; i < mags.length; i++) {
      logMag[i] = math.log(1 + 20 * mags[i]);
    }
    final prev = _prevLogMag;
    _prevLogMag = logMag;
    if (prev == null) return null;

    // half-wave rectified spectral flux
    var flux = 0.0;
    for (var i = 1; i < logMag.length; i++) {
      final d = logMag[i] - prev[i];
      if (d > 0) flux += d;
    }
    _flux.add(flux);
    _fluxTimes.add(timestampMs);
    if (_flux.length > 24) {
      _flux.removeAt(0);
      _fluxTimes.removeAt(0);
    }
    if (_flux.length < 4) return null;

    // peak-pick on the previous frame so we can look one frame ahead
    final n = _flux.length;
    final candidate = _flux[n - 2];
    final isPeak = candidate > _flux[n - 1] && candidate >= _flux[n - 3];
    if (!isPeak) return null;

    final sorted = List<double>.from(_flux)..sort();
    final median = sorted[sorted.length ~/ 2];
    final mean = _flux.reduce((a, b) => a + b) / n;
    final threshold = math.max(median * sensitivity, mean * 1.15) + 0.35;
    if (candidate < threshold) return null;

    final onsetMs = _fluxTimes[n - 2];
    if (onsetMs - _lastOnsetMs < minIntervalMs) return null;
    _lastOnsetMs = onsetMs;
    return StrumEvent(timestampMs: onsetMs, strength: candidate / threshold);
  }
}
