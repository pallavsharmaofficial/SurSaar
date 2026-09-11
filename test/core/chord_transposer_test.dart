import 'package:flutter_test/flutter_test.dart';
import 'package:sursaar/core/utils/chord_transposer.dart';

void main() {
  test('transposes up and down with suffixes', () {
    expect(ChordTransposer.transposeChord('G', 2), 'A');
    expect(ChordTransposer.transposeChord('Am7', -2), 'Gm7');
    expect(ChordTransposer.transposeChord('Bb', 1), 'B');
    expect(ChordTransposer.transposeChord('C', -1), 'B');
  });

  test('transposes progressions', () {
    expect(
      ChordTransposer.transposeProgression(<String>['G', 'Em', 'C', 'D'], -3),
      <String>['E', 'C#m', 'A', 'B'],
    );
  });
}
