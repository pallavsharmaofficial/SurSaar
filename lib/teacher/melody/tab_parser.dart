import 'melody_tab.dart';

/// Reads ASCII guitar tab into a [MelodyTab].
///
/// ```
/// [Sthayi]
/// e|-----0--------|
/// B|--1-----3--1--|
/// G|--------------|
/// ```
///
/// * Blocks of `e|`, `B|`, `G|`, `D|`, `A|`, `E|` lines are read column by
///   column; partial blocks (one or two strings, common for single-string
///   tabs) work too.
/// * When several strings sound in the same column the highest string is the
///   melody note.
/// * Technique marks (`h p / \ b r ~ x`) are ignored; frets up to 24.
/// * ASCII tab has no rhythm, so durations come from the spacing: the most
///   common gap between notes is one beat and the others are scaled to it
///   (rounded to quarter beats).
/// * `[Intro]`, `Verse:` or `# Antara` lines name the section that follows.
class TabParser {
  const TabParser._();

  static final RegExp _tabLine = RegExp(r'^\s*([eEbBgGdDaA])\s*[|:](.*)$');
  static final RegExp _bracketHeader = RegExp(r'^\s*\[([^\]]{1,40})\]\s*$');
  static final RegExp _colonHeader = RegExp(r'^\s*([A-Za-z][\w ]{0,30}):\s*$');
  static final RegExp _hashHeader = RegExp(r'^\s*#+\s*(.{1,40})$');

  /// True when [text] looks like it contains tab lines.
  static bool looksLikeTab(String text) => text.split('\n').any(_isTabContent);

  static MelodyTab parse(String text, {String defaultSection = 'Melody'}) {
    final lines = text.replaceAll('\r', '').split('\n');
    final events = <_Event>[];
    var section = defaultSection;
    var block = <String>[];
    var blockSection = section;
    var columnOffset = 0;
    var blockIndex = 0;

    void flush() {
      if (block.isEmpty) return;
      final parsed = _parseBlock(block, columnOffset, blockSection, blockIndex);
      if (parsed.isNotEmpty) {
        events.addAll(parsed);
        blockIndex++;
      }
      final width = block
          .map((l) => _tabLine.firstMatch(l)!.group(2)!.length)
          .fold<int>(0, (a, b) => a > b ? a : b);
      columnOffset += width + 1;
      block = <String>[];
    }

    for (final raw in lines) {
      if (_isTabContent(raw)) {
        if (block.isEmpty) blockSection = section;
        block.add(raw);
        continue;
      }
      flush();
      final header = _headerOf(raw);
      if (header != null) section = header;
    }
    flush();
    return MelodyTab(_withDurations(events));
  }

  static bool _isTabContent(String line) {
    final match = _tabLine.firstMatch(line);
    if (match == null) return false;
    final body = match.group(2)!;
    // Real tab lines are mostly dashes.
    return body.contains('-') &&
        body.replaceAll(RegExp(r'[^-]'), '').length >= body.trim().length / 3;
  }

  static String? _headerOf(String line) {
    for (final pattern in <RegExp>[_bracketHeader, _colonHeader, _hashHeader]) {
      final match = pattern.firstMatch(line);
      if (match != null) return match.group(1)!.trim();
    }
    return null;
  }

  /// Maps the lines of one block to string indices (0 = low E).
  static List<int> _stringsFor(List<String> block) {
    final letters = block
        .map((l) => _tabLine.firstMatch(l)!.group(1)!)
        .toList(growable: false);
    if (letters.length == 6) return const <int>[5, 4, 3, 2, 1, 0];
    final upperECount = letters.where((l) => l == 'E').length;
    var seenUpperE = false;
    final strings = <int>[];
    for (final letter in letters) {
      switch (letter) {
        case 'e':
          strings.add(5);
        case 'b' || 'B':
          strings.add(4);
        case 'g' || 'G':
          strings.add(3);
        case 'd' || 'D':
          strings.add(2);
        case 'a' || 'A':
          strings.add(1);
        default:
          // With two "E" lines the first one is the high string.
          strings.add(upperECount >= 2 && !seenUpperE ? 5 : 0);
          seenUpperE = true;
      }
    }
    return strings;
  }

  static List<_Event> _parseBlock(
    List<String> block,
    int columnOffset,
    String section,
    int blockIndex,
  ) {
    final strings = _stringsFor(block);
    final byColumn = <int, _Event>{};
    var blockEnd = columnOffset;
    for (final line in block) {
      final body = _tabLine.firstMatch(line)!.group(2)!.trimRight();
      final trimmed = body.endsWith('|') || body.endsWith(':')
          ? body.substring(0, body.length - 1)
          : body;
      if (columnOffset + trimmed.length > blockEnd) {
        blockEnd = columnOffset + trimmed.length;
      }
    }
    for (var i = 0; i < block.length; i++) {
      final body = _tabLine.firstMatch(block[i])!.group(2)!;
      var c = 0;
      while (c < body.length) {
        final code = body.codeUnitAt(c);
        if (!_isDigit(code)) {
          c++;
          continue;
        }
        var end = c + 1;
        if (end < body.length &&
            _isDigit(body.codeUnitAt(end)) &&
            int.parse(body.substring(c, end + 1)) <= 24) {
          end++;
        }
        final fret = int.parse(body.substring(c, end));
        final column = columnOffset + c;
        final existing = byColumn[column];
        if (existing == null || strings[i] > existing.string) {
          byColumn[column] = _Event(
            column: column,
            string: strings[i],
            fret: fret,
            section: section,
            block: blockIndex,
            blockEnd: blockEnd,
          );
        }
        c = end;
      }
    }
    final events = byColumn.values.toList()
      ..sort((a, b) => a.column.compareTo(b.column));
    return events;
  }

  static bool _isDigit(int code) => code >= 48 && code <= 57;

  static List<TabNote> _withDurations(List<_Event> events) {
    if (events.isEmpty) return const <TabNote>[];
    final gaps = <int>[];
    for (var i = 0; i + 1 < events.length; i++) {
      if (events[i].block == events[i + 1].block) {
        gaps.add(events[i + 1].column - events[i].column);
      }
    }
    final unit = _mostCommon(gaps) ?? 2;
    double beatsFor(int gap, {double max = 4}) {
      final raw = gap / unit;
      return ((raw * 4).round() / 4).clamp(0.25, max);
    }

    return <TabNote>[
      for (var i = 0; i < events.length; i++)
        TabNote(
          string: events[i].string,
          fret: events[i].fret,
          section: events[i].section,
          beats: i + 1 < events.length && events[i].block == events[i + 1].block
              ? beatsFor(events[i + 1].column - events[i].column)
              // Last note of a block: its trailing dashes, at most two beats.
              : beatsFor(events[i].blockEnd - events[i].column, max: 2),
        ),
    ];
  }

  static int? _mostCommon(List<int> values) {
    if (values.isEmpty) return null;
    final counts = <int, int>{};
    for (final v in values) {
      counts[v] = (counts[v] ?? 0) + 1;
    }
    var best = values.first;
    for (final entry in counts.entries) {
      final current = counts[best]!;
      if (entry.value > current ||
          (entry.value == current && entry.key < best)) {
        best = entry.key;
      }
    }
    return best;
  }

  /// Writes [notes] back as a six-line ASCII tab, four characters per beat.
  static String format(List<TabNote> notes, {int beatsPerLine = 16}) {
    final buffer = StringBuffer();
    var section = '';
    var start = 0;
    while (start < notes.length) {
      if (notes[start].section != section) {
        section = notes[start].section;
        if (buffer.isNotEmpty) buffer.writeln();
        if (section.isNotEmpty) buffer.writeln('[$section]');
      }
      final rows = List<StringBuffer>.generate(6, (_) => StringBuffer('-'));
      var beats = 0.0;
      var i = start;
      while (i < notes.length &&
          notes[i].section == section &&
          (beats < beatsPerLine || i == start)) {
        final note = notes[i];
        final width = (note.beats * 4).round().clamp(2, 16);
        final text = '${note.fret}';
        for (var s = 0; s < 6; s++) {
          final cell = s == note.string
              ? text.padRight(width, '-')
              : ''.padRight(width, '-');
          rows[s].write(cell);
        }
        beats += note.beats;
        i++;
      }
      for (var s = 5; s >= 0; s--) {
        buffer.writeln('${TabNote.stringNames[s]}|${rows[s]}|');
      }
      start = i;
    }
    return buffer.toString().trimRight();
  }
}

class _Event {
  const _Event({
    required this.column,
    required this.string,
    required this.fret,
    required this.section,
    required this.block,
    required this.blockEnd,
  });

  final int column;
  final int string;
  final int fret;
  final String section;
  final int block;
  final int blockEnd;
}
