import 'dart:math' as math;
import 'dart:typed_data';

import '../../data/content/chord_library.dart';
import '../models/audio_frame.dart';
import '../models/chord_detection.dart';
import 'chord_templates.dart';
import 'chroma.dart';
import 'fft.dart';

/// Real-time chord recogniser: chroma + template matching with temporal
/// smoothing. Pure Dart, runs comfortably at ~10 detections/second.
class ChordDetector {
  ChordDetector({
    required int sampleRate,
    List<String> candidates = const <String>[],
    this.frameSeconds = 0.18,
    this.hopSeconds = 0.1,
    this.silenceDb = -50,
    this.smoothing = 0.45,
  }) {
    _configure(sampleRate);
    setCandidates(candidates);
  }

  final double frameSeconds;
  final double hopSeconds;

  /// RMS below this (dBFS) is treated as silence.
  final double silenceDb;

  /// EMA factor applied to new chroma frames (higher = more responsive).
  final double smoothing;

  late int _sampleRate;
  late int _frameSize;
  late int _hop;
  late FFT _fft;
  late Float64List _window;
  late ChromaExtractor _chroma;

  final List<double> _buffer = <double>[];
  int _bufferStartMs = 0;
  List<double>? _smoothed;
  final Map<String, List<double>> _templates = <String, List<double>>{};
  final List<String?> _history = <String?>[];
  String? _target;

  int get sampleRate => _sampleRate;
  int get frameSize => _frameSize;

  void _configure(int sampleRate) {
    _sampleRate = sampleRate;
    final wanted = sampleRate * frameSeconds;
    var size = 1;
    while (size < wanted) {
      size <<= 1;
    }
    // choose the closer power of two
    if ((size - wanted).abs() > (wanted - size / 2).abs() && size > 1024) {
      size >>= 1;
    }
    _frameSize = size;
    _hop = math.max(256, (sampleRate * hopSeconds).round());
    _fft = FFT(_frameSize);
    _window = FFT.hann(_frameSize);
    _chroma = ChromaExtractor(sampleRate: sampleRate, fftSize: _frameSize);
    _buffer.clear();
    _smoothed = null;
  }

  /// Chords to choose between. The 24 triads are always included so that a
  /// wrong chord can be named ("that sounds like Em").
  void setCandidates(List<String> candidates) {
    _templates.clear();
    for (final name in <String>[...candidates, ...ChordTemplates.triads]) {
      final normalized = ChordLibrary.normalizeName(name);
      if (_templates.containsKey(normalized)) continue;
      final template = ChordTemplates.templateFor(normalized);
      if (template != null) _templates[normalized] = template;
    }
  }

  /// The chord the teacher currently expects (for [ChordDetection.targetScore]).
  set target(String? chord) =>
      _target = chord == null ? null : ChordLibrary.normalizeName(chord);

  void reset() {
    _buffer.clear();
    _smoothed = null;
    _history.clear();
  }

  /// Feeds audio; returns a detection for every completed hop.
  List<ChordDetection> feed(AudioFrame frame) {
    if (frame.sampleRate != _sampleRate) _configure(frame.sampleRate);
    if (_buffer.isEmpty) _bufferStartMs = frame.timestampMs;
    _buffer.addAll(frame.samples);

    final results = <ChordDetection>[];
    while (_buffer.length >= _frameSize) {
      final chunk = Float32List(_frameSize);
      var sumSq = 0.0;
      for (var i = 0; i < _frameSize; i++) {
        final s = _buffer[i];
        chunk[i] = s;
        sumSq += s * s;
      }
      final rms = math.sqrt(sumSq / _frameSize);
      final frameEndMs =
          _bufferStartMs + (_frameSize * 1000 / _sampleRate).round();
      results.add(_analyse(chunk, rms, frameEndMs));
      _buffer.removeRange(0, _hop);
      _bufferStartMs += (_hop * 1000 / _sampleRate).round();
    }
    return results;
  }

  ChordDetection _analyse(Float32List chunk, double rms, int timestampMs) {
    final rmsDb = rms <= 0 ? -120.0 : 20 * math.log(rms) / math.ln10;
    final isSilent = rmsDb < silenceDb;
    if (isSilent) {
      _history.add(null);
      if (_history.length > 6) _history.removeAt(0);
      return ChordDetection(
        timestampMs: timestampMs,
        chroma: _smoothed ?? List<double>.filled(12, 0),
        rms: rms,
        isSilent: true,
        scores: const <String, double>{},
        targetChord: _target,
      );
    }

    final mags = _fft.magnitudes(chunk, window: _window);
    final chroma = _chroma.extract(mags);
    final prev = _smoothed;
    final smoothed = prev == null
        ? chroma
        : ChromaExtractor.normalize(<double>[
            for (var i = 0; i < 12; i++)
              smoothing * chroma[i] + (1 - smoothing) * prev[i],
          ]);
    _smoothed = smoothed;

    final scores = <String, double>{};
    String? best;
    var bestScore = -1.0;
    var second = -1.0;
    for (final entry in _templates.entries) {
      final s = ChromaExtractor.cosine(smoothed, entry.value);
      scores[entry.key] = s;
      if (s > bestScore) {
        second = bestScore;
        bestScore = s;
        best = entry.key;
      } else if (s > second) {
        second = s;
      }
    }

    // Majority vote over the last few frames removes flicker on transitions.
    _history.add(best);
    if (_history.length > 5) _history.removeAt(0);
    final votes = <String, int>{};
    for (final h in _history) {
      if (h != null) votes[h] = (votes[h] ?? 0) + 1;
    }
    String? stable = best;
    var maxVotes = 0;
    votes.forEach((chord, count) {
      if (count > maxVotes) {
        maxVotes = count;
        stable = chord;
      }
    });

    final margin = (bestScore - second).clamp(0.0, 0.3) / 0.3;
    final confidence = (0.5 * margin + 0.5 * bestScore).clamp(0.0, 1.0);

    return ChordDetection(
      timestampMs: timestampMs,
      chroma: smoothed,
      rms: rms,
      isSilent: false,
      scores: scores,
      chord: stable,
      confidence: confidence,
      targetChord: _target,
      targetScore: _target == null ? 0 : (scores[_target!] ?? 0),
    );
  }
}
