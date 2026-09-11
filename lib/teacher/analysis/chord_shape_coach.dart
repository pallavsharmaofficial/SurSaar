import '../../models/chord_voicing.dart';
import '../models/hand_frame.dart';

/// A marker the AR overlay draws on a fingertip.
class FingerGuide {
  const FingerGuide({
    required this.finger,
    required this.landmark,
    required this.label,
    required this.stringIndex,
    required this.fret,
  });

  final int finger; // 1..4 (5 thumb)
  final HandLandmark landmark;
  final String label; // e.g. "3rd fret · A"
  final int stringIndex; // 0 = low E
  final int fret;
}

class ShapeFeedback {
  const ShapeFeedback({
    required this.handVisible,
    required this.guides,
    required this.hints,
    this.usedFingers = const <int>{},
    this.idleFingers = const <int>{},
  });

  static const ShapeFeedback none = ShapeFeedback(
    handVisible: false,
    guides: <FingerGuide>[],
    hints: <String>[],
  );

  final bool handVisible;
  final List<FingerGuide> guides;
  final List<String> hints;
  final Set<int> usedFingers;
  final Set<int> idleFingers;
}

/// Turns a target voicing + the fretting hand's landmarks into AR guides
/// and short coaching hints.
///
/// This is deliberately conservative: without fretboard registration the
/// camera cannot see which fret a finger is on, so the coach guides which
/// finger goes where and checks posture (curl, spread, hand present)
/// rather than claiming fret-level accuracy.
class ChordShapeCoach {
  const ChordShapeCoach();

  static const List<String> _stringNames = <String>[
    'low E',
    'A',
    'D',
    'G',
    'B',
    'high e',
  ];

  static String _ordinal(int n) {
    if (n == 1) return '1st';
    if (n == 2) return '2nd';
    if (n == 3) return '3rd';
    return '${n}th';
  }

  static String fingerName(int finger) {
    switch (finger) {
      case 1:
        return 'index';
      case 2:
        return 'middle';
      case 3:
        return 'ring';
      case 4:
        return 'pinky';
      case 5:
        return 'thumb';
      default:
        return 'finger';
    }
  }

  /// Where each finger goes for [voicing] – used both for the on-hand AR
  /// labels and the "how to play" text.
  static List<String> placementText(ChordVoicing voicing) {
    final lines = <String>[];
    final coveredByBarre = <int>{};
    for (final barre in voicing.barres) {
      lines.add(
        'Barre the ${_ordinal(barre.fret)} fret from ${_stringNames[barre.startString]} '
        'to ${_stringNames[barre.endString]} with your ${fingerName(barre.finger)}.',
      );
      for (var s = barre.startString; s <= barre.endString; s++) {
        if (voicing.frets[s] == barre.fret) coveredByBarre.add(s);
      }
    }
    for (var s = 0; s < 6; s++) {
      final fret = voicing.frets[s];
      final finger = voicing.fingers[s];
      if (fret <= 0 || finger == 0 || coveredByBarre.contains(s)) continue;
      lines.add(
        '${fingerName(finger)[0].toUpperCase()}${fingerName(finger).substring(1)} '
        'on the ${_ordinal(fret)} fret of the ${_stringNames[s]} string.',
      );
    }
    final muted = <String>[
      for (var s = 0; s < 6; s++)
        if (voicing.frets[s] < 0) _stringNames[s],
    ];
    if (muted.isNotEmpty) {
      lines.add(
        'Skip the ${muted.join(' and ')} string${muted.length > 1 ? 's' : ''}.',
      );
    }
    return lines;
  }

  ShapeFeedback evaluate({required ChordVoicing voicing, Hand? frettingHand}) {
    final used = voicing.usedFingers;
    final idle = <int>{1, 2, 3, 4}.difference(used);
    if (frettingHand == null) {
      return ShapeFeedback(
        handVisible: false,
        guides: const <FingerGuide>[],
        hints: const <String>[
          'Show your fretting hand to the camera so I can guide your fingers.',
        ],
        usedFingers: used,
        idleFingers: idle,
      );
    }

    final guides = <FingerGuide>[];
    final seen = <int>{};
    for (var s = 5; s >= 0; s--) {
      final fret = voicing.frets[s];
      final finger = voicing.fingers[s];
      if (fret <= 0 || finger == 0 || finger > 5) continue;
      if (!seen.add(finger)) continue; // one label per finger (barres)
      guides.add(
        FingerGuide(
          finger: finger,
          landmark: frettingHand.fingertip(finger),
          label: '${_ordinal(fret)} fret · ${_stringNames[s]}',
          stringIndex: s,
          fret: fret,
        ),
      );
    }

    final hints = <String>[];
    if (frettingHand.score < 0.6) {
      hints.add('Bring your fretting hand closer to the camera.');
    }
    for (final finger in used) {
      final curl = frettingHand.curl(finger);
      if (curl < 0.25) {
        hints.add(
          'Curl your ${fingerName(finger)} so only the fingertip touches the string.',
        );
        break;
      }
    }
    if (voicing.barres.isNotEmpty) {
      final indexCurl = frettingHand.curl(1);
      if (indexCurl > 0.55) {
        hints.add(
          'Flatten your index finger across the strings for the barre.',
        );
      }
    }
    if (hints.isEmpty) {
      hints.add(
        'Use your ${used.map(fingerName).join(', ')} for ${voicing.name}.',
      );
    }

    return ShapeFeedback(
      handVisible: true,
      guides: guides,
      hints: hints,
      usedFingers: used,
      idleFingers: idle,
    );
  }
}
