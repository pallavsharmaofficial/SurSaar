import '../../data/content/chord_library.dart';

/// Turns chord symbols into words a speech engine reads naturally
/// ("C#m7" → "C sharp minor seven").
class ChordSpeech {
  const ChordSpeech._();

  static const Map<String, String> _qualities = <String, String>{
    '': '',
    'm': ' minor',
    '7': ' seven',
    'm7': ' minor seven',
    'maj7': ' major seven',
    'sus2': ' sus two',
    'sus4': ' sus four',
    'dim': ' diminished',
    'aug': ' augmented',
    'add9': ' add nine',
    '6': ' six',
    'm6': ' minor six',
    '9': ' nine',
    '5': ' five',
  };

  static String name(String chord) {
    final normalized = ChordLibrary.normalizeName(chord);
    final parts = normalized.split('/');
    final match = RegExp(r'^([A-G])(#?)(.*)$').firstMatch(parts.first);
    if (match == null) return chord;
    final buffer = StringBuffer(match.group(1)!);
    if (match.group(2)!.isNotEmpty) buffer.write(' sharp');
    final suffix = match.group(3)!;
    buffer.write(_qualities[suffix] ?? ' $suffix');
    if (parts.length > 1) {
      buffer.write(' over ${parts[1].replaceAll('#', ' sharp')}');
    }
    return buffer.toString();
  }
}
