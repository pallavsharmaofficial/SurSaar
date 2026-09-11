import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../models/chord_voicing.dart';

/// Looks up how to finger a chord.
///
/// Open-position voicings come from `assets/data/chords.json` (or the remote
/// content bundle). Anything else that is a plain major / minor / 7 / m7
/// chord is derived on the fly from movable E-shape and A-shape barre
/// templates, so every chord a song can throw at the learner has a diagram.
class ChordLibrary {
  ChordLibrary(List<ChordVoicing> voicings) {
    for (final voicing in voicings) {
      _byName.putIfAbsent(normalizeName(voicing.name), () => voicing);
    }
  }

  static const String assetPath = 'assets/data/chords.json';

  static Future<ChordLibrary> loadFromAsset() async {
    final raw = await rootBundle.loadString(assetPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return ChordLibrary.fromJson(json);
  }

  factory ChordLibrary.fromJson(Map<String, dynamic> json) {
    final list = (json['voicings'] as List<dynamic>? ?? <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(ChordVoicing.fromJson)
        .toList(growable: false);
    return ChordLibrary(list);
  }

  final Map<String, ChordVoicing> _byName = <String, ChordVoicing>{};

  Iterable<String> get knownChords => _byName.keys;

  /// Adds voicings (e.g. from a remote bundle); later additions win.
  void addAll(Iterable<ChordVoicing> voicings) {
    for (final voicing in voicings) {
      _byName[normalizeName(voicing.name)] = voicing;
    }
  }

  static const Map<String, String> _flatToSharp = <String, String>{
    'Db': 'C#',
    'Eb': 'D#',
    'Gb': 'F#',
    'Ab': 'G#',
    'Bb': 'A#',
    'Cb': 'B',
    'Fb': 'E',
    'E#': 'F',
    'B#': 'C',
  };

  /// Canonical chord spelling: sharps, "m" for minor, no "maj" for major.
  static String normalizeName(String name) {
    var text = name.trim();
    if (text.isEmpty) return text;
    final match = RegExp(r'^([A-Ga-g])([#b♯♭]?)(.*)$').firstMatch(text);
    if (match == null) return text;
    final letter = match.group(1)!.toUpperCase();
    var accidental = match.group(2) ?? '';
    accidental = accidental.replaceAll('♯', '#').replaceAll('♭', 'b');
    var root = '$letter$accidental';
    root = _flatToSharp[root] ?? root;
    var suffix = (match.group(3) ?? '').trim();
    final lower = suffix.toLowerCase();
    final majorExt = RegExp(
      r'^(major|Major|maj|Maj|M)(\d+.*)$',
    ).firstMatch(suffix);
    final minorMarker = RegExp(r'^(minor|min|-)').firstMatch(lower);
    if (lower == 'major' || lower == 'maj' || suffix == 'M') {
      suffix = '';
    } else if (majorExt != null) {
      suffix = 'maj${majorExt.group(2)}';
    } else if (minorMarker != null) {
      suffix = 'm${suffix.substring(minorMarker.end)}';
    }
    return '$root$suffix';
  }

  static int rootIndex(String normalizedName) {
    final match = RegExp(r'^([A-G]#?)').firstMatch(normalizedName);
    if (match == null) return -1;
    return kNoteNames.indexOf(match.group(1)!);
  }

  static String suffixOf(String normalizedName) =>
      normalizedName.replaceFirst(RegExp(r'^[A-G]#?'), '');

  /// The best voicing for [chordName], or null when the chord cannot be
  /// derived (exotic qualities without a stored voicing).
  ChordVoicing? voicingFor(String chordName) {
    final name = normalizeName(chordName);
    final stored = _byName[name];
    if (stored != null) return stored;

    // Slash chords: use the upper chord's shape.
    if (name.contains('/')) {
      return voicingFor(name.split('/').first);
    }

    final root = rootIndex(name);
    if (root < 0) return null;
    final suffix = suffixOf(name);
    final eShape = _eShapes[suffix];
    final aShape = _aShapes[suffix];
    if (eShape == null && aShape == null) {
      // Unknown quality – fall back to the triad so the learner still gets
      // a usable shape and a note in the label.
      final triad = suffix.startsWith('m') ? 'm' : '';
      final fallback = voicingFor('${kNoteNames[root]}$triad');
      return fallback == null
          ? null
          : ChordVoicing(
              name: name,
              frets: fallback.frets,
              fingers: fallback.fingers,
              baseFret: fallback.baseFret,
              barres: fallback.barres,
              label: 'approximation (${fallback.name} shape)',
            );
    }

    // E-shape root is on the low E string (E = 4), A-shape on A (= 9).
    final eFret = (root - 4) % 12 == 0 ? 12 : (root - 4) % 12;
    final aFret = (root - 9) % 12 == 0 ? 12 : (root - 9) % 12;
    // Prefer whichever sits lower on the neck.
    if (eShape != null && (aShape == null || eFret <= aFret)) {
      return eShape.transposed(eFret - 1, newName: name);
    }
    return aShape!.transposed(aFret - 1, newName: name);
  }

  /// Movable shapes rooted on fret 1 (F family) – all strings fretted.
  static final Map<String, ChordVoicing> _eShapes = <String, ChordVoicing>{
    '': const ChordVoicing(
      name: 'F',
      frets: <int>[1, 3, 3, 2, 1, 1],
      fingers: <int>[1, 3, 4, 2, 1, 1],
      baseFret: 1,
      barres: <Barre>[Barre(fret: 1, startString: 0, endString: 5)],
      label: 'E-shape barre',
    ),
    'm': const ChordVoicing(
      name: 'Fm',
      frets: <int>[1, 3, 3, 1, 1, 1],
      fingers: <int>[1, 3, 4, 1, 1, 1],
      baseFret: 1,
      barres: <Barre>[Barre(fret: 1, startString: 0, endString: 5)],
      label: 'Em-shape barre',
    ),
    '7': const ChordVoicing(
      name: 'F7',
      frets: <int>[1, 3, 1, 2, 1, 1],
      fingers: <int>[1, 3, 1, 2, 1, 1],
      baseFret: 1,
      barres: <Barre>[Barre(fret: 1, startString: 0, endString: 5)],
      label: 'E7-shape barre',
    ),
    'm7': const ChordVoicing(
      name: 'Fm7',
      frets: <int>[1, 3, 1, 1, 1, 1],
      fingers: <int>[1, 3, 1, 1, 1, 1],
      baseFret: 1,
      barres: <Barre>[Barre(fret: 1, startString: 0, endString: 5)],
      label: 'Em7-shape barre',
    ),
    'maj7': const ChordVoicing(
      name: 'Fmaj7',
      frets: <int>[1, 3, 2, 2, 1, 1],
      fingers: <int>[1, 4, 2, 3, 1, 1],
      baseFret: 1,
      barres: <Barre>[Barre(fret: 1, startString: 0, endString: 5)],
      label: 'Emaj7-shape barre',
    ),
    'sus4': const ChordVoicing(
      name: 'Fsus4',
      frets: <int>[1, 3, 3, 3, 1, 1],
      fingers: <int>[1, 2, 3, 4, 1, 1],
      baseFret: 1,
      barres: <Barre>[Barre(fret: 1, startString: 0, endString: 5)],
      label: 'Esus4-shape barre',
    ),
  };

  /// Movable shapes rooted on fret 1 (A#/Bb family) – low E muted.
  static final Map<String, ChordVoicing> _aShapes = <String, ChordVoicing>{
    '': const ChordVoicing(
      name: 'A#',
      frets: <int>[-1, 1, 3, 3, 3, 1],
      fingers: <int>[0, 1, 3, 3, 3, 1],
      baseFret: 1,
      barres: <Barre>[
        Barre(fret: 1, startString: 1, endString: 5),
        Barre(fret: 3, startString: 2, endString: 4, finger: 3),
      ],
      label: 'A-shape barre',
    ),
    'm': const ChordVoicing(
      name: 'A#m',
      frets: <int>[-1, 1, 3, 3, 2, 1],
      fingers: <int>[0, 1, 3, 4, 2, 1],
      baseFret: 1,
      barres: <Barre>[Barre(fret: 1, startString: 1, endString: 5)],
      label: 'Am-shape barre',
    ),
    '7': const ChordVoicing(
      name: 'A#7',
      frets: <int>[-1, 1, 3, 1, 3, 1],
      fingers: <int>[0, 1, 3, 1, 4, 1],
      baseFret: 1,
      barres: <Barre>[Barre(fret: 1, startString: 1, endString: 5)],
      label: 'A7-shape barre',
    ),
    'm7': const ChordVoicing(
      name: 'A#m7',
      frets: <int>[-1, 1, 3, 1, 2, 1],
      fingers: <int>[0, 1, 3, 1, 2, 1],
      baseFret: 1,
      barres: <Barre>[Barre(fret: 1, startString: 1, endString: 5)],
      label: 'Am7-shape barre',
    ),
    'maj7': const ChordVoicing(
      name: 'A#maj7',
      frets: <int>[-1, 1, 3, 2, 3, 1],
      fingers: <int>[0, 1, 3, 2, 4, 1],
      baseFret: 1,
      barres: <Barre>[Barre(fret: 1, startString: 1, endString: 5)],
      label: 'Amaj7-shape barre',
    ),
    'sus2': const ChordVoicing(
      name: 'A#sus2',
      frets: <int>[-1, 1, 3, 3, 1, 1],
      fingers: <int>[0, 1, 3, 4, 1, 1],
      baseFret: 1,
      barres: <Barre>[Barre(fret: 1, startString: 1, endString: 5)],
      label: 'Asus2-shape barre',
    ),
    'sus4': const ChordVoicing(
      name: 'A#sus4',
      frets: <int>[-1, 1, 3, 3, 4, 1],
      fingers: <int>[0, 1, 2, 3, 4, 1],
      baseFret: 1,
      barres: <Barre>[Barre(fret: 1, startString: 1, endString: 5)],
      label: 'Asus4-shape barre',
    ),
  };
}
