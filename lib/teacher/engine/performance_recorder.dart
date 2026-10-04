import 'dart:math' as math;

import '../analysis/chord_shape_coach.dart';
import '../../models/strumming_pattern.dart';
import '../models/strum_event.dart';

/// How one chord change (or note-to-note move) went.
class TransitionStat {
  TransitionStat(this.from, this.to);

  final String from;
  final String to;
  int count = 0;
  int fails = 0;
  int totalMs = 0;

  String get key => '$from>$to';

  int get successes => count - fails;

  int get averageMs => successes <= 0 ? 0 : totalMs ~/ successes;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'from': from,
    'to': to,
    'count': count,
    'fails': fails,
    'totalMs': totalMs,
  };
}

/// Hits and misses for one song section.
class SectionStat {
  SectionStat(this.name);

  final String name;
  int correct = 0;
  int total = 0;

  double get accuracy => total == 0 ? 0 : correct / total;
}

/// Everything the tutor learned about the player in one session.
///
/// Built by [PerformanceRecorder] from the engine's own events, so it is
/// deterministic and testable without a camera or microphone.
class SessionReport {
  SessionReport({
    required this.isLearn,
    required this.isMelody,
    required this.bpm,
    required this.durationMs,
    required this.score,
    required this.successes,
    required this.skips,
    required this.bestCombo,
    required this.chordResults,
    required this.transitions,
    required this.confusions,
    required this.timingHits,
    required this.timingEarly,
    required this.timingLate,
    required this.timingMisses,
    required this.timingExtras,
    required this.timingOffsetsMs,
    required this.directionChecked,
    required this.directionCorrect,
    required this.upStrokesMissed,
    required this.downStrokesMissed,
    required this.visionTicks,
    required this.handVisibleTicks,
    required this.shapeChecks,
    required this.postureHints,
    required this.averageLevel,
    required this.strums,
    required this.sections,
    required this.noteCentsOffsets,
    required this.noteSemitoneErrors,
    required this.hearItUses,
    required this.hintsShown,
  });

  final bool isLearn;
  final bool isMelody;
  final int bpm;
  final int durationMs;

  /// 0..100.
  final double score;
  final int successes;
  final int skips;
  final int bestCombo;

  /// target → (attempts, successes, average ms to land).
  final Map<String, ({int attempts, int successes, int avgMs, int skips})>
  chordResults;
  final List<TransitionStat> transitions;

  /// target → heard → number of steps / chords where it was heard.
  final Map<String, Map<String, int>> confusions;

  final int timingHits;
  final int timingEarly;
  final int timingLate;
  final int timingMisses;
  final int timingExtras;

  /// Signed strum offsets (actual − expected) of judged strums.
  final List<int> timingOffsetsMs;
  final int directionChecked;
  final int directionCorrect;
  final int upStrokesMissed;
  final int downStrokesMissed;

  final int visionTicks;
  final int handVisibleTicks;
  final int shapeChecks;

  /// Posture hint → how many shape checks showed it.
  final Map<String, int> postureHints;

  /// Microphone level while sounding, 0..1.
  final double averageLevel;
  final int strums;
  final List<SectionStat> sections;

  /// Melody: cents off pitch for notes that were right.
  final List<double> noteCentsOffsets;

  /// Melody: semitone distance of wrong notes (signed: + = too high).
  final List<int> noteSemitoneErrors;
  final int hearItUses;
  final int hintsShown;

  int get judgedStrums => timingHits + timingEarly + timingLate + timingMisses;

  double get minutes => durationMs / 60000;

  /// Mean signed offset; negative = rushing, positive = dragging.
  double? get meanOffsetMs {
    if (timingOffsetsMs.length < 4) return null;
    return timingOffsetsMs.reduce((a, b) => a + b) / timingOffsetsMs.length;
  }

  /// Spread of strum timing (standard deviation).
  double? get offsetSpreadMs {
    if (timingOffsetsMs.length < 4) return null;
    final mean = meanOffsetMs!;
    var sum = 0.0;
    for (final o in timingOffsetsMs) {
      sum += (o - mean) * (o - mean);
    }
    return math.sqrt(sum / timingOffsetsMs.length);
  }

  double? get timingAccuracy {
    final judged = judgedStrums;
    if (judged < 4) return null;
    return (timingHits + 0.5 * (timingEarly + timingLate)) / judged;
  }

  double? get directionAccuracy =>
      directionChecked < 4 ? null : directionCorrect / directionChecked;

  double? get handVisibleRatio =>
      visionTicks < 30 ? null : handVisibleTicks / visionTicks;

  double? get averageCents {
    if (noteCentsOffsets.length < 3) return null;
    return noteCentsOffsets.reduce((a, b) => a + b) / noteCentsOffsets.length;
  }

  /// Transitions sorted slowest first (failed ones count as very slow).
  List<TransitionStat> get slowestTransitions {
    int cost(TransitionStat t) =>
        t.successes == 0 ? 1 << 30 : t.averageMs + t.fails * 4000;
    return transitions.where((t) => t.count > 0).toList()
      ..sort((a, b) => cost(b).compareTo(cost(a)));
  }

  /// Most frequent wrong chord heard for each target, strongest first.
  List<({String target, String heard, int count})> get topConfusions {
    final list = <({String target, String heard, int count})>[
      for (final entry in confusions.entries)
        for (final heard in entry.value.entries)
          (target: entry.key, heard: heard.key, count: heard.value),
    ]..sort((a, b) => b.count.compareTo(a.count));
    return list;
  }

  List<MapEntry<String, int>> get topPostureHints =>
      postureHints.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
}

/// Collects the raw events of a session into a [SessionReport].
class PerformanceRecorder {
  final Map<String, TransitionStat> _transitions = <String, TransitionStat>{};
  final Map<String, Map<String, int>> _confusions =
      <String, Map<String, int>>{};
  final Map<String, int> _wrongThisStep = <String, int>{};
  String? _stepTarget;
  final List<int> _offsets = <int>[];
  final Map<String, int> _posture = <String, int>{};
  final Map<String, SectionStat> _sections = <String, SectionStat>{};
  final List<double> _cents = <double>[];
  final List<int> _semitoneErrors = <int>[];

  int _hits = 0;
  int _early = 0;
  int _late = 0;
  int _misses = 0;
  int _extras = 0;
  int _directionChecked = 0;
  int _directionCorrect = 0;
  int _upMissed = 0;
  int _downMissed = 0;
  int _visionTicks = 0;
  int _handTicks = 0;
  int _shapeChecks = 0;
  double _levelSum = 0;
  int _levelCount = 0;
  int _hearIt = 0;
  int _hints = 0;

  void reset() {
    _transitions.clear();
    _confusions.clear();
    _wrongThisStep.clear();
    _stepTarget = null;
    _offsets.clear();
    _posture.clear();
    _sections.clear();
    _cents.clear();
    _semitoneErrors.clear();
    _hits = _early = _late = _misses = _extras = 0;
    _directionChecked = _directionCorrect = _upMissed = _downMissed = 0;
    _visionTicks = _handTicks = _shapeChecks = 0;
    _levelSum = 0;
    _levelCount = 0;
    _hearIt = _hints = 0;
  }

  /// A new target begins. The previous step's most-heard wrong chord (if it
  /// was heard often enough to be more than the last chord ringing on) is
  /// recorded as one confusion.
  void newStep() {
    final target = _stepTarget;
    if (target != null && _wrongThisStep.isNotEmpty) {
      final top = _wrongThisStep.entries.reduce(
        (a, b) => b.value > a.value ? b : a,
      );
      if (top.value >= 3) {
        final row = _confusions.putIfAbsent(target, () => <String, int>{});
        row[top.key] = (row[top.key] ?? 0) + 1;
      }
    }
    _wrongThisStep.clear();
    _stepTarget = null;
  }

  void transition(String from, String to, {int? ms}) {
    if (from == to) return;
    final stat = _transitions.putIfAbsent(
      '$from>$to',
      () => TransitionStat(from, to),
    );
    stat.count++;
    if (ms == null) {
      stat.fails++;
    } else {
      stat.totalMs += ms;
    }
  }

  /// One analysis frame heard [heard] while [target] was wanted.
  void confusion(String target, String heard) {
    if (heard == target) return;
    _stepTarget = target;
    _wrongThisStep[heard] = (_wrongThisStep[heard] ?? 0) + 1;
  }

  void timing(SlotTiming timing) {
    switch (timing.result) {
      case TimingResult.hit:
        _hits++;
      case TimingResult.early:
        _early++;
      case TimingResult.late:
        _late++;
      case TimingResult.miss:
        _misses++;
        if (timing.expectedStroke == StrokeType.up) _upMissed++;
        if (timing.expectedStroke == StrokeType.down) _downMissed++;
      case TimingResult.extra:
        _extras++;
    }
    if (timing.actualMs != null &&
        timing.result != TimingResult.extra &&
        timing.result != TimingResult.miss) {
      _offsets.add(timing.deltaMs);
    }
    final expected = timing.expectedStroke;
    final played = timing.playedStroke;
    if (expected != null &&
        played != null &&
        expected != StrokeType.mute &&
        expected != StrokeType.rest &&
        timing.result != TimingResult.extra) {
      _directionChecked++;
      if (expected == played) _directionCorrect++;
    }
  }

  void shape(ShapeFeedback feedback) {
    if (!feedback.handVisible) return;
    _shapeChecks++;
    for (final hint in feedback.hints) {
      // "Use your index, middle…" is a reminder, not a posture problem.
      if (hint.startsWith('Use your ')) continue;
      _posture[hint] = (_posture[hint] ?? 0) + 1;
    }
  }

  void visionTick({required bool handVisible}) {
    _visionTicks++;
    if (handVisible) _handTicks++;
  }

  void level(double value) {
    if (value < 0.05) return;
    _levelSum += value;
    _levelCount++;
  }

  void section(String name, {required bool ok}) {
    if (name.isEmpty) return;
    final stat = _sections.putIfAbsent(name, () => SectionStat(name));
    stat.total++;
    if (ok) stat.correct++;
  }

  void noteInTune(double cents) => _cents.add(cents);

  void wrongNote(int semitones) {
    if (semitones != 0) _semitoneErrors.add(semitones);
  }

  void hearIt() => _hearIt++;

  void hint() => _hints++;

  SessionReport build({
    required bool isLearn,
    required bool isMelody,
    required int bpm,
    required int durationMs,
    required double score,
    required int successes,
    required int skips,
    required int bestCombo,
    required Map<String, ({int attempts, int successes, int avgMs, int skips})>
    chordResults,
    required int strums,
  }) {
    newStep();
    return SessionReport(
      isLearn: isLearn,
      isMelody: isMelody,
      bpm: bpm,
      durationMs: durationMs,
      score: score,
      successes: successes,
      skips: skips,
      bestCombo: bestCombo,
      chordResults: chordResults,
      transitions: _transitions.values.toList(growable: false),
      confusions: <String, Map<String, int>>{
        for (final e in _confusions.entries)
          e.key: Map<String, int>.of(e.value),
      },
      timingHits: _hits,
      timingEarly: _early,
      timingLate: _late,
      timingMisses: _misses,
      timingExtras: _extras,
      timingOffsetsMs: List<int>.of(_offsets),
      directionChecked: _directionChecked,
      directionCorrect: _directionCorrect,
      upStrokesMissed: _upMissed,
      downStrokesMissed: _downMissed,
      visionTicks: _visionTicks,
      handVisibleTicks: _handTicks,
      shapeChecks: _shapeChecks,
      postureHints: Map<String, int>.of(_posture),
      averageLevel: _levelCount == 0 ? 0 : _levelSum / _levelCount,
      strums: strums,
      sections: _sections.values.toList(growable: false),
      noteCentsOffsets: List<double>.of(_cents),
      noteSemitoneErrors: List<int>.of(_semitoneErrors),
      hearItUses: _hearIt,
      hintsShown: _hints,
    );
  }
}
