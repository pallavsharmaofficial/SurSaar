import 'package:flutter_test/flutter_test.dart';
import 'package:sursaar/data/content/chord_library.dart';
import 'package:sursaar/models/chord_voicing.dart';

void main() {
  final library = ChordLibrary(const <ChordVoicing>[
    ChordVoicing(
      name: 'G',
      frets: <int>[3, 2, 0, 0, 0, 3],
      fingers: <int>[2, 1, 0, 0, 0, 3],
    ),
    ChordVoicing(
      name: 'Am',
      frets: <int>[-1, 0, 2, 2, 1, 0],
      fingers: <int>[0, 0, 2, 3, 1, 0],
    ),
  ]);

  test('normalises spellings', () {
    expect(ChordLibrary.normalizeName('Bb'), 'A#');
    expect(ChordLibrary.normalizeName('Amin'), 'Am');
    expect(ChordLibrary.normalizeName('Cmaj'), 'C');
    expect(ChordLibrary.normalizeName('CMaj7'), 'Cmaj7');
    expect(ChordLibrary.normalizeName('g'), 'G');
  });

  test('returns stored voicings', () {
    expect(library.voicingFor('G')!.frets, <int>[3, 2, 0, 0, 0, 3]);
    expect(library.voicingFor('A minor')!.name, 'Am');
  });

  test('derives barre chords from movable shapes', () {
    final fSharpMinor = library.voicingFor('F#m')!;
    expect(fSharpMinor.frets, <int>[2, 4, 4, 2, 2, 2]);
    expect(fSharpMinor.barres.first.fret, 2);
    expect(fSharpMinor.pitchClasses, <int>{6, 9, 1}); // F# A C#

    final bFlat = library.voicingFor('Bb')!;
    expect(bFlat.frets, <int>[-1, 1, 3, 3, 3, 1]);
    expect(bFlat.name, 'A#');
  });

  test('pitch classes of open G are G B D', () {
    expect(library.voicingFor('G')!.pitchClasses, <int>{7, 11, 2});
  });

  test('slash chords fall back to the upper chord', () {
    expect(library.voicingFor('G/B')!.name, 'G');
  });
}
