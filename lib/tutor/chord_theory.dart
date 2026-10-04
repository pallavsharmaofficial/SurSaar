import '../data/content/chord_library.dart';
import '../models/chord_voicing.dart';
import '../teacher/analysis/chord_shape_coach.dart';

/// Just enough music theory for the tutor to explain a wrong chord.
class ChordTheory {
  const ChordTheory._();

  static const Map<String, List<int>> _intervals = <String, List<int>>{
    '': <int>[0, 4, 7],
    'm': <int>[0, 3, 7],
    '7': <int>[0, 4, 7, 10],
    'm7': <int>[0, 3, 7, 10],
    'maj7': <int>[0, 4, 7, 11],
    'sus2': <int>[0, 2, 7],
    'sus4': <int>[0, 5, 7],
    '7sus4': <int>[0, 5, 7, 10],
    'add9': <int>[0, 2, 4, 7],
    'madd9': <int>[0, 2, 3, 7],
    'dim': <int>[0, 3, 6],
    'aug': <int>[0, 4, 8],
    '6': <int>[0, 4, 7, 9],
    'm6': <int>[0, 3, 7, 9],
    '9': <int>[0, 2, 4, 7, 10],
    '5': <int>[0, 7],
  };

  static const List<String> _stringNames = <String>[
    'low E',
    'A',
    'D',
    'G',
    'B',
    'high e',
  ];

  /// Pitch classes (0 = C) of [chord], or empty when it can't be read.
  static Set<int> tones(String chord) {
    final name = ChordLibrary.normalizeName(chord);
    final parts = name.split('/');
    final root = ChordLibrary.rootIndex(parts.first);
    if (root < 0) return const <int>{};
    final suffix = ChordLibrary.suffixOf(parts.first);
    final intervals =
        _intervals[suffix] ??
        (suffix.startsWith('m') ? _intervals['m']! : _intervals['']!);
    final result = <int>{for (final i in intervals) (root + i) % 12};
    if (parts.length > 1) {
      final bass = ChordLibrary.rootIndex(parts[1]);
      if (bass >= 0) result.add(bass);
    }
    return result;
  }

  static String noteName(int pitchClass) => kNoteNames[pitchClass % 12];

  /// Barre chords are the big hurdle for beginners.
  static bool isBarre(ChordVoicing? voicing) =>
      voicing != null && (voicing.barres.isNotEmpty || voicing.baseFret > 1);

  /// Explains why [target] came out sounding like [heard], using the
  /// strings of [voicing] that carry the missing notes.
  static String explainConfusion(
    String target,
    String heard, {
    ChordVoicing? voicing,
  }) {
    final want = tones(target);
    final got = tones(heard);
    if (want.isEmpty || got.isEmpty) {
      return 'Check every finger is pressing just behind its fret.';
    }
    final missing = want.difference(got);
    final extra = got.difference(want);
    final shared = want.intersection(got).length;
    final buffer = StringBuffer();
    if (missing.isNotEmpty) {
      buffer.write(
        "I'm not hearing the ${missing.map(noteName).join(' and ')} "
        '${missing.length > 1 ? 'notes' : 'note'}',
      );
      if (extra.isNotEmpty) {
        buffer.write(
          ' and I hear ${extra.map(noteName).join(' and ')} instead',
        );
      }
      buffer.write('. ');
    }
    if (voicing != null && missing.isNotEmpty) {
      final strings = <String>[];
      for (var s = 0; s < 6; s++) {
        final fret = voicing.frets[s];
        if (fret < 0) continue;
        final pc = (kStandardTuningMidi[s] + fret) % 12;
        if (!missing.contains(pc)) continue;
        if (fret == 0) {
          strings.add('the open ${_stringNames[s]} string rings');
        } else {
          final finger = voicing.fingers[s];
          final who = finger >= 1 && finger <= 4
              ? 'your ${ChordShapeCoach.fingerName(finger)}'
              : 'a finger';
          strings.add(
            '$who presses the ${_stringNames[s]} string at fret $fret',
          );
        }
      }
      if (strings.isNotEmpty) {
        buffer.write('Make sure ${strings.take(2).join(', and ')}.');
      }
    }
    if (shared >= 2) {
      buffer.write(
        ' $target and $heard share $shared notes, so one muted or wrong '
        'string is enough to tip it over.',
      );
    }
    final text = buffer.toString().trim();
    return text.isEmpty
        ? 'Check every finger is pressing just behind its fret.'
        : text;
  }
}
