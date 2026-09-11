class ChordTransposer {
  static const List<String> _scale = <String>[
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

  static const Map<String, String> _flatToSharp = <String, String>{
    'Db': 'C#',
    'Eb': 'D#',
    'Gb': 'F#',
    'Ab': 'G#',
    'Bb': 'A#',
  };

  static String transposeChord(String chord, int semitones) {
    final match = RegExp(r'^([A-G])([#b]?)(.*)$').firstMatch(chord);
    if (match == null) return chord;

    final letter = match.group(1)!;
    final accidental = match.group(2) ?? '';
    final suffix = match.group(3) ?? '';

    var root = '$letter$accidental';
    root = _flatToSharp[root] ?? root;

    final index = _scale.indexOf(root);
    if (index == -1) return chord;

    final newIndex = (index + semitones) % _scale.length;
    final adjustedIndex = newIndex < 0 ? newIndex + _scale.length : newIndex;

    return '${_scale[adjustedIndex]}$suffix';
  }

  static List<String> transposeProgression(
    List<String> progression,
    int semitones,
  ) {
    return progression
        .map((chord) => transposeChord(chord, semitones))
        .toList(growable: false);
  }
}
