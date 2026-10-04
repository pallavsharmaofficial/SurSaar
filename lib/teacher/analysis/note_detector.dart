import 'dart:typed_data';

import '../melody/melody_tab.dart';
import '../models/audio_frame.dart';
import 'pitch_detector.dart';

/// One single-note estimate from the microphone.
class NoteDetection {
  const NoteDetection({
    required this.timestampMs,
    required this.isSilent,
    this.frequency = 0,
    this.midi = 0,
    this.cents = 0,
    this.clarity = 0,
  });

  final int timestampMs;
  final bool isSilent;
  final double frequency;

  /// Nearest MIDI note.
  final int midi;

  /// Offset from [midi]; negative = flat, positive = sharp.
  final double cents;
  final double clarity;

  String get noteName => NoteName.of(midi);

  /// Signed semitones from [targetMidi] (fractional).
  double semitonesFrom(int targetMidi) => midi + cents / 100 - targetMidi;
}

/// Streams [NoteDetection]s from PCM using the YIN [PitchDetector].
///
/// Audio is decimated to ≈ 24 kHz first (guitar melody notes stay well under
/// 1.2 kHz), which makes YIN about four times cheaper on 48 kHz input. A
/// 3-estimate median removes single-frame octave slips.
class NoteDetector {
  NoteDetector({required int sampleRate, this.hopMs = 30})
    : _decimation = sampleRate > 32000 ? 2 : 1,
      _detector = PitchDetector(
        sampleRate: sampleRate > 32000 ? sampleRate ~/ 2 : sampleRate,
        minHz: 75,
        maxHz: 1400,
      );

  final int hopMs;
  final int _decimation;
  final PitchDetector _detector;
  final List<double> _buffer = <double>[];
  final List<double> _recentMidi = <double>[];
  int _bufferStartMs = 0;
  bool _hasStart = false;
  double _carry = 0;
  int _carryCount = 0;

  int get _rate => _detector.sampleRate;

  int get _hopSamples => (_rate * hopMs / 1000).round();

  void reset() {
    _buffer.clear();
    _recentMidi.clear();
    _hasStart = false;
    _carry = 0;
    _carryCount = 0;
  }

  List<NoteDetection> feed(AudioFrame frame) {
    if (!_hasStart) {
      _bufferStartMs = frame.timestampMs;
      _hasStart = true;
    }
    _append(frame.samples);
    final results = <NoteDetection>[];
    final needed = _detector.frameSize;
    while (_buffer.length >= needed) {
      final endMs = _bufferStartMs + (needed * 1000 / _rate).round();
      final estimate = _detector.estimate(_buffer);
      results.add(_toDetection(estimate, endMs));
      final hop = _hopSamples;
      _buffer.removeRange(0, hop);
      _bufferStartMs += (hop * 1000 / _rate).round();
    }
    return results;
  }

  void _append(Float32List samples) {
    if (_decimation == 1) {
      _buffer.addAll(samples);
      return;
    }
    for (final s in samples) {
      _carry += s;
      _carryCount++;
      if (_carryCount == _decimation) {
        _buffer.add(_carry / _decimation);
        _carry = 0;
        _carryCount = 0;
      }
    }
  }

  NoteDetection _toDetection(PitchEstimate? estimate, int timestampMs) {
    if (estimate == null || estimate.clarity < 0.6) {
      _recentMidi.clear();
      return NoteDetection(timestampMs: timestampMs, isSilent: true);
    }
    _recentMidi.add(NoteName.midiOf(estimate.frequency));
    if (_recentMidi.length > 3) _recentMidi.removeAt(0);
    final sorted = List<double>.of(_recentMidi)..sort();
    final median = sorted[sorted.length ~/ 2];
    final nearest = median.round();
    return NoteDetection(
      timestampMs: timestampMs,
      isSilent: false,
      frequency: estimate.frequency,
      midi: nearest,
      cents: (median - nearest) * 100,
      clarity: estimate.clarity,
    );
  }
}
