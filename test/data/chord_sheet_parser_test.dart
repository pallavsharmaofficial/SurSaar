import 'package:flutter_test/flutter_test.dart';
import 'package:sursaar/data/content/chord_sheet_parser.dart';
import 'package:sursaar/models/song.dart';

/// Pasted from a web page: the line breaks were lost, so chords are glued
/// to the end of the previous lyric.
const gluedSheet =
    '[Verse 1]CJaise tu hai Paas mereEm F Dm GTere Paas mainCJaise shaamon ke '
    'sawereF G CTere Paas mainF GJaise neechi nazar meinAm EmSharam chhupi '
    'haiDm GSaanson mein koi nazamCJaise paani Paas pyaaseEm F Dm GTere Paas '
    'mainCJaise dil ke hain dilaaseF G CTere Paas main[Chorus]Bb GJhooth hain '
    'ye dooriyanBb F GJhooth faasla haiC FTujhe roz mil raha hoon mainD G F '
    'GYeh door phir kaha huaCJaise kaanon mein ho baaliEm F Dm GTere Paas '
    'mainCJaise honthon pe ho laaliF G CTere Paas mainF G CTere Paas mainF G '
    'CTere Paas main';

void main() {
  group('ChordSheetParser', () {
    test('reads a sheet whose line breaks were lost', () {
      final sheet = ChordSheetParser.parse(gluedSheet);

      expect(sheet.chords, <String>[
        'C',
        'Em',
        'F',
        'Dm',
        'G',
        'Am',
        'A#',
        'D',
      ]);
      expect(sheet.sections.map((s) => s.name), <String>['Verse 1', 'Chorus']);
      expect(sheet.key, 'C');

      final verse = sheet.sections.first;
      expect(verse.lines.first.chords.map((c) => c.chord), <String>['C']);
      expect(verse.lines.first.lyric, 'Jaise tu hai Paas mere');
      expect(verse.lines[1].chords.map((c) => c.chord), <String>[
        'Em',
        'F',
        'Dm',
        'G',
      ]);
      expect(verse.lines[1].lyric, 'Tere Paas main');

      final chorus = sheet.sections[1];
      expect(chorus.lines.first.chords.map((c) => c.chord), <String>[
        'A#',
        'G',
      ]);
      expect(chorus.lines.first.lyric, 'Jhooth hain ye dooriyan');
      expect(chorus.lines[3].chords.map((c) => c.chord), <String>[
        'D',
        'G',
        'F',
        'G',
      ]);
    });

    test('reads chords written above the lyrics', () {
      const sheet = '''
Capo on 2nd fret
Strumming: D DU UDU
Key: G major

[Verse]
G            Em
Kaara kaara mausam
C        D
kaisa yeh gaana

[Chorus]
Bm  G  D  A
''';
      final parsed = ChordSheetParser.parse(sheet);
      expect(parsed.capo, 2);
      expect(parsed.strumming, 'D DU UDU');
      expect(parsed.key, 'G');
      expect(parsed.chords, <String>['G', 'Em', 'C', 'D', 'Bm', 'A']);
      expect(parsed.sections.first.lines.first.lyric, 'Kaara kaara mausam');
      expect(parsed.sections.last.lines.single.lyric, isEmpty);
    });

    test('reads ChordPro lines', () {
      final parsed = ChordSheetParser.parse(
        '[Verse]\n[Am]Hello [F]there [C]my [G]friend',
      );
      expect(parsed.chords, <String>['Am', 'F', 'C', 'G']);
      final line = parsed.sections.single.lines.single;
      expect(line.lyric, 'Hello there my friend');
      expect(line.chords[1].position, greaterThan(0));
    });

    test('keeps lyric-looking words out of the chords', () {
      final parsed = ChordSheetParser.parse('C\nCold mess and Dil se');
      expect(parsed.chords, <String>['C']);
      expect(parsed.sections.single.lines.single.lyric, 'Cold mess and Dil se');
    });

    test('builds a song, with or without lyrics', () {
      final sheet = ChordSheetParser.parse(gluedSheet);
      final withLyrics = sheet.toSong(id: 'x', title: 'Tere Paas Main');
      expect(withLyrics.addedByUser, isTrue);
      expect(withLyrics.difficulty, SongDifficulty.advanced);
      expect(withLyrics.uniqueChords.first, 'C');
      expect(withLyrics.sections.first.lines.first.lyric, isNotEmpty);

      final chordsOnly = sheet.toSong(
        id: 'x',
        title: 'Tere Paas Main',
        keepLyrics: false,
      );
      expect(
        chordsOnly.sections.every((s) => s.lines.every((l) => l.lyric.isEmpty)),
        isTrue,
      );
      expect(chordsOnly.sections.first.lines.length, 11);
    });

    test('makes unique ids', () {
      expect(
        ChordSheetParser.idFor('Tere Paas Main', 'Unknown', <String>{}),
        'tere_paas_main_unknown',
      );
      expect(ChordSheetParser.idFor('A', 'B', <String>{'a_b'}), 'a_b_2');
    });
  });
}
