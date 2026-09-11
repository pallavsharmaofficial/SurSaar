import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'chord_voicing.g.dart';

/// Standard tuning as MIDI note numbers, low E (index 0) to high e (index 5).
const List<int> kStandardTuningMidi = <int>[40, 45, 50, 55, 59, 64];

const List<String> kNoteNames = <String>[
  'C',
  'C#',
  'D',
  'D#',
  'E',
  'F',
  'F#',
  'G',
  'G#',
  'A',
  'A#',
  'B',
];

/// A barre across several strings at one fret.
@JsonSerializable()
class Barre extends Equatable {
  const Barre({
    required this.fret,
    required this.startString,
    required this.endString,
    this.finger = 1,
  });

  factory Barre.fromJson(Map<String, dynamic> json) => _$BarreFromJson(json);

  /// Absolute fret number.
  final int fret;

  /// First string covered (0 = low E).
  final int startString;

  /// Last string covered (5 = high e).
  final int endString;

  /// Finger used (1 = index ... 4 = pinky).
  final int finger;

  Map<String, dynamic> toJson() => _$BarreToJson(this);

  @override
  List<Object?> get props => <Object?>[fret, startString, endString, finger];
}

/// One way of playing a chord on the fretboard.
///
/// String order is always low E → high e. `frets[i]` is the absolute fret
/// number pressed on string `i`; `0` = open, `-1` = muted.
/// `fingers[i]` is the finger used (0 none, 1 index, 2 middle, 3 ring,
/// 4 pinky, 5 thumb).
@JsonSerializable(explicitToJson: true)
class ChordVoicing extends Equatable {
  const ChordVoicing({
    required this.name,
    required this.frets,
    this.fingers = const <int>[0, 0, 0, 0, 0, 0],
    this.baseFret = 1,
    this.barres = const <Barre>[],
    this.label,
  });

  factory ChordVoicing.fromJson(Map<String, dynamic> json) =>
      _$ChordVoicingFromJson(json);

  final String name;
  final List<int> frets;
  final List<int> fingers;

  /// The fret shown at the top of a diagram (1 for open-position shapes).
  final int baseFret;
  final List<Barre> barres;

  /// Human label such as "open" or "E-shape barre".
  final String? label;

  Map<String, dynamic> toJson() => _$ChordVoicingToJson(this);

  /// Highest fret used by the voicing (0 if only open strings).
  int get maxFret => frets.fold<int>(0, (max, f) => f > max ? f : max);

  /// Lowest fretted (non-open, non-muted) fret, or 0.
  int get minFrettedFret {
    var min = 0;
    for (final f in frets) {
      if (f > 0 && (min == 0 || f < min)) min = f;
    }
    return min;
  }

  bool get isOpenPosition => maxFret <= 4;

  /// Fingers (1-4) that press a string in this voicing.
  Set<int> get usedFingers => fingers.where((f) => f >= 1 && f <= 4).toSet();

  /// MIDI note numbers sounding in this voicing (muted strings skipped).
  List<int> get midiNotes {
    final notes = <int>[];
    for (var i = 0; i < 6; i++) {
      final f = frets[i];
      if (f < 0) continue;
      notes.add(kStandardTuningMidi[i] + f);
    }
    return notes;
  }

  /// Pitch classes (0 = C … 11 = B) present in this voicing.
  Set<int> get pitchClasses => midiNotes.map((n) => n % 12).toSet();

  /// A copy with every fretted note moved by [semitones]. Only valid for
  /// shapes without open strings (barre shapes).
  ChordVoicing transposed(int semitones, {required String newName}) {
    final newFrets = frets
        .map((f) => f <= 0 ? f : f + semitones)
        .toList(growable: false);
    final newBarres = barres
        .map(
          (b) => Barre(
            fret: b.fret + semitones,
            startString: b.startString,
            endString: b.endString,
            finger: b.finger,
          ),
        )
        .toList(growable: false);
    return ChordVoicing(
      name: newName,
      frets: newFrets,
      fingers: fingers,
      baseFret: baseFret + semitones,
      barres: newBarres,
      label: label,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    name,
    frets,
    fingers,
    baseFret,
    barres,
    label,
  ];
}
