import 'package:flutter_test/flutter_test.dart';
import 'package:sursaar/models/strumming_pattern.dart';

void main() {
  group('StrummingPattern.parse', () {
    test('classic D DU UDU lands on the right slots', () {
      final p = StrummingPattern.parse('D DU UDU');
      expect(p.gridNotation, 'D - D U - U D U');
      expect(p.slots.length, 8);
    });

    test('D D U U D U is the same groove', () {
      expect(
        StrummingPattern.parse('D D U U D U').gridNotation,
        'D - D U - U D U',
      );
    });

    test('explicit rests are respected', () {
      expect(
        StrummingPattern.parse('D - D U - U D U').gridNotation,
        'D - D U - U D U',
      );
    });

    test('dashes as separators still parse', () {
      expect(
        StrummingPattern.parse('D - DU - UDU').gridNotation,
        'D - D U - U D U',
      );
    });

    test('mutes are kept and words are understood', () {
      final p = StrummingPattern.parse('down mute down-up');
      expect(p.slots.first, StrokeType.down);
      expect(p.slots.contains(StrokeType.mute), isTrue);
    });

    test('long patterns extend to two bars', () {
      final p = StrummingPattern.parse('D - D - UU - D - DU');
      expect(p.bars, 2);
      expect(p.slots.length, 16);
    });

    test('empty falls back to four downstrokes', () {
      expect(StrummingPattern.parse('').gridNotation, 'D - D - D - D -');
    });

    test('json round trip', () {
      final p = StrummingPattern.parse('D X DU X DU');
      final copy = StrummingPattern.fromJson(p.toJson());
      expect(copy, p);
    });
  });
}
