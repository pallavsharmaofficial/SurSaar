import 'dart:math' as math;

import '../../models/chord_voicing.dart';
import '../models/audio_frame.dart';
import 'pitch_detector.dart';

double midiToHz(num midi) => 440.0 * math.pow(2, (midi - 69) / 12);

double centsBetween(double hz, double referenceHz) =>
    1200 * (math.log(hz / referenceHz) / math.ln2);

/// An open string in standard tuning.
class GuitarString {
  const GuitarString(this.index, this.name, this.midi, this.label);

  /// 0 = low E … 5 = high e.
  final int index;
  final String name;
  final int midi;
  final String label;

  double get frequency => midiToHz(midi);
}

/// What the tuner shows for one estimate.
class TunerReading {
  const TunerReading({
    required this.frequency,
    required this.noteName,
    required this.octave,
    required this.centsFromNote,
    required this.string,
    required this.centsFromString,
    required this.clarity,
  });

  final double frequency;
  final String noteName;
  final int octave;
  final double centsFromNote;
  final GuitarString string;

  /// Negative = flat (tune up), positive = sharp (tune down).
  final double centsFromString;
  final double clarity;

  static const double inTuneCents = 5;

  bool get inTune => centsFromString.abs() <= inTuneCents;

  bool get isFlat => centsFromString < -inTuneCents;

  bool get isSharp => centsFromString > inTuneCents;
}

class Tuner {
  const Tuner._();

  static const List<GuitarString> standard = <GuitarString>[
    GuitarString(0, 'E2', 40, 'Low E'),
    GuitarString(1, 'A2', 45, 'A'),
    GuitarString(2, 'D3', 50, 'D'),
    GuitarString(3, 'G3', 55, 'G'),
    GuitarString(4, 'B3', 59, 'B'),
    GuitarString(5, 'E4', 64, 'High e'),
  ];

  /// Interprets [frequency]; the target string is [lockTo] or the nearest one.
  static TunerReading reading(
    double frequency, {
    double clarity = 1,
    GuitarString? lockTo,
  }) {
    final midi = 69 + 12 * (math.log(frequency / 440) / math.ln2);
    final nearest = midi.round();
    final string =
        lockTo ??
        standard.reduce(
          (a, b) =>
              centsBetween(frequency, a.frequency).abs() <=
                  centsBetween(frequency, b.frequency).abs()
              ? a
              : b,
        );
    return TunerReading(
      frequency: frequency,
      noteName: kNoteNames[((nearest % 12) + 12) % 12],
      octave: nearest ~/ 12 - 1,
      centsFromNote: (midi - nearest) * 100,
      string: string,
      centsFromString: centsBetween(frequency, string.frequency),
      clarity: clarity,
    );
  }
}

/// Feeds streaming audio into a [PitchDetector] and smooths the readings.
class PitchTracker {
  PitchTracker({this.historySize = 5});

  final int historySize;
  PitchDetector? _detector;
  final List<double> _buffer = <double>[];
  final List<double> _recent = <double>[];
  int _silentEstimates = 0;

  TunerReading? lastReading;

  /// Latest smoothed readings produced by [frame] (may be empty).
  List<TunerReading> feed(AudioFrame frame, {GuitarString? lockTo}) {
    var detector = _detector;
    if (detector == null || detector.sampleRate != frame.sampleRate) {
      detector = _detector = PitchDetector(sampleRate: frame.sampleRate);
      _buffer.clear();
      _recent.clear();
    }
    _buffer.addAll(frame.samples);
    final hop = math.max(512, frame.sampleRate ~/ 20);
    final readings = <TunerReading>[];
    while (_buffer.length >= detector.frameSize) {
      final estimate = detector.estimate(_buffer);
      _buffer.removeRange(0, math.min(hop, _buffer.length));
      if (estimate == null || estimate.clarity < 0.75) {
        if (++_silentEstimates > 6) {
          _recent.clear();
          lastReading = null;
        }
        continue;
      }
      _silentEstimates = 0;
      // Restart smoothing when the note changes by more than a semitone.
      if (_recent.isNotEmpty &&
          centsBetween(estimate.frequency, _recent.last).abs() > 100) {
        _recent.clear();
      }
      _recent.add(estimate.frequency);
      if (_recent.length > historySize) _recent.removeAt(0);
      final sorted = List<double>.of(_recent)..sort();
      final median = sorted[sorted.length ~/ 2];
      final reading = Tuner.reading(
        median,
        clarity: estimate.clarity,
        lockTo: lockTo,
      );
      lastReading = reading;
      readings.add(reading);
    }
    // Keep the buffer bounded if audio arrives faster than it is analysed.
    if (_buffer.length > detector.frameSize * 3) {
      _buffer.removeRange(0, _buffer.length - detector.frameSize * 2);
    }
    return readings;
  }

  void reset() {
    _buffer.clear();
    _recent.clear();
    _silentEstimates = 0;
    lastReading = null;
  }
}
