import 'dart:math' as math;
import 'dart:ui' show Offset;

import '../models/hand_frame.dart';

/// Where the guitar is in the camera frame, worked out from the two hands.
///
/// The fretting hand sits on the neck and the strumming hand near the sound
/// hole, so the line between them gives the neck direction, and the body
/// continues just past the strumming hand.
class GuitarPose {
  const GuitarPose({
    this.hasNeck = false,
    this.neckStart = Offset.zero,
    this.neckEnd = Offset.zero,
    this.bodyAnchor = const Offset(0.5, 0.82),
    this.confidence = 0,
    this.hint,
  });

  static const GuitarPose none = GuitarPose();

  /// Both hands were found, so the neck line is meaningful.
  final bool hasNeck;

  /// Normalised image coordinates: headstock end and body end of the neck.
  final Offset neckStart;
  final Offset neckEnd;

  /// Where sound appears to come from.
  final Offset bodyAnchor;

  /// 0..1.
  final double confidence;

  /// What the learner should change, if anything.
  final String? hint;

  double get angle =>
      math.atan2(neckEnd.dy - neckStart.dy, neckEnd.dx - neckStart.dx);
}

/// Smooths the pose across frames so overlays sit still.
class GuitarPoseTracker {
  GuitarPoseTracker({this.leftHanded = false, this.smoothing = 0.35});

  bool leftHanded;
  final double smoothing;
  GuitarPose _pose = GuitarPose.none;

  GuitarPose get pose => _pose;

  void reset() => _pose = GuitarPose.none;

  GuitarPose update(HandFrame frame) {
    final fretting = frame.frettingHand(leftHanded: leftHanded);
    final strumming = frame.strummingHand(leftHanded: leftHanded);
    if (fretting == null || strumming == null) {
      final single = frame.hands.length == 1 ? frame.hands.first : null;
      _pose = GuitarPose(
        bodyAnchor: single == null
            ? const Offset(0.5, 0.82)
            : Offset(single.wrist.x, math.min(0.95, single.wrist.y + 0.12)),
        confidence: single == null ? 0 : 0.25,
        hint: frame.hasHands
            ? 'Show both hands so I can see the guitar.'
            : 'Hold your guitar so both hands are in view.',
      );
      return _pose;
    }

    final neck = Offset(fretting.wrist.x, fretting.wrist.y);
    final body = Offset(strumming.wrist.x, strumming.wrist.y);
    final span = (body - neck).distance;
    if (span < 0.08) {
      _pose = GuitarPose(
        bodyAnchor: body,
        confidence: 0.2,
        hint: 'Move back a little so the whole guitar fits.',
      );
      return _pose;
    }
    final direction = (body - neck) / span;
    // headstock sits beyond the fretting hand, the body beyond the strumming
    final head = neck - direction * (span * 0.55);
    final tail = body + direction * (span * 0.30);
    final anchor = body + direction * (span * 0.22);
    final confidence =
        (math.min(fretting.score, strumming.score) *
                (span.clamp(0.1, 0.6) / 0.6))
            .clamp(0.0, 1.0);

    _pose = GuitarPose(
      hasNeck: true,
      neckStart: _lerp(_pose.hasNeck ? _pose.neckStart : head, head),
      neckEnd: _lerp(_pose.hasNeck ? _pose.neckEnd : tail, tail),
      bodyAnchor: _lerp(_pose.hasNeck ? _pose.bodyAnchor : anchor, anchor),
      confidence: confidence,
      hint: span > 0.75 ? 'Come a little closer to the camera.' : null,
    );
    return _pose;
  }

  Offset _lerp(Offset from, Offset to) => Offset(
    from.dx + (to.dx - from.dx) * (1 - smoothing) + 0.0,
    from.dy + (to.dy - from.dy) * (1 - smoothing),
  );
}
