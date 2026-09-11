import 'dart:async';
import 'dart:math' as math;

import '../../data/content/chord_library.dart';
import '../../models/chord_voicing.dart';
import '../../models/strumming_pattern.dart';
import '../../models/user_settings.dart';
import '../analysis/chord_detector.dart';
import '../analysis/chord_shape_coach.dart';
import '../analysis/hand_motion_tracker.dart';
import '../analysis/onset_detector.dart';
import '../analysis/timing_scorer.dart';
import '../models/audio_frame.dart';
import '../models/chord_detection.dart';
import '../models/hand_frame.dart';
import '../models/strum_event.dart';
import 'practice_plan.dart';

enum TeacherPhase { idle, countIn, running, paused, finished }

enum CoachTone { info, good, warn }

class CoachMessage {
  const CoachMessage(this.text, {this.tone = CoachTone.info, this.atMs = 0});

  final String text;
  final CoachTone tone;
  final int atMs;
}

/// Everything the UI needs to render one frame of the lesson.
class TeacherSnapshot {
  const TeacherSnapshot({
    required this.phase,
    required this.plan,
    this.elapsedMs = 0,
    this.beat = 0,
    this.countInBeatsLeft = 0,
    this.targetIndex = -1,
    this.currentTarget,
    this.nextTarget,
    this.targetVoicing,
    this.nextVoicing,
    this.detection,
    this.lastStrum,
    this.lastTiming,
    this.recentTimings = const <SlotTiming>[],
    this.chordAccuracy = 0,
    this.timingAccuracy = 1,
    this.chordsPlayed = 0,
    this.mistakes = 0,
    this.strums = 0,
    this.message,
    this.hands = HandFrame.empty,
    this.shape = ShapeFeedback.none,
    this.visionActive = false,
    this.audioActive = false,
  });

  final TeacherPhase phase;
  final PracticePlan plan;
  final int elapsedMs;
  final double beat;
  final int countInBeatsLeft;
  final int targetIndex;
  final ChordTarget? currentTarget;
  final ChordTarget? nextTarget;
  final ChordVoicing? targetVoicing;
  final ChordVoicing? nextVoicing;
  final ChordDetection? detection;
  final StrumEvent? lastStrum;
  final SlotTiming? lastTiming;
  final List<SlotTiming> recentTimings;
  final double chordAccuracy; // 0..1
  final double timingAccuracy; // 0..1
  final int chordsPlayed;
  final int mistakes;
  final int strums;
  final CoachMessage? message;
  final HandFrame hands;
  final ShapeFeedback shape;
  final bool visionActive;
  final bool audioActive;

  bool get isActive =>
      phase == TeacherPhase.countIn || phase == TeacherPhase.running;

  int get bar => beat < 0 ? 0 : beat ~/ plan.beatsPerBar + 1;

  int get beatInBar => beat < 0 ? 0 : (beat.floor() % plan.beatsPerBar) + 1;

  /// Index into the strumming pattern's slots for the current position.
  int get slotIndex => beat < 0
      ? -1
      : ((beat * 2).floor()) % math.max(1, plan.pattern.slots.length);

  double get progress =>
      plan.totalBeats <= 0 ? 0 : (beat / plan.totalBeats).clamp(0.0, 1.0);

  double get targetProgress => currentTarget?.progressAt(beat) ?? 0;

  /// Combined score 0..100.
  double get overallScore {
    final timingWeight = strums > 0 ? 0.4 : 0.0;
    final chordWeight = 1 - timingWeight;
    return ((chordAccuracy * chordWeight + timingAccuracy * timingWeight) * 100)
        .clamp(0.0, 100.0);
  }
}

/// Orchestrates detectors, the metronome clock, scoring and coaching.
///
/// Feed it audio ([onAudio]) and hand landmarks ([onHands]); it publishes
/// [TeacherSnapshot]s on [stream]. The clock is injectable for tests.
class TeacherEngine {
  TeacherEngine({
    required PracticePlan plan,
    required this.chordLibrary,
    this.settings = const UserSettings(),
    int Function()? clock,
    this.countInBeats = 4,
    this.autoTick = true,
  }) : _plan = plan,
       _clock = clock ?? (() => DateTime.now().millisecondsSinceEpoch),
       _timing = TimingScorer(pattern: plan.pattern, bpm: plan.bpm),
       _motion = HandMotionTracker(leftHanded: settings.leftHanded) {
    _emit();
  }

  final ChordLibrary chordLibrary;
  UserSettings settings;
  final int countInBeats;
  final bool autoTick;

  /// Called on every metronome beat (accent on beat 1).
  void Function(int beatInBar, bool accent)? onMetronomeBeat;

  PracticePlan _plan;
  final int Function() _clock;
  final TimingScorer _timing;
  final HandMotionTracker _motion;
  final ChordShapeCoach _coach = const ChordShapeCoach();
  ChordDetector? _chordDetector;
  OnsetDetector? _onsetDetector;

  final StreamController<TeacherSnapshot> _controller =
      StreamController<TeacherSnapshot>.broadcast();
  Timer? _ticker;

  TeacherPhase _phase = TeacherPhase.idle;
  int _startMs = 0;
  int _runStartMs = 0;
  int _pausedAccumMs = 0;
  int _pauseStartMs = 0;
  int _lastClickedBeat = -1;
  int _lastClickMs = -100000;

  // stats
  int _detTotal = 0;
  int _detCorrect = 0;
  int _targetDetections = 0;
  int _targetCorrect = 0;
  int _lastTargetIndex = -1;
  int _chordsPlayed = 0;
  int _mistakes = 0;
  int _strums = 0;
  int _lastSoundMs = 0;
  ChordDetection? _lastDetection;
  StrumEvent? _lastStrum;
  SlotTiming? _lastTiming;
  HandFrame _lastHands = HandFrame.empty;
  int _lastHandsMs = 0;
  int _lastFrettingSeenMs = 0;
  ShapeFeedback _shape = ShapeFeedback.none;
  int _lastShapeMs = 0;
  bool _audioActive = false;

  // coaching
  CoachMessage? _message;
  int _lastMessageMs = -100000;
  int _wrongStreak = 0;
  int _goodStreak = 0;
  int _lateStreak = 0;
  int _earlyStreak = 0;
  int _announcedNextIndex = -1;
  String? _lastWrongChord;

  late TeacherSnapshot _snapshot = TeacherSnapshot(
    phase: TeacherPhase.idle,
    plan: _plan,
  );

  Stream<TeacherSnapshot> get stream => _controller.stream;
  TeacherSnapshot get snapshot => _snapshot;
  PracticePlan get plan => _plan;
  TeacherPhase get phase => _phase;

  double get beatMs => 60000 / _plan.bpm;

  /// Milliseconds since the running phase started (negative in count-in).
  int get elapsedRunMs {
    final now = _phase == TeacherPhase.paused ? _pauseStartMs : _clock();
    switch (_phase) {
      case TeacherPhase.idle:
        return 0;
      case TeacherPhase.countIn:
        return now - _startMs - (countInBeats * beatMs).round();
      case TeacherPhase.running:
      case TeacherPhase.paused:
        return now - _runStartMs - _pausedAccumMs;
      case TeacherPhase.finished:
        return _snapshot.elapsedMs;
    }
  }

  double get beat => elapsedRunMs / beatMs;

  // ------------------------------------------------------------------ control

  void start() {
    if (_phase == TeacherPhase.countIn || _phase == TeacherPhase.running) {
      return;
    }
    _resetStats();
    _phase = TeacherPhase.countIn;
    _startMs = _clock();
    _pausedAccumMs = 0;
    _lastClickedBeat = -1;
    _message = const CoachMessage('Get ready…');
    _emit();
    if (autoTick) {
      _ticker?.cancel();
      _ticker = Timer.periodic(const Duration(milliseconds: 33), (_) => tick());
    }
  }

  void pause() {
    if (_phase != TeacherPhase.running) return;
    _phase = TeacherPhase.paused;
    _pauseStartMs = _clock();
    _message = const CoachMessage('Paused');
    _emit();
  }

  void resume() {
    if (_phase != TeacherPhase.paused) return;
    _pausedAccumMs += _clock() - _pauseStartMs;
    _phase = TeacherPhase.running;
    _message = const CoachMessage('Go!', tone: CoachTone.good);
    _emit();
  }

  void stop() {
    if (_phase == TeacherPhase.idle || _phase == TeacherPhase.finished) return;
    _closeTarget();
    _phase = TeacherPhase.finished;
    _ticker?.cancel();
    _ticker = null;
    _message = CoachMessage(
      _finishText(),
      tone: _snapshot.overallScore >= 70 ? CoachTone.good : CoachTone.info,
    );
    _emit();
  }

  void dispose() {
    _ticker?.cancel();
    _controller.close();
  }

  void setBpm(int bpm) {
    if (bpm == _plan.bpm) return;
    _plan = _plan.copyWith(bpm: bpm);
    _timing.bpm = bpm;
    if (_phase != TeacherPhase.idle && _phase != TeacherPhase.finished) {
      // keep the current beat position stable across the tempo change
      final currentBeat = beat;
      _runStartMs =
          _clock() - _pausedAccumMs - (currentBeat * 60000 / bpm).round();
      _timing.reset();
    }
    _emit();
  }

  void setCapo(int capo) {
    _plan = _plan.copyWith(capo: capo);
    _chordDetector?.setCandidates(_plan.chords);
    _emit();
  }

  void setSettings(UserSettings value) {
    settings = value;
    _motion.leftHanded = value.leftHanded;
  }

  // ------------------------------------------------------------------- inputs

  void onAudio(AudioFrame frame) {
    _audioActive = true;
    if (_phase != TeacherPhase.running && _phase != TeacherPhase.countIn) {
      return;
    }
    final chordDetector = _chordDetector ??= ChordDetector(
      sampleRate: frame.sampleRate,
      candidates: _plan.chords,
    );
    final onsetDetector = _onsetDetector ??= OnsetDetector(
      sampleRate: frame.sampleRate,
    );

    final target = _plan.targetAt(beat);
    chordDetector.target = target?.chord;

    for (final detection in chordDetector.feed(frame)) {
      _handleDetection(detection);
    }
    for (final onset in onsetDetector.feed(frame)) {
      _handleOnset(onset);
    }
  }

  void onHands(HandFrame frame) {
    _lastHands = frame;
    _lastHandsMs = _clock();
    _motion.add(frame);
    final fretting =
        frame.frettingHand(leftHanded: settings.leftHanded) ??
        (frame.hands.length == 1 ? frame.hands.first : null);
    if (fretting != null) _lastFrettingSeenMs = _lastHandsMs;
    if (_lastHandsMs - _lastShapeMs >= 120) {
      _lastShapeMs = _lastHandsMs;
      final voicing = _voicingFor(_plan.targetAt(beat)?.chord);
      _shape = voicing == null
          ? ShapeFeedback.none
          : _coach.evaluate(voicing: voicing, frettingHand: fretting);
      if (_phase == TeacherPhase.idle) _emit();
    }
  }

  // --------------------------------------------------------------------- tick

  /// Advances the clock; call at ~30 Hz (done automatically when [autoTick]).
  void tick() {
    final now = _clock();
    if (_phase == TeacherPhase.countIn) {
      final elapsed = now - _startMs;
      final beatIndex = (elapsed / beatMs).floor();
      if (beatIndex != _lastClickedBeat && beatIndex < countInBeats) {
        _lastClickedBeat = beatIndex;
        _click(beatIndex == 0);
        _message = CoachMessage('Get ready… ${countInBeats - beatIndex}');
      }
      if (elapsed >= countInBeats * beatMs) {
        _phase = TeacherPhase.running;
        _runStartMs = now;
        _lastClickedBeat = -1;
        _lastSoundMs = now;
        _timing.reset();
        _message = const CoachMessage('Go!', tone: CoachTone.good);
      }
      _emit();
      return;
    }
    if (_phase != TeacherPhase.running) {
      return;
    }

    final currentBeat = beat;
    final beatIndex = currentBeat.floor();
    if (beatIndex != _lastClickedBeat && currentBeat >= 0) {
      _lastClickedBeat = beatIndex;
      _click(beatIndex % _plan.beatsPerBar == 0);
    }

    // scoring bookkeeping
    final missed = _timing.collectMisses(elapsedRunMs);
    if (missed.isNotEmpty) {
      _lastTiming = missed.last;
    }
    final index = _plan.indexAt(currentBeat);
    if (index != _lastTargetIndex) {
      _closeTarget();
      _lastTargetIndex = index;
      _targetDetections = 0;
      _targetCorrect = 0;
      _wrongStreak = 0;
    }

    if (currentBeat >= _plan.totalBeats && _plan.totalBeats > 0) {
      stop();
      return;
    }

    _coachTick(now, currentBeat);
    _emit();
  }

  // ---------------------------------------------------------------- internals

  void _resetStats() {
    _detTotal = 0;
    _detCorrect = 0;
    _targetDetections = 0;
    _targetCorrect = 0;
    _lastTargetIndex = -1;
    _chordsPlayed = 0;
    _mistakes = 0;
    _strums = 0;
    _lastDetection = null;
    _lastStrum = null;
    _lastTiming = null;
    _wrongStreak = 0;
    _goodStreak = 0;
    _lateStreak = 0;
    _earlyStreak = 0;
    _announcedNextIndex = -1;
    _lastWrongChord = null;
    _timing.reset();
    _chordDetector?.reset();
    _onsetDetector?.reset();
    _motion.reset();
  }

  void _closeTarget() {
    if (_lastTargetIndex < 0) return;
    if (_targetDetections > 0) {
      _chordsPlayed++;
      if (_targetCorrect / _targetDetections < 0.5) _mistakes++;
    }
  }

  void _click(bool accent) {
    _lastClickMs = _clock();
    if (settings.metronomeEnabled) {
      onMetronomeBeat?.call((_lastClickedBeat % _plan.beatsPerBar) + 1, accent);
    }
  }

  ChordVoicing? _voicingFor(String? chord) =>
      chord == null ? null : chordLibrary.voicingFor(chord);

  static bool sameChordFamily(String? a, String? b) {
    if (a == null || b == null) return false;
    final na = ChordLibrary.normalizeName(a).split('/').first;
    final nb = ChordLibrary.normalizeName(b).split('/').first;
    if (na == nb) return true;
    if (ChordLibrary.rootIndex(na) != ChordLibrary.rootIndex(nb)) return false;
    bool minor(String s) {
      final suffix = ChordLibrary.suffixOf(s);
      return suffix.startsWith('m') && !suffix.startsWith('maj');
    }

    return minor(na) == minor(nb);
  }

  void _handleDetection(ChordDetection detection) {
    _lastDetection = detection;
    if (_phase != TeacherPhase.running) return;
    if (detection.isSilent) return;
    _lastSoundMs = _clock();

    final currentBeat = beat;
    final target = _plan.targetAt(currentBeat);
    if (target == null) return;
    // grace period right after a change so transitions are not penalised
    final msIntoTarget = (currentBeat - target.startBeat) * beatMs;
    if (msIntoTarget < 350) return;

    _detTotal++;
    _targetDetections++;
    if (sameChordFamily(detection.chord, target.chord)) {
      _detCorrect++;
      _targetCorrect++;
      _goodStreak++;
      _wrongStreak = 0;
    } else {
      _wrongStreak++;
      _goodStreak = 0;
      _lastWrongChord = detection.chord;
    }
  }

  void _handleOnset(StrumEvent onset) {
    if (_phase != TeacherPhase.running) return;
    // the metronome click itself can register as an onset on open speakers
    if (onset.timestampMs - _lastClickMs >= 0 &&
        onset.timestampMs - _lastClickMs < 70) {
      return;
    }
    final direction = _lastHandsMs > 0
        ? _motion.directionAt(onset.timestampMs)
        : null;
    final strum = onset.withDirection(direction);
    _lastStrum = strum;
    _strums++;
    final elapsed = strum.timestampMs - _runStartMs - _pausedAccumMs;
    if (elapsed < 0) return;
    final timing = _timing.onStrum(strum, elapsed);
    _lastTiming = timing;
    switch (timing.result) {
      case TimingResult.late:
        _lateStreak++;
        _earlyStreak = 0;
      case TimingResult.early:
        _earlyStreak++;
        _lateStreak = 0;
      default:
        _lateStreak = 0;
        _earlyStreak = 0;
    }
  }

  bool get _visionActive => _lastHandsMs > 0 && _clock() - _lastHandsMs < 1500;

  void _say(String text, CoachTone tone, int now, {int cooldownMs = 2200}) {
    if (now - _lastMessageMs < cooldownMs) return;
    _lastMessageMs = now;
    _message = CoachMessage(text, tone: tone, atMs: now);
  }

  void _coachTick(int now, double currentBeat) {
    final target = _plan.targetAt(currentBeat);
    final next = _plan.nextAfter(currentBeat);
    final index = _plan.indexAt(currentBeat);

    // upcoming change – announced one beat ahead, once per target
    if (next != null &&
        next.startBeat - currentBeat <= 1.0 &&
        next.chord != target?.chord &&
        _announcedNextIndex != index) {
      _announcedNextIndex = index;
      _lastMessageMs = now;
      _message = CoachMessage('Next: ${next.chord}', atMs: now);
      return;
    }

    if (_visionActive && now - _lastFrettingSeenMs > 2000) {
      _say(
        'Show your fretting hand to the camera so I can guide your fingers.',
        CoachTone.warn,
        now,
      );
      return;
    }

    final silentMs = now - _lastSoundMs;
    if (_audioActive && silentMs > beatMs * _plan.beatsPerBar * 1.5) {
      _say('Strum the strings — I can\'t hear you yet.', CoachTone.warn, now);
      return;
    }

    if (_wrongStreak >= 3 && target != null) {
      final heard = _lastWrongChord;
      final hint = _shape.handVisible && _shape.hints.isNotEmpty
          ? ' ${_shape.hints.first}'
          : '';
      _say(
        heard == null
            ? 'That doesn\'t sound like ${target.chord} yet.$hint'
            : 'That sounds like $heard — target is ${target.chord}.$hint',
        CoachTone.warn,
        now,
      );
      _wrongStreak = 0;
      return;
    }

    if (_lateStreak >= 3) {
      _say(
        'You\'re strumming late — relax and land on the click.',
        CoachTone.warn,
        now,
      );
      _lateStreak = 0;
      return;
    }
    if (_earlyStreak >= 3) {
      _say('You\'re rushing — wait for the click.', CoachTone.warn, now);
      _earlyStreak = 0;
      return;
    }

    final lastTiming = _lastTiming;
    if (lastTiming != null &&
        lastTiming.directionMismatch &&
        now - (lastTiming.actualMs ?? 0) - _runStartMs < 600) {
      final arrow = StrummingPattern.arrow(lastTiming.expectedStroke!);
      _say(
        '${lastTiming.expectedStroke == StrokeType.down ? 'Downstroke' : 'Upstroke'} here $arrow',
        CoachTone.warn,
        now,
        cooldownMs: 1500,
      );
      return;
    }

    if (_goodStreak >= 5 && target != null) {
      _say(
        'Clean ${target.chord}! Keep it going.',
        CoachTone.good,
        now,
        cooldownMs: 4000,
      );
      _goodStreak = 0;
    }
  }

  String _finishText() {
    final score = _snapshot.overallScore;
    if (score >= 85) return 'Excellent! ${score.round()}% — that was clean.';
    if (score >= 65) {
      return 'Nice work: ${score.round()}%. A little more polish and it\'s there.';
    }
    if (_detTotal == 0) {
      return 'Session saved. Next time turn on the mic so I can hear you.';
    }
    return 'Good effort: ${score.round()}%. Slow the tempo down and try again.';
  }

  void _emit() {
    final currentBeat = _phase == TeacherPhase.idle ? -1.0 : beat;
    final target = _phase == TeacherPhase.idle
        ? (_plan.targets.isEmpty ? null : _plan.targets.first)
        : _plan.targetAt(currentBeat);
    final next = _phase == TeacherPhase.idle
        ? (_plan.targets.length > 1 ? _plan.targets[1] : null)
        : _plan.nextAfter(currentBeat);
    final countInLeft = _phase == TeacherPhase.countIn
        ? (countInBeats - ((_clock() - _startMs) / beatMs).floor()).clamp(
            0,
            countInBeats,
          )
        : 0;
    _snapshot = TeacherSnapshot(
      phase: _phase,
      plan: _plan,
      elapsedMs: _phase == TeacherPhase.idle ? 0 : math.max(0, elapsedRunMs),
      beat: _phase == TeacherPhase.idle ? 0 : currentBeat,
      countInBeatsLeft: countInLeft,
      targetIndex: _phase == TeacherPhase.idle ? 0 : _plan.indexAt(currentBeat),
      currentTarget: target,
      nextTarget: next,
      targetVoicing: _voicingFor(target?.chord),
      nextVoicing: _voicingFor(next?.chord),
      detection: _lastDetection,
      lastStrum: _lastStrum,
      lastTiming: _lastTiming,
      recentTimings: List<SlotTiming>.unmodifiable(_timing.recent),
      chordAccuracy: _detTotal == 0 ? 0 : _detCorrect / _detTotal,
      timingAccuracy: _timing.accuracy,
      chordsPlayed: _chordsPlayed,
      mistakes: _mistakes,
      strums: _strums,
      message: _message,
      hands: _lastHands,
      shape: _shape,
      visionActive: _visionActive,
      audioActive: _audioActive,
    );
    if (!_controller.isClosed) _controller.add(_snapshot);
  }
}
