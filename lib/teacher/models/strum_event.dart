import '../../models/strumming_pattern.dart';

/// An attack detected in the audio (a strum or pluck).
class StrumEvent {
  const StrumEvent({
    required this.timestampMs,
    required this.strength,
    this.direction,
  });

  final int timestampMs;

  /// Onset strength relative to the adaptive threshold (>= 1).
  final double strength;

  /// Down/up as inferred from the strumming hand's motion, when known.
  final StrokeType? direction;

  StrumEvent withDirection(StrokeType? direction) => StrumEvent(
    timestampMs: timestampMs,
    strength: strength,
    direction: direction,
  );
}

enum TimingResult { hit, early, late, extra, miss }

/// How one strum lined up with the expected pattern slot.
class SlotTiming {
  const SlotTiming({
    required this.absoluteSlot,
    required this.slotInPattern,
    required this.expectedMs,
    required this.result,
    this.actualMs,
    this.expectedStroke,
    this.playedStroke,
  });

  final int absoluteSlot;
  final int slotInPattern;
  final int expectedMs;
  final int? actualMs;
  final TimingResult result;
  final StrokeType? expectedStroke;
  final StrokeType? playedStroke;

  int get deltaMs => actualMs == null ? 0 : actualMs! - expectedMs;

  bool get isGood => result == TimingResult.hit;

  bool get directionMismatch =>
      expectedStroke != null &&
      playedStroke != null &&
      expectedStroke != StrokeType.mute &&
      expectedStroke != playedStroke;
}
