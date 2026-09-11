import 'dart:math' as math;
import 'dart:ui' show Offset, Rect;

/// Which hand a set of landmarks belongs to, from the *learner's* point of
/// view (a right-handed player frets with the left hand).
enum Handedness { left, right, unknown }

/// One of the 21 MediaPipe hand landmarks, normalised to the video frame
/// (x to the right, y downwards, both 0..1; z is relative depth).
class HandLandmark {
  const HandLandmark(this.x, this.y, [this.z = 0]);

  final double x;
  final double y;
  final double z;

  Offset get offset => Offset(x, y);

  double distanceTo(HandLandmark other) =>
      math.sqrt(math.pow(x - other.x, 2) + math.pow(y - other.y, 2));
}

/// MediaPipe landmark indices.
class HandLandmarkIndex {
  const HandLandmarkIndex._();

  static const int wrist = 0;
  static const int thumbCmc = 1;
  static const int thumbMcp = 2;
  static const int thumbIp = 3;
  static const int thumbTip = 4;
  static const int indexMcp = 5;
  static const int indexPip = 6;
  static const int indexDip = 7;
  static const int indexTip = 8;
  static const int middleMcp = 9;
  static const int middlePip = 10;
  static const int middleDip = 11;
  static const int middleTip = 12;
  static const int ringMcp = 13;
  static const int ringPip = 14;
  static const int ringDip = 15;
  static const int ringTip = 16;
  static const int pinkyMcp = 17;
  static const int pinkyPip = 18;
  static const int pinkyDip = 19;
  static const int pinkyTip = 20;

  /// Skeleton connections for drawing.
  static const List<(int, int)> connections = <(int, int)>[
    (0, 1),
    (1, 2),
    (2, 3),
    (3, 4),
    (0, 5),
    (5, 6),
    (6, 7),
    (7, 8),
    (5, 9),
    (9, 10),
    (10, 11),
    (11, 12),
    (9, 13),
    (13, 14),
    (14, 15),
    (15, 16),
    (13, 17),
    (17, 18),
    (18, 19),
    (19, 20),
    (0, 17),
  ];

  /// Fingertip landmark for a chord-diagram finger number
  /// (1 index, 2 middle, 3 ring, 4 pinky, 5 thumb).
  static int tipForFinger(int finger) {
    switch (finger) {
      case 1:
        return indexTip;
      case 2:
        return middleTip;
      case 3:
        return ringTip;
      case 4:
        return pinkyTip;
      case 5:
        return thumbTip;
      default:
        return indexTip;
    }
  }

  static (int mcp, int pip, int tip) jointsForFinger(int finger) {
    switch (finger) {
      case 1:
        return (indexMcp, indexPip, indexTip);
      case 2:
        return (middleMcp, middlePip, middleTip);
      case 3:
        return (ringMcp, ringPip, ringTip);
      case 4:
        return (pinkyMcp, pinkyPip, pinkyTip);
      default:
        return (thumbMcp, thumbIp, thumbTip);
    }
  }
}

class Hand {
  const Hand({
    required this.handedness,
    required this.score,
    required this.landmarks,
  });

  final Handedness handedness;
  final double score;

  /// Exactly 21 landmarks in MediaPipe order.
  final List<HandLandmark> landmarks;

  HandLandmark operator [](int index) => landmarks[index];

  HandLandmark get wrist => landmarks[HandLandmarkIndex.wrist];
  HandLandmark get indexMcp => landmarks[HandLandmarkIndex.indexMcp];
  HandLandmark get middleMcp => landmarks[HandLandmarkIndex.middleMcp];

  HandLandmark fingertip(int finger) =>
      landmarks[HandLandmarkIndex.tipForFinger(finger)];

  /// Bounding box in normalised coordinates.
  Rect get bounds {
    var minX = 1.0, minY = 1.0, maxX = 0.0, maxY = 0.0;
    for (final l in landmarks) {
      if (l.x < minX) minX = l.x;
      if (l.y < minY) minY = l.y;
      if (l.x > maxX) maxX = l.x;
      if (l.y > maxY) maxY = l.y;
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  /// Approximate hand size (wrist → middle MCP), used to scale overlays.
  double get palmLength => wrist.distanceTo(middleMcp);

  /// 0 = fully straight, 1 = fully curled, for finger 1..4.
  double curl(int finger) {
    final (mcp, pip, tip) = HandLandmarkIndex.jointsForFinger(finger);
    final a = landmarks[mcp];
    final b = landmarks[pip];
    final c = landmarks[tip];
    final v1x = a.x - b.x, v1y = a.y - b.y;
    final v2x = c.x - b.x, v2y = c.y - b.y;
    final dot = v1x * v2x + v1y * v2y;
    final n1 = math.sqrt(v1x * v1x + v1y * v1y);
    final n2 = math.sqrt(v2x * v2x + v2y * v2y);
    if (n1 == 0 || n2 == 0) return 0;
    final cos = (dot / (n1 * n2)).clamp(-1.0, 1.0);
    final angle = math.acos(cos); // pi = straight
    return (1 - angle / math.pi).clamp(0.0, 1.0) * 2;
  }
}

/// All hands detected in one video frame.
class HandFrame {
  const HandFrame({
    required this.hands,
    required this.timestampMs,
    required this.imageWidth,
    required this.imageHeight,
    this.mirrored = true,
  });

  static const HandFrame empty = HandFrame(
    hands: <Hand>[],
    timestampMs: 0,
    imageWidth: 0,
    imageHeight: 0,
  );

  final List<Hand> hands;
  final int timestampMs;
  final int imageWidth;
  final int imageHeight;

  /// True when the preview is shown mirrored (front camera); overlay x
  /// coordinates must then be flipped.
  final bool mirrored;

  bool get hasHands => hands.isNotEmpty;

  /// Blends this frame towards [previous] so the overlay stops jittering.
  HandFrame smoothedFrom(HandFrame? previous, {double factor = 0.5}) {
    if (previous == null || previous.hands.length != hands.length) return this;
    final blended = <Hand>[];
    for (var i = 0; i < hands.length; i++) {
      final before = previous.hands[i];
      final now = hands[i];
      if (before.handedness != now.handedness) return this;
      blended.add(
        Hand(
          handedness: now.handedness,
          score: now.score,
          landmarks: List<HandLandmark>.generate(
            now.landmarks.length,
            (j) => HandLandmark(
              before[j].x + (now[j].x - before[j].x) * factor,
              before[j].y + (now[j].y - before[j].y) * factor,
              before[j].z + (now[j].z - before[j].z) * factor,
            ),
            growable: false,
          ),
        ),
      );
    }
    return HandFrame(
      hands: blended,
      timestampMs: timestampMs,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      mirrored: mirrored,
    );
  }

  Hand? handFor(Handedness handedness) {
    for (final hand in hands) {
      if (hand.handedness == handedness) return hand;
    }
    return null;
  }

  /// The hand that frets (left for right-handed players).
  Hand? frettingHand({bool leftHanded = false}) =>
      handFor(leftHanded ? Handedness.right : Handedness.left) ??
      (hands.length == 1 ? null : null);

  /// The hand that strums (right for right-handed players).
  Hand? strummingHand({bool leftHanded = false}) =>
      handFor(leftHanded ? Handedness.left : Handedness.right);
}
