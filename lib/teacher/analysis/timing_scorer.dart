import '../../models/strumming_pattern.dart';
import '../models/strum_event.dart';

/// Lines strums up against the expected strumming grid.
class TimingScorer {
  TimingScorer({
    required this.pattern,
    required this.bpm,
    this.toleranceMs = 110,
  });

  StrummingPattern pattern;
  int bpm;

  /// |delta| within this is a hit; up to 2x is early/late; beyond is extra.
  final int toleranceMs;

  final Map<int, SlotTiming> _results = <int, SlotTiming>{};
  int _lastCheckedSlot = -1;
  int hits = 0;
  int misses = 0;
  int extras = 0;
  int earlies = 0;
  int lates = 0;
  final List<SlotTiming> recent = <SlotTiming>[];

  double get slotMs => 60000 / bpm / 2;

  /// Timing accuracy 0..1.
  double get accuracy {
    final judged = hits + misses + earlies + lates;
    if (judged == 0) return 1;
    return ((hits + 0.5 * (earlies + lates)) / (judged + 0.5 * extras)).clamp(
      0.0,
      1.0,
    );
  }

  int get judgedCount => hits + misses + earlies + lates;

  void reset() {
    _results.clear();
    _lastCheckedSlot = -1;
    hits = misses = extras = earlies = lates = 0;
    recent.clear();
  }

  StrokeType strokeAt(int absoluteSlot) =>
      pattern.slots[absoluteSlot % pattern.slots.length];

  int expectedMsFor(int absoluteSlot) => (absoluteSlot * slotMs).round();

  /// Judges a strum that happened [elapsedMs] after the pattern started.
  SlotTiming onStrum(StrumEvent strum, int elapsedMs) {
    final nearest = (elapsedMs / slotMs).round();
    // Search the nearest sounding slots around the strum.
    SlotTiming? best;
    for (var slot = nearest - 2; slot <= nearest + 2; slot++) {
      if (slot < 0) continue;
      final stroke = strokeAt(slot);
      if (stroke == StrokeType.rest) continue;
      if (_results.containsKey(slot) &&
          _results[slot]!.result != TimingResult.miss) {
        continue;
      }
      final expected = expectedMsFor(slot);
      final delta = elapsedMs - expected;
      if (delta.abs() > toleranceMs * 2) continue;
      final result = delta.abs() <= toleranceMs
          ? TimingResult.hit
          : (delta < 0 ? TimingResult.early : TimingResult.late);
      final candidate = SlotTiming(
        absoluteSlot: slot,
        slotInPattern: slot % pattern.slots.length,
        expectedMs: expected,
        actualMs: elapsedMs,
        result: result,
        expectedStroke: stroke,
        playedStroke: strum.direction,
      );
      if (best == null || candidate.deltaMs.abs() < best.deltaMs.abs()) {
        best = candidate;
      }
    }

    final timing =
        best ??
        SlotTiming(
          absoluteSlot: nearest,
          slotInPattern: nearest % pattern.slots.length,
          expectedMs: expectedMsFor(nearest),
          actualMs: elapsedMs,
          result: TimingResult.extra,
          expectedStroke: strokeAt(nearest),
          playedStroke: strum.direction,
        );

    switch (timing.result) {
      case TimingResult.hit:
        hits++;
        _results[timing.absoluteSlot] = timing;
      case TimingResult.early:
        earlies++;
        _results[timing.absoluteSlot] = timing;
      case TimingResult.late:
        lates++;
        _results[timing.absoluteSlot] = timing;
      case TimingResult.extra:
        extras++;
      case TimingResult.miss:
        break;
    }
    _push(timing);
    return timing;
  }

  /// Marks sounding slots that passed without a strum as misses.
  List<SlotTiming> collectMisses(int elapsedMs) {
    final missed = <SlotTiming>[];
    final lastPassed = ((elapsedMs - toleranceMs * 2) / slotMs).floor();
    for (var slot = _lastCheckedSlot + 1; slot <= lastPassed; slot++) {
      final stroke = strokeAt(slot);
      if (stroke == StrokeType.rest) continue;
      if (_results.containsKey(slot)) continue;
      final miss = SlotTiming(
        absoluteSlot: slot,
        slotInPattern: slot % pattern.slots.length,
        expectedMs: expectedMsFor(slot),
        result: TimingResult.miss,
        expectedStroke: stroke,
      );
      _results[slot] = miss;
      misses++;
      missed.add(miss);
      _push(miss);
    }
    if (lastPassed > _lastCheckedSlot) _lastCheckedSlot = lastPassed;
    return missed;
  }

  SlotTiming? resultFor(int absoluteSlot) => _results[absoluteSlot];

  void _push(SlotTiming timing) {
    recent.add(timing);
    if (recent.length > 16) recent.removeAt(0);
  }
}
