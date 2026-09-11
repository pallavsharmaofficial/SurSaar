import '../../models/song.dart';
import '../../models/song_section.dart';
import 'chord_library.dart';

/// What a pasted chord sheet contained.
class ParsedSheet {
  const ParsedSheet({
    required this.sections,
    required this.chords,
    this.key,
    this.capo = 0,
    this.strumming,
    this.bpm,
    this.title,
    this.artist,
  });

  final List<SongSection> sections;

  /// Unique chords in order of first appearance.
  final List<String> chords;
  final String? key;
  final int capo;
  final String? strumming;
  final int? bpm;
  final String? title;
  final String? artist;

  bool get isEmpty => chords.isEmpty;

  int get lineCount =>
      sections.fold(0, (sum, section) => sum + section.lines.length);

  /// Builds a song for the learner's own library.
  ///
  /// Lyrics stay in the learner's copy on their device; songs published in
  /// the shared catalogue are stored with chords only.
  Song toSong({
    required String id,
    String? title,
    String? artist,
    bool keepLyrics = true,
    List<String> tags = const <String>['my song'],
  }) {
    final songTitle = (title ?? this.title ?? 'My song').trim();
    final songArtist = (artist ?? this.artist ?? 'Unknown').trim();
    final sectionsOut = keepLyrics
        ? sections
        : sections
              .map(
                (section) => SongSection(
                  name: section.name,
                  repeat: section.repeat,
                  lines: section.lines
                      .map((line) => SongLine(chords: line.chords))
                      .toList(growable: false),
                ),
              )
              .toList(growable: false);
    return Song(
      id: id,
      title: songTitle.isEmpty ? 'My song' : songTitle,
      artist: songArtist.isEmpty ? 'Unknown' : songArtist,
      difficulty: ChordSheetParser.guessDifficulty(chords),
      strummingPattern: strumming ?? 'D DU UDU',
      originalChords: chords,
      key: key,
      capo: capo,
      bpm: bpm,
      sections: sectionsOut,
      tags: tags,
      addedByUser: true,
      tutorialUrl:
          'https://www.youtube.com/results?search_query=${Uri.encodeQueryComponent('$songTitle $songArtist guitar chords')}',
    );
  }
}

/// Reads pasted chord sheets.
///
/// Handles the three shapes people paste: chords above lyrics, ChordPro
/// (`[G]lyric`), and sheets copied from a web page where the line breaks were
/// lost so chords are glued to the lyrics ("…Paas mereEm F Dm GTere Paas
/// main").
class ChordSheetParser {
  const ChordSheetParser._();

  static final RegExp _chordAtStart = RegExp(
    r'^([A-G](?:#|b)?(?:maj|min|dim|aug|sus|add|m|M)?\d*(?:sus\d|add\d|maj\d)?(?:\/[A-G](?:#|b)?)?)',
  );
  static final RegExp _sectionLine = RegExp(r'^\[\s*([^\]]{1,32})\s*\]$');
  static final RegExp _inlineChord = RegExp(r'\[([^\]\s]{1,10})\]');
  static final RegExp _capo = RegExp(
    r'capo\s*(?:on|at|:)?\s*(?:the\s*)?(\d{1,2})',
    caseSensitive: false,
  );
  static final RegExp _key = RegExp(
    r'\bkey\s*(?:of|:)?\s*([A-G][#b]?)\s*(minor|major|min|maj|m)?\b',
    caseSensitive: false,
  );
  static final RegExp _strumming = RegExp(
    r'strum(?:ming)?(?:\s*pattern)?\s*[:\-]?\s*([DdUuXx\-.\s_]{4,40})',
    caseSensitive: false,
  );
  static final RegExp _bpm = RegExp(r'(\d{2,3})\s*bpm', caseSensitive: false);

  /// Puts section markers and glued chord runs back on their own lines.
  static String normalize(String raw) {
    var text = raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    text = text.replaceAllMapped(RegExp(r'\[([^\]\n]{1,32})\]'), (match) {
      final inner = match[1]!.trim();
      // "[Am]" is an inline ChordPro chord, not a section heading.
      return isChord(inner) ? match[0]! : '\n[$inner]\n';
    });
    // "…Paas mereEm F…" and "…Paas mainCJaise…"
    text = text.replaceAllMapped(
      RegExp(
        r'([a-z\)\],!\?])(?=[A-G](?:#|b)?(?:maj|min|dim|aug|sus|add|m)?\d*(?:\s|[A-Z]))',
      ),
      (match) => '${match[1]}\n',
    );
    return text;
  }

  static bool isChord(String token) {
    final match = _chordAtStart.firstMatch(token);
    return match != null && match.group(0)!.length == token.length;
  }

  /// Splits one line into its chords and the lyric that follows them.
  static (List<String>, String) splitLine(String line) {
    var rest = line.trim();
    final chords = <String>[];
    while (rest.isNotEmpty) {
      final match = _chordAtStart.firstMatch(rest);
      if (match == null) break;
      final token = match.group(1)!;
      final after = rest.substring(token.length);
      if (after.isEmpty || after.startsWith(RegExp(r'[\s|,]'))) {
        chords.add(token);
        rest = after.replaceFirst(RegExp(r'^[\s|,]+'), '');
        continue;
      }
      if (after.startsWith(RegExp('[A-Z]'))) {
        // the last chord of the run is glued to the lyric
        chords.add(token);
        rest = after;
        break;
      }
      break;
    }
    return (chords, rest.trim());
  }

  static ParsedSheet parse(String raw) {
    final text = normalize(raw);
    final sections = <SongSection>[];
    final allChords = <String>[];
    List<SongLine> lines = <SongLine>[];
    String sectionName = 'Progression';
    List<String>? pendingChords;
    String? key;
    var capo = 0;
    String? strumming;
    int? bpm;

    void flushSection() {
      if (lines.isEmpty) return;
      sections.add(
        SongSection(name: sectionName, lines: List<SongLine>.of(lines)),
      );
      lines = <SongLine>[];
    }

    void addLine(List<String> chords, String lyric) {
      if (chords.isEmpty) return;
      lines.add(
        SongLine(
          lyric: lyric,
          chords: chords
              .map((c) => ChordPlacement(chord: ChordLibrary.normalizeName(c)))
              .toList(growable: false),
        ),
      );
      for (final chord in chords) {
        final name = ChordLibrary.normalizeName(chord);
        if (!allChords.contains(name)) allChords.add(name);
      }
    }

    for (final raw in text.split('\n')) {
      final line = raw.trim();
      if (line.isEmpty) {
        if (pendingChords != null) {
          addLine(pendingChords, '');
          pendingChords = null;
        }
        continue;
      }

      final capoMatch = _capo.firstMatch(line);
      if (capoMatch != null && capo == 0) {
        capo = int.tryParse(capoMatch.group(1)!) ?? 0;
      }
      final strumMatch = _strumming.firstMatch(line);
      if (strumMatch != null && strumming == null) {
        final pattern = strumMatch.group(1)!.trim().toUpperCase();
        if (RegExp('[DU]').hasMatch(pattern)) strumming = pattern;
      }
      final bpmMatch = _bpm.firstMatch(line);
      if (bpmMatch != null && bpm == null) {
        bpm = int.tryParse(bpmMatch.group(1)!);
      }

      final section = _sectionLine.firstMatch(line);
      if (section != null && !isChord(section.group(1)!.trim())) {
        if (pendingChords != null) {
          addLine(pendingChords, '');
          pendingChords = null;
        }
        flushSection();
        final name = section.group(1)!.trim();
        sectionName = name.isEmpty
            ? sectionName
            : name[0].toUpperCase() + name.substring(1);
        continue;
      }

      // ChordPro: [G]lyric [C]lyric
      if (_inlineChord.hasMatch(line)) {
        final chords = <ChordPlacement>[];
        final buffer = StringBuffer();
        var last = 0;
        for (final match in _inlineChord.allMatches(line)) {
          buffer.write(line.substring(last, match.start));
          final chord = match.group(1)!;
          if (isChord(chord)) {
            chords.add(
              ChordPlacement(
                chord: ChordLibrary.normalizeName(chord),
                position: buffer.length,
              ),
            );
          }
          last = match.end;
        }
        buffer.write(line.substring(last));
        if (chords.isNotEmpty) {
          lines.add(SongLine(lyric: buffer.toString().trim(), chords: chords));
          for (final placement in chords) {
            if (!allChords.contains(placement.chord)) {
              allChords.add(placement.chord);
            }
          }
          continue;
        }
      }

      final (chords, lyric) = splitLine(line);
      if (chords.isEmpty) {
        // a lyric line under a chord-only line
        if (pendingChords != null) {
          addLine(pendingChords, lyric);
          pendingChords = null;
        }
        continue;
      }
      if (lyric.isEmpty) {
        if (pendingChords != null) {
          addLine(pendingChords, '');
        }
        pendingChords = chords;
        continue;
      }
      if (pendingChords != null) {
        addLine(pendingChords, '');
        pendingChords = null;
      }
      addLine(chords, lyric);
    }
    if (pendingChords != null) {
      addLine(pendingChords, '');
    }
    flushSection();

    final keyMatch = _key.firstMatch(text);
    if (keyMatch != null) {
      final quality = (keyMatch.group(2) ?? '').toLowerCase();
      final minor = quality.startsWith('m') && !quality.startsWith('maj');
      key = ChordLibrary.normalizeName(
        '${keyMatch.group(1)!}${minor ? 'm' : ''}',
      );
    }
    key ??= _inferKey(sections);

    return ParsedSheet(
      sections: sections,
      chords: allChords,
      key: key,
      capo: capo,
      strumming: strumming,
      bpm: bpm,
    );
  }

  /// Songs usually start and end on their key chord.
  static String? _inferKey(List<SongSection> sections) {
    final order = <String>[
      for (final section in sections)
        for (final line in section.lines)
          for (final placement in line.chords) placement.chord,
    ];
    if (order.isEmpty) return null;
    final first = order.first;
    final last = order.last;
    if (first == last) return first;
    final counts = <String, int>{};
    for (final chord in order) {
      counts[chord] = (counts[chord] ?? 0) + 1;
    }
    return (counts[first] ?? 0) >= (counts[last] ?? 0) ? first : last;
  }

  static final RegExp _barreChord = RegExp(
    r'^(F|B|Bm|Fm|F#|F#m|C#m|G#m|A#|A#m|D#|D#m|Cm|Gm)(?!\w)',
  );

  static SongDifficulty guessDifficulty(List<String> chords) {
    final barres = chords.where(_barreChord.hasMatch).length;
    if (chords.length <= 4 && barres == 0) return SongDifficulty.beginner;
    if (chords.length <= 6 && barres <= 1) return SongDifficulty.intermediate;
    return SongDifficulty.advanced;
  }

  /// A stable id for a pasted song, unique against [existingIds].
  static String idFor(String title, String artist, Set<String> existingIds) {
    final base = '${title}_$artist'
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final slug = base.isEmpty ? 'my_song' : base;
    if (!existingIds.contains(slug)) return slug;
    for (var i = 2; i < 100; i++) {
      if (!existingIds.contains('${slug}_$i')) return '${slug}_$i';
    }
    return '${slug}_${DateTime.now().millisecondsSinceEpoch}';
  }
}
