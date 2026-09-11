import '../../models/strumming_pattern.dart';
import '../models/hand_frame.dart';

/// Infers strum direction from the strumming hand's vertical motion.
class HandMotionTracker {
  HandMotionTracker({this.leftHanded = false, this.windowMs = 140});

  bool leftHanded;
  final int windowMs;

  final List<(int, double)> _samples = <(int, double)>[];

  void add(HandFrame frame) {
    final hand =
        frame.strummingHand(leftHanded: leftHanded) ??
        (frame.hands.length == 1 ? frame.hands.first : null);
    if (hand == null) return;
    // index MCP is stable and near the pick; y grows downwards
    _samples.add((frame.timestampMs, hand.indexMcp.y));
    while (_samples.length > 60) {
      _samples.removeAt(0);
    }
  }

  void reset() => _samples.clear();

  /// Down if the hand was moving down around [timestampMs], up if moving
  /// up, null when there is no usable motion.
  StrokeType? directionAt(int timestampMs) {
    if (_samples.length < 2) return null;
    (int, double)? before;
    (int, double)? after;
    for (final s in _samples) {
      if (s.$1 <= timestampMs && s.$1 >= timestampMs - windowMs) before = s;
      if (s.$1 > timestampMs && s.$1 <= timestampMs + windowMs / 2) {
        after ??= s;
      }
    }
    final a = before;
    final b = after ?? (_samples.isNotEmpty ? _samples.last : null);
    if (a == null || b == null || b.$1 == a.$1) return null;
    final dy = b.$2 - a.$2;
    if (dy.abs() < 0.008) return null;
    return dy > 0 ? StrokeType.down : StrokeType.up;
  }
}
