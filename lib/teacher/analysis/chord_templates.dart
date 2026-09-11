import '../../data/content/chord_library.dart';
import '../../models/chord_voicing.dart';
import 'chroma.dart';

/// Pitch-class templates for chord matching.
class ChordTemplates {
  const ChordTemplates._();

  /// Semitone intervals above the root for each chord quality suffix.
  static const Map<String, List<int>> intervals = <String, List<int>>{
    '': <int>[0, 4, 7],
    'm': <int>[0, 3, 7],
    '7': <int>[0, 4, 7, 10],
    'm7': <int>[0, 3, 7, 10],
    'maj7': <int>[0, 4, 7, 11],
    'sus2': <int>[0, 2, 7],
    'sus4': <int>[0, 5, 7],
    'dim': <int>[0, 3, 6],
    'aug': <int>[0, 4, 8],
    'add9': <int>[0, 4, 7, 2],
    '6': <int>[0, 4, 7, 9],
    'm6': <int>[0, 3, 7, 9],
    '9': <int>[0, 4, 7, 10, 2],
    '5': <int>[0, 7],
  };

  /// All 24 major/minor triads, the default candidate set.
  static List<String> get triads => <String>[
    for (final note in kNoteNames) note,
    for (final note in kNoteNames) '${note}m',
  ];

  /// Weighted, normalised 12-bin template for [chordName], or null for an
  /// unknown quality.
  static List<double>? templateFor(String chordName) {
    final name = ChordLibrary.normalizeName(chordName).split('/').first;
    final root = ChordLibrary.rootIndex(name);
    if (root < 0) return null;
    final suffix = ChordLibrary.suffixOf(name);
    final steps = intervals[suffix] ?? intervals[_fallbackSuffix(suffix)];
    if (steps == null) return null;
    final t = List<double>.filled(12, 0);
    for (var i = 0; i < steps.length; i++) {
      final pc = (root + steps[i]) % 12;
      // root and third define the chord, the fifth is shared by many.
      final weight = i == 0 ? 1.0 : (steps[i] == 7 ? 0.8 : 0.95);
      t[pc] = weight > t[pc] ? weight : t[pc];
    }
    return ChromaExtractor.normalize(t);
  }

  static String _fallbackSuffix(String suffix) {
    if (suffix.startsWith('maj')) return 'maj7';
    if (suffix.startsWith('m')) return 'm';
    if (suffix.startsWith('sus')) return 'sus4';
    if (suffix.startsWith('dim')) return 'dim';
    return '';
  }
}
