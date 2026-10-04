import 'dart:math' as math;

import '../../models/chord_voicing.dart';

/// One plucked note of a single-note tab.
class TabNote {
  const TabNote({
    required this.string,
    required this.fret,
    this.beats = 1,
    this.section = '',
  });

  /// 0 = low E … 5 = high e (same order as [ChordVoicing.frets]).
  final int string;
  final int fret;

  /// How long the note lasts, in beats.
  final double beats;
  final String section;

  static const List<String> stringNames = <String>[
    'E',
    'A',
    'D',
    'G',
    'B',
    'e',
  ];

  static const String _tokenPrefix = 'n:';

  /// MIDI pitch in standard tuning (no capo).
  int get midi => kStandardTuningMidi[string] + fret;

  /// Practice-plan target id, e.g. `n:4:3` (B string, 3rd fret).
  String get token => '$_tokenPrefix$string:$fret';

  String get stringName => stringNames[string];

  /// "D4".
  String get noteName => NoteName.of(midi);

  /// "B3" – string then fret, the way single-string tabs are read aloud.
  String get shortLabel => '$stringName$fret';

  /// "B string · 3rd fret".
  String get placement => fret == 0
      ? '$stringName string · open'
      : '$stringName string · ${ordinal(fret)} fret';

  /// Whether [target] is a note token rather than a chord name.
  static bool isToken(String? target) =>
      target != null && target.startsWith(_tokenPrefix);

  static TabNote? fromToken(String? token) {
    if (!isToken(token)) return null;
    final parts = token!.substring(_tokenPrefix.length).split(':');
    if (parts.length != 2) return null;
    final string = int.tryParse(parts[0]);
    final fret = int.tryParse(parts[1]);
    if (string == null || fret == null || string < 0 || string > 5) {
      return null;
    }
    return TabNote(string: string, fret: fret);
  }

  /// Short text for a target that may be a chord or a note token.
  static String display(String target) =>
      fromToken(target)?.shortLabel ?? target;

  static String ordinal(int n) {
    if (n % 100 >= 11 && n % 100 <= 13) return '${n}th';
    switch (n % 10) {
      case 1:
        return '${n}st';
      case 2:
        return '${n}nd';
      case 3:
        return '${n}rd';
      default:
        return '${n}th';
    }
  }

  /// A one-dot "chord" so diagrams and the camera overlay can show where the
  /// finger goes. [boxStart] is the lowest fret of the phrase, so the learner
  /// keeps one finger per fret.
  ChordVoicing voicing({int boxStart = 1}) {
    final frets = List<int>.filled(6, -1);
    final fingers = List<int>.filled(6, 0);
    frets[string] = fret;
    if (fret > 0) {
      fingers[string] = (fret - math.max(1, boxStart) + 1).clamp(1, 4).toInt();
    }
    final base = fret <= 4 ? 1 : fret - 1;
    return ChordVoicing(
      name: shortLabel,
      frets: frets,
      fingers: fingers,
      baseFret: base,
      label: noteName,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is TabNote &&
      other.string == string &&
      other.fret == fret &&
      other.beats == beats &&
      other.section == section;

  @override
  int get hashCode => Object.hash(string, fret, beats, section);

  @override
  String toString() => 'TabNote($shortLabel, $beats)';
}

/// MIDI ↔ note-name helpers.
class NoteName {
  const NoteName._();

  static String of(int midi) => '${kNoteNames[midi % 12]}${midi ~/ 12 - 1}';

  static double frequency(int midi) =>
      440.0 * math.pow(2, (midi - 69) / 12).toDouble();

  /// Fractional MIDI number of [hz].
  static double midiOf(double hz) => 69 + 12 * math.log(hz / 440) / math.ln2;
}

/// A single-note melody: the notes in order plus the section each belongs to.
class MelodyTab {
  const MelodyTab(this.notes);

  final List<TabNote> notes;

  bool get isEmpty => notes.isEmpty;

  double get totalBeats => notes.fold(0, (sum, n) => sum + n.beats);

  /// Section names in order of first appearance.
  List<String> get sections {
    final seen = <String>{};
    return <String>[
      for (final n in notes)
        if (seen.add(n.section)) n.section,
    ];
  }

  List<TabNote> notesIn(String section) =>
      notes.where((n) => n.section == section).toList(growable: false);

  /// Lowest fretted note – where the hand sits ("box" position).
  int get boxStart {
    final fretted = notes.where((n) => n.fret > 0).map((n) => n.fret);
    return fretted.isEmpty ? 1 : fretted.reduce(math.min);
  }

  /// Distinct notes (by string + fret), lowest pitch first.
  List<TabNote> get uniqueNotes {
    final seen = <String>{};
    final unique = <TabNote>[
      for (final n in notes)
        if (seen.add('${n.string}:${n.fret}'))
          TabNote(string: n.string, fret: n.fret),
    ];
    unique.sort((a, b) => a.midi.compareTo(b.midi));
    return unique;
  }
}
