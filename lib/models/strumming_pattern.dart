import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'strumming_pattern.g.dart';

/// What the strumming hand does on one eighth-note slot.
enum StrokeType { down, up, mute, rest }

/// A strumming pattern expressed as eighth-note slots.
///
/// Patterns are written the way guitarists write them ("D DU UDU",
/// "D - DU - UDU", "DDUUDU", "D X DU X DU"). [parse] turns any of those into
/// a fixed grid of eighth-note slots where downstrokes sit on the beat and
/// upstrokes sit on the "and", which is exactly what the timing engine needs.
@JsonSerializable()
class StrummingPattern extends Equatable {
  const StrummingPattern({
    required this.notation,
    required this.slots,
    this.beatsPerBar = 4,
  });

  factory StrummingPattern.fromJson(Map<String, dynamic> json) =>
      _$StrummingPatternFromJson(json);

  /// Parses guitarist notation into a slot grid.
  ///
  /// Tokens: `D` down, `U` up, `X` (or `M`) muted/percussive, `-`, `.` and `_`
  /// are rests. Spaces and commas only separate groups. A down that would
  /// land on an "and" is pushed to the next beat, and an up that would land
  /// on a beat is pushed to the next "and", so the natural pulse is kept.
  factory StrummingPattern.parse(String notation, {int beatsPerBar = 4}) {
    final cleaned = notation.trim();
    if (cleaned.isEmpty) {
      return StrummingPattern(
        notation: 'D D D D',
        slots: const <StrokeType>[
          StrokeType.down,
          StrokeType.rest,
          StrokeType.down,
          StrokeType.rest,
          StrokeType.down,
          StrokeType.rest,
          StrokeType.down,
          StrokeType.rest,
        ],
        beatsPerBar: beatsPerBar,
      );
    }

    final tokens = <StrokeType?>[];
    final upper = cleaned.toUpperCase();
    // Long-form words ("down-up") are common in scraped data.
    final normalised = upper
        .replaceAll('DOWN', 'D')
        .replaceAll('UP', 'U')
        .replaceAll('MUTE', 'X')
        .replaceAll('REST', '-');
    for (final rune in normalised.runes) {
      final ch = String.fromCharCode(rune);
      switch (ch) {
        case 'D':
          tokens.add(StrokeType.down);
        case 'U':
          tokens.add(StrokeType.up);
        case 'X':
        case 'M':
          tokens.add(StrokeType.mute);
        case '-':
        case '.':
        case '_':
          tokens.add(StrokeType.rest);
        default:
          // separators and anything else are ignored
          break;
      }
    }

    if (tokens.isEmpty) {
      return StrummingPattern.parse('D D D D', beatsPerBar: beatsPerBar);
    }

    final barSlots = beatsPerBar * 2;
    final slots = <StrokeType>[];
    for (final token in tokens) {
      final slotIndex = slots.length;
      final onBeat = slotIndex.isEven;
      if (token == StrokeType.down && !onBeat) {
        slots.add(StrokeType.rest);
      } else if (token == StrokeType.up && onBeat && slots.isNotEmpty) {
        slots.add(StrokeType.rest);
      }
      slots.add(token!);
    }

    // Pad to a whole number of bars (1 or 2 bars are the common cases).
    final bars = (slots.length / barSlots).ceil().clamp(1, 4);
    while (slots.length < bars * barSlots) {
      slots.add(StrokeType.rest);
    }
    if (slots.length > bars * barSlots) {
      slots.removeRange(bars * barSlots, slots.length);
    }

    return StrummingPattern(
      notation: cleaned,
      slots: List<StrokeType>.unmodifiable(slots),
      beatsPerBar: beatsPerBar,
    );
  }

  /// The original notation as written by the author.
  final String notation;

  /// Eighth-note slots, on-beat at even indexes.
  final List<StrokeType> slots;

  final int beatsPerBar;

  Map<String, dynamic> toJson() => _$StrummingPatternToJson(this);

  int get slotsPerBar => beatsPerBar * 2;

  int get bars => (slots.length / slotsPerBar).ceil();

  /// Number of sounding strokes (down/up/mute) in the pattern.
  int get strokeCount => slots.where((s) => s != StrokeType.rest).length;

  /// Compact display string, one glyph per slot ("D - D U - U D U").
  String get gridNotation => slots.map(glyph).join(' ');

  static String glyph(StrokeType type) {
    switch (type) {
      case StrokeType.down:
        return 'D';
      case StrokeType.up:
        return 'U';
      case StrokeType.mute:
        return 'X';
      case StrokeType.rest:
        return '-';
    }
  }

  static String arrow(StrokeType type) {
    switch (type) {
      case StrokeType.down:
        return '↓';
      case StrokeType.up:
        return '↑';
      case StrokeType.mute:
        return '✕';
      case StrokeType.rest:
        return '·';
    }
  }

  @override
  List<Object?> get props => <Object?>[notation, slots, beatsPerBar];
}
