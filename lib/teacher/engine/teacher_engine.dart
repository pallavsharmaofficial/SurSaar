import 'dart:async';
import 'dart:math' as math;

import '../../data/content/chord_library.dart';
import '../../models/chord_voicing.dart';
import '../../models/coaching_mode.dart';
import '../../models/strumming_pattern.dart';
import '../../models/user_settings.dart';
import '../analysis/chord_detector.dart';
import '../analysis/chord_shape_coach.dart';
import '../analysis/guitar_pose.dart';
import '../analysis/hand_motion_tracker.dart';
import '../analysis/onset_detector.dart';
import '../analysis/timing_scorer.dart';
import '../models/audio_frame.dart';
import '../models/chord_detection.dart';
import '../models/hand_frame.dart';
import '../models/strum_event.dart';
import 'chord_speech.dart';
import 'practice_plan.dart';

export '../../models/coaching_mode.dart';

enum TeacherPhase { idle, countIn, running, paused, finished }

enum CoachTone { info, good, warn }

class CoachMessage {
  const CoachMessage(
    this.text, {
    this.tone = CoachTone.info,
    this.atMs = 0,
    this.speak = false,
    this.spoken,
  });

  final String text;
  final CoachTone tone;
  final int atMs;

  /// Worth saying out loud when the voice coach is on.
  final bool speak;

  /// What to say, when it differs from [text].
  final String? spoken;

  String get spokenText => spoken ?? text;
}

enum CueType { correct, missed, skipped, finished }

/// A one-off moment the UI animates (burst, shake…). [id] always increases.
class TeacherCue {
  const TeacherCue({
    required this.id,
    required this.type,
    required this.chord,
    this.combo = 0,
  });

  final int id;
  final CueType type;
  final String chord;
  final int combo;
}

/// How one chord went during the session.
class ChordStat {
  ChordStat(this.chord);

  final String chord;
  int attempts = 0;
  int successes = 0;
  int skips = 0;
  int msToSuccess = 0;

  double get successRate => attempts == 0 ? 0 : successes / attempts;

  int get averageMsToSuccess => successes == 0 ? 0 : msToSuccess ~/ successes;

  /// Worth practising again.
  bool get isTricky =>
      attempts > 0 &&
      (successRate < 0.75 || skips > 0 || averageMsToSuccess > 8000);

  ChordStat copy() => ChordStat(chord)
    ..attempts = attempts
    ..successes = successes
    ..skips = skips
    ..msToSuccess = msToSuccess;
}

/// Everything the UI needs to render one frame of the lesson.
class TeacherSnapshot {
  const TeacherSnapshot({
    required this.phase,
    required this.plan,
    required this.mode,
    this.elapsedMs = 0,
    this.beat = 0,
    this.countInBeatsLeft = 0,
    this.targetIndex = 0,
    this.targetCount = 0,
    this.currentChord,
    this.nextChord,
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
    this.holdProgress = 0,
    this.combo = 0,
    this.bestCombo = 0,
    this.hintLevel = 0,
    this.score = 0,
    this.cue,
    this.stats = const <ChordStat>[],
    this.message,
    this.hands = HandFrame.empty,
    this.shape = ShapeFeedback.none,
    this.visionActive = false,
    this.audioActive = false,
    this.inputLevel = 0,
    this.heardStrum = false,
    this.handSeen = false,
    this.listeningPaused = false,
    this.celebrating = false,
    this.waitingForFreshStrum = false,
    this.pose = GuitarPose.none,
    this.strumId = 0,
  });

  final TeacherPhase phase;
  final PracticePlan plan;
  final CoachingMode mode;
  final int elapsedMs;
  final double beat;
  final int countInBeatsLeft;

  /// Learn mode: step index. Play-along: index of the current chord target.
  final int targetIndex;
  final int targetCount;
  final String? currentChord;
  final String? nextChord;

  /// Play-along only: the beat span of the current / next chord.
  final ChordTarget? currentTarget;
  final ChordTarget? nextTarget;
  final ChordVoicing? targetVoicing;
  final ChordVoicing? nextVoicing;
  final ChordDetection? detection;
  final StrumEvent? lastStrum;
  final SlotTiming? lastTiming;
  final List<SlotTiming> recentTimings;
  final double chordAccuracy;
  final double timingAccuracy;

  /// Learn mode: chords played. Play-along: chords with detections.
  final int chordsPlayed;

  /// Learn mode: skips. Play-along: chords that were not right.
  final int mistakes;
  final int strums;

  /// Learn mode: how close the held chord is to being accepted.
  /// Play-along: how far through the current chord the beat is.
  final double holdProgress;
  final int combo;
  final int bestCombo;
  final int hintLevel;

  /// 0..100.
  final double score;
  final TeacherCue? cue;
  final List<ChordStat> stats;
  final CoachMessage? message;
  final HandFrame hands;
  final ShapeFeedback shape;
  final bool visionActive;
  final bool audioActive;

  /// Microphone level, 0..1.
  final double inputLevel;

  /// A strum has been heard since the microphone started.
  final bool heardStrum;

  /// The fretting hand is in view right now.
  final bool handSeen;

  /// The teacher is ignoring the mic while a reference sound plays.
  final bool listeningPaused;

  /// Learn mode: showing the success moment before the next chord.
  final bool celebrating;

  /// Learn mode: the same chord again – waiting for a new strum.
  final bool waitingForFreshStrum;

  /// Where the guitar is in the camera frame.
  final GuitarPose pose;

  /// Increases on every strum heard, so the UI can react to each one.
  final int strumId;

  bool get isLearn => mode == CoachingMode.learn;

  bool get isActive =>
      phase == TeacherPhase.countIn || phase == TeacherPhase.running;

  int get bar => beat < 0 ? 0 : beat ~/ plan.beatsPerBar + 1;

  int get beatInBar => beat < 0 ? 0 : (beat.floor() % plan.beatsPerBar) + 1;

  /// Index into the strumming pattern's slots for the current position.
  int get slotIndex => beat < 0
      ? -1
      : ((beat * 2).floor()) % math.max(1, plan.pattern.slots.length);

  double get progress {
    if (isLearn) {
      return targetCount == 0 ? 0 : (targetIndex / targetCount).clamp(0.0, 1.0);
    }
    return plan.totalBeats <= 0 ? 0 : (beat / plan.totalBeats).clamp(0.0, 1.0);
  }

  double get targetProgress => currentTarget?.progressAt(beat) ?? 0;

  int get stars => TeacherEngine.starsFor(score);

  int get successes => stats.fold(0, (sum, s) => sum + s.successes);

  int get skips => stats.fold(0, (sum, s) => sum + s.skips);

  List<ChordStat> get trickyChords =>
      stats.where((s) => s.isTricky).toList()
        ..sort((a, b) => a.successRate.compareTo(b.successRate));
}

/// Orchestrates detectors, pacing, scoring and coaching.
///
/// Feed it audio ([onAudio]) and hand landmarks ([onHands]); it publishes
/// [TeacherSnapshot]s on [stream]. The clock is injectable for tests.
class TeacherEngine {
  TeacherEngine({
    required PracticePlan plan,
    required this.chordLibrary,
    this.settings = const UserSettings(),
    CoachingMode mode = CoachingMode.learn,
    int Function()? clock,
    this.countInBeats = 4,
    this.autoTick = true,
  }) : _plan = plan,
       _mode = mode,
       _clock = clock ?? (() => DateTime.now().millisecondsSinceEpoch),
       _timing = TimingScorer(pattern: plan.pattern, bpm: plan.bpm),
       _motion = HandMotionTracker(leftHanded: settings.leftHanded) {
    _emit();
  }

  /// How long the right chord must ring before it counts (learn mode).
  static const int holdToAcceptMs = 400;
  static const int celebrateMs = 900;
  static const int skipPauseMs = 300;
  static const int hintAfterMs = 7000;
  static const int strongHintAfterMs = 15000;

  static int starsFor(double score) => score >= 90
      ? 3
      : score >= 65
      ? 2
      : score >= 30
      ? 1
      : 0;

  /// Lenient match: `G/B` and `Gmaj7` count as `G`, `Gm` does not.
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

  /// Whether [detection] counts as playing [target].
  static bool accepts(ChordDetection detection, String target) {
    if (detection.isSilent) return false;
    if (sameChordFamily(detection.chord, target)) return true;
    final key = ChordLibrary.normalizeName(target).split('/').first;
    final targetScore = detection.scores[key];
    if (targetScore == null) return false;
    var best = 0.0;
    for (final score in detection.scores.values) {
      if (score > best) best = score;
    }
    return targetScore >= 0.8 && best - targetScore <= 0.03;
  }

  final ChordLibrary chordLibrary;
  UserSettings settings;
  final int countInBeats;
  final bool autoTick;

  /// Called on every metronome beat (accent on beat 1).
  void Function(int beatInBar, bool accent)? onMetronomeBeat;

  PracticePlan _plan;
  CoachingMode _mode;
  final int Function() _clock;
  final TimingScorer _timing;
  final HandMotionTracker _motion;
  final GuitarPoseTracker _poseTracker = GuitarPoseTracker();
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
  int _endElapsedMs = 0;
  int _lastClickedBeat = -1;
  int _lastClickMs = -100000;

  // shared results
  int _detTotal = 0;
  int _detCorrect = 0;
  int _strums = 0;
  int _combo = 0;
  int _bestCombo = 0;
  int _cueId = 0;
  TeacherCue? _cue;
  final Map<String, ChordStat> _stats = <String, ChordStat>{};
  ChordDetection? _lastDetection;
  StrumEvent? _lastStrum;
  SlotTiming? _lastTiming;

  // play-along
  int _targetDetections = 0;
  int _targetCorrect = 0;
  int _lastTargetIndex = -1;
  int _chordsPlayed = 0;
  int _mistakes = 0;

  // learn
  int _learnIndex = 0;
  int _holdMs = 0;
  int _stepStartMs = 0;
  int _celebrateUntilMs = 0;
  int _hintLevel = 0;
  int _successes = 0;
  int _skips = 0;
  bool _pendingAdvance = false;
  bool _needsFreshStrum = false;

  // senses
  HandFrame _lastHands = HandFrame.empty;
  int _strumId = 0;
  int _lastHandsMs = 0;
  int _lastFrettingSeenMs = 0;
  int _lastShapeMs = 0;
  int _lastSoundMs = 0;
  int _suppressUntilMs = 0;
  bool _wasSuppressed = false;
  int _lastEmitMs = 0;
  ShapeFeedback _shape = ShapeFeedback.none;
  bool _audioActive = false;
  bool _heardStrum = false;
  double _level = 0;

  // coaching
  CoachMessage? _message;
  int _lastMessageMs = -100000;
  int _wrongStreak = 0;
  int _goodStreak = 0;
  int _lateStreak = 0;
  int _earlyStreak = 0;
  int _announcedNextIndex = -1;
  String? _lastWrongChord;

  late TeacherSnapshot _snapshot;

  Stream<TeacherSnapshot> get stream => _controller.stream;
  TeacherSnapshot get snapshot => _snapshot;
  PracticePlan get plan => _plan;
  TeacherPhase get phase => _phase;
  CoachingMode get mode => _mode;
  List<String> get learnSteps => _plan.learnSteps;

  double get beatMs => 60000 / _plan.bpm;

  /// Milliseconds since the running phase started (negative in count-in).
  int get elapsedRunMs {
    switch (_phase) {
      case TeacherPhase.idle:
        return 0;
      case TeacherPhase.countIn:
        return _clock() - _startMs - (countInBeats * beatMs).round();
      case TeacherPhase.running:
        return _clock() - _runStartMs - _pausedAccumMs;
      case TeacherPhase.paused:
        return _pauseStartMs - _runStartMs - _pausedAccumMs;
      case TeacherPhase.finished:
        return _endElapsedMs;
    }
  }

  double get beat => elapsedRunMs / beatMs;

  String? get _currentChord {
    if (_mode == CoachingMode.learn) {
      final steps = learnSteps;
      if (steps.isEmpty) return null;
      return steps[_learnIndex.clamp(0, steps.length - 1)];
    }
    if (_plan.targets.isEmpty) return null;
    return _phase == TeacherPhase.idle
        ? _plan.targets.first.chord
        : _plan.targetAt(beat)?.chord;
  }

  bool get _visionActive => _lastHandsMs > 0 && _clock() - _lastHandsMs < 1500;

  // ------------------------------------------------------------------ control

  void start() {
    if (_phase == TeacherPhase.countIn || _phase == TeacherPhase.running) {
      return;
    }
    _resetStats();
    final now = _clock();
    _startMs = now;
    _pausedAccumMs = 0;
    _lastClickedBeat = -1;
    if (_mode == CoachingMode.learn) {
      if (learnSteps.isEmpty) return;
      _phase = TeacherPhase.running;
      _runStartMs = now;
      _learnIndex = 0;
      _enterStep(now);
    } else {
      _phase = TeacherPhase.countIn;
      _message = CoachMessage('Get ready…', atMs: now);
    }
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
    _message = CoachMessage('Paused', atMs: _pauseStartMs);
    _emit();
  }

  void resume() {
    if (_phase != TeacherPhase.paused) return;
    final now = _clock();
    final pausedFor = now - _pauseStartMs;
    _pausedAccumMs += pausedFor;
    _stepStartMs += pausedFor;
    _celebrateUntilMs += pausedFor;
    _lastSoundMs = now;
    _phase = TeacherPhase.running;
    _message = CoachMessage(
      "Let's keep going.",
      tone: CoachTone.good,
      atMs: now,
    );
    _emit();
  }

  void stop() {
    if (_phase == TeacherPhase.idle || _phase == TeacherPhase.finished) return;
    if (_mode == CoachingMode.playAlong) {
      _closeTarget();
      _lastTargetIndex = -1;
    }
    _endElapsedMs = math.max(0, elapsedRunMs);
    _phase = TeacherPhase.finished;
    _ticker?.cancel();
    _ticker = null;
    _pendingAdvance = false;
    _pushCue(CueType.finished, '');
    final score = _score();
    final now = _clock();
    _message = CoachMessage(
      _finishText(score),
      tone: score >= 65 ? CoachTone.good : CoachTone.info,
      atMs: now,
      speak: true,
      spoken: _finishSpoken(score),
    );
    _lastMessageMs = now;
    _emit();
  }

  /// Learn mode: move on without playing the current chord.
  void skip() {
    if (_mode != CoachingMode.learn ||
        _phase != TeacherPhase.running ||
        _pendingAdvance ||
        _learnIndex >= learnSteps.length) {
      return;
    }
    _completeLearnStep(success: false);
    _emit();
  }

  void setMode(CoachingMode mode) {
    if (mode == _mode) return;
    if (_phase == TeacherPhase.countIn ||
        _phase == TeacherPhase.running ||
        _phase == TeacherPhase.paused) {
      return;
    }
    _mode = mode;
    _phase = TeacherPhase.idle;
    _resetStats();
    _message = null;
    _emit();
  }

  /// Stops listening for [duration] (e.g. while a reference chord plays).
  void suppressListening(Duration duration) {
    _suppressUntilMs = _clock() + duration.inMilliseconds;
    _holdMs = 0;
    _emit();
  }

  void dispose() {
    _ticker?.cancel();
    _controller.close();
  }

  void setBpm(int bpm) {
    if (bpm == _plan.bpm) return;
    final keepBeat =
        _phase == TeacherPhase.running || _phase == TeacherPhase.paused;
    final currentBeat = beat;
    _plan = _plan.copyWith(bpm: bpm);
    _timing.bpm = bpm;
    if (keepBeat && _mode == CoachingMode.playAlong) {
      final reference = _phase == TeacherPhase.paused
          ? _pauseStartMs
          : _clock();
      _runStartMs =
          reference - _pausedAccumMs - (currentBeat * 60000 / bpm).round();
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
    _updateLevel(frame);
    final chordDetector = _chordDetector ??= ChordDetector(
      sampleRate: frame.sampleRate,
      candidates: _plan.chords,
    );
    final onsetDetector = _onsetDetector ??= OnsetDetector(
      sampleRate: frame.sampleRate,
    );

    if (_clock() < _suppressUntilMs) {
      _wasSuppressed = true;
      _emitIfIdle();
      return;
    }
    if (_wasSuppressed) {
      _wasSuppressed = false;
      chordDetector.reset();
      onsetDetector.reset();
    }

    chordDetector.target = _currentChord;
    for (final detection in chordDetector.feed(frame)) {
      _handleDetection(detection);
    }
    for (final onset in onsetDetector.feed(frame)) {
      _handleOnset(onset);
    }
    _emitIfIdle();
  }

  void onHands(HandFrame rawFrame) {
    final now = _clock();
    final frame = rawFrame.smoothedFrom(
      _lastHandsMs > 0 && now - _lastHandsMs < 400 ? _lastHands : null,
    );
    _poseTracker.leftHanded = settings.leftHanded;
    _poseTracker.update(frame);
    _lastHands = frame;
    _lastHandsMs = now;
    _motion.add(frame);
    final fretting = _frettingHand(frame);
    if (fretting != null) _lastFrettingSeenMs = now;
    if (now - _lastShapeMs >= 120) {
      _lastShapeMs = now;
      final voicing = _voicingFor(_currentChord);
      _shape = voicing == null
          ? ShapeFeedback.none
          : _coach.evaluate(voicing: voicing, frettingHand: fretting);
    }
    _emitIfIdle();
  }

  // --------------------------------------------------------------------- tick

  /// Advances the clock; call at ~30 Hz (done automatically when [autoTick]).
  void tick() {
    final now = _clock();
    if (_phase == TeacherPhase.countIn) {
      _tickCountIn(now);
      return;
    }
    if (_phase != TeacherPhase.running) return;
    if (_mode == CoachingMode.learn) {
      _tickLearn(now);
    } else {
      _tickPlayAlong(now);
    }
  }

  void _tickCountIn(int now) {
    final elapsed = now - _startMs;
    final beatIndex = (elapsed / beatMs).floor();
    if (beatIndex != _lastClickedBeat && beatIndex < countInBeats) {
      _lastClickedBeat = beatIndex;
      _click(beatIndex == 0, force: true);
      _message = CoachMessage(
        'Get ready… ${countInBeats - beatIndex}',
        atMs: now,
      );
    }
    if (elapsed >= countInBeats * beatMs) {
      _phase = TeacherPhase.running;
      _runStartMs = now;
      _lastClickedBeat = -1;
      _lastSoundMs = now;
      _timing.reset();
      _message = CoachMessage(
        'Go!',
        tone: CoachTone.good,
        atMs: now,
        speak: true,
        spoken: 'Go. ${ChordSpeech.name(_currentChord ?? '')}',
      );
    }
    _emit();
  }

  void _tickLearn(int now) {
    if (_pendingAdvance && now >= _celebrateUntilMs) {
      _pendingAdvance = false;
      _learnIndex++;
      if (_learnIndex >= learnSteps.length) {
        stop();
        return;
      }
      _enterStep(now);
    }
    if (settings.metronomeEnabled) {
      final beatIndex = beat.floor();
      if (beatIndex >= 0 && beatIndex != _lastClickedBeat) {
        _lastClickedBeat = beatIndex;
        _click(beatIndex % _plan.beatsPerBar == 0);
      }
    }
    _learnCoach(now);
    _emit();
  }

  void _tickPlayAlong(int now) {
    final currentBeat = beat;
    final beatIndex = currentBeat.floor();
    if (beatIndex != _lastClickedBeat && currentBeat >= 0) {
      _lastClickedBeat = beatIndex;
      _click(beatIndex % _plan.beatsPerBar == 0);
    }
    final missed = _timing.collectMisses(elapsedRunMs);
    if (missed.isNotEmpty) _lastTiming = missed.last;
    final index = _plan.indexAt(currentBeat);
    if (index != _lastTargetIndex) {
      _closeTarget();
      _lastTargetIndex = index;
      _wrongStreak = 0;
    }
    if (_plan.totalBeats > 0 && currentBeat >= _plan.totalBeats) {
      stop();
      return;
    }
    _playAlongCoach(now, currentBeat);
    _emit();
  }

  // ---------------------------------------------------------------- internals

  void _resetStats() {
    _detTotal = 0;
    _detCorrect = 0;
    _strums = 0;
    _combo = 0;
    _bestCombo = 0;
    _cue = null;
    _stats.clear();
    _lastDetection = null;
    _lastStrum = null;
    _lastTiming = null;
    _targetDetections = 0;
    _targetCorrect = 0;
    _lastTargetIndex = -1;
    _chordsPlayed = 0;
    _mistakes = 0;
    _learnIndex = 0;
    _holdMs = 0;
    _stepStartMs = 0;
    _celebrateUntilMs = 0;
    _hintLevel = 0;
    _successes = 0;
    _skips = 0;
    _pendingAdvance = false;
    _needsFreshStrum = false;
    _wrongStreak = 0;
    _goodStreak = 0;
    _lateStreak = 0;
    _earlyStreak = 0;
    _announcedNextIndex = -1;
    _lastWrongChord = null;
    _endElapsedMs = 0;
    _timing.reset();
    _chordDetector?.reset();
    _onsetDetector?.reset();
    _motion.reset();
  }

  ChordStat _statFor(String chord) =>
      _stats.putIfAbsent(chord, () => ChordStat(chord));

  void _pushCue(CueType type, String chord) {
    _cue = TeacherCue(id: ++_cueId, type: type, chord: chord, combo: _combo);
  }

  void _click(bool accent, {bool force = false}) {
    if (!force && !settings.metronomeEnabled) return;
    _lastClickMs = _clock();
    onMetronomeBeat?.call(
      (math.max(0, _lastClickedBeat) % _plan.beatsPerBar) + 1,
      accent,
    );
  }

  Hand? _frettingHand(HandFrame frame) =>
      frame.frettingHand(leftHanded: settings.leftHanded) ??
      (frame.hands.length == 1 ? frame.hands.first : null);

  ChordVoicing? _voicingFor(String? chord) =>
      chord == null || chord.isEmpty ? null : chordLibrary.voicingFor(chord);

  void _updateLevel(AudioFrame frame) {
    final samples = frame.samples;
    if (samples.isEmpty) return;
    var sum = 0.0;
    for (final v in samples) {
      sum += v * v;
    }
    final rms = math.sqrt(sum / samples.length);
    final db = rms <= 1e-9 ? -120.0 : 20 * math.log(rms) / math.ln10;
    final level = ((db + 60) / 50).clamp(0.0, 1.0);
    _level = level > _level ? level : _level * 0.8 + level * 0.2;
  }

  void _emitIfIdle() {
    if (_phase == TeacherPhase.running || _phase == TeacherPhase.countIn) {
      return;
    }
    if (_clock() - _lastEmitMs >= 80) _emit();
  }

  void _handleDetection(ChordDetection detection) {
    _lastDetection = detection;
    if (!detection.isSilent) _lastSoundMs = _clock();
    if (_phase != TeacherPhase.running) return;
    if (_mode == CoachingMode.learn) {
      _learnDetection(detection);
    } else {
      _playAlongDetection(detection);
    }
  }

  void _learnDetection(ChordDetection detection) {
    final now = _clock();
    final steps = learnSteps;
    if (_pendingAdvance ||
        now < _celebrateUntilMs ||
        _learnIndex >= steps.length ||
        _needsFreshStrum) {
      return;
    }
    final hop = _chordDetector?.hopMs ?? 100;
    if (detection.isSilent) {
      _holdMs = math.max(0, _holdMs - hop ~/ 2);
      return;
    }
    final target = steps[_learnIndex];
    _detTotal++;
    if (accepts(detection, target)) {
      _detCorrect++;
      _holdMs += hop;
      _wrongStreak = 0;
      if (_holdMs >= holdToAcceptMs) {
        _completeLearnStep(success: true);
        _emit();
      }
    } else {
      _holdMs = math.max(0, _holdMs - hop);
      _wrongStreak++;
      _lastWrongChord = detection.chord;
    }
  }

  void _playAlongDetection(ChordDetection detection) {
    if (detection.isSilent) return;
    final currentBeat = beat;
    final target = _plan.targetAt(currentBeat);
    if (target == null) return;
    // grace period right after a change so transitions are not penalised
    if ((currentBeat - target.startBeat) * beatMs < 350) return;
    _detTotal++;
    _targetDetections++;
    if (accepts(detection, target.chord)) {
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
    // the metronome click itself can register as an onset on open speakers
    final sinceClick = onset.timestampMs - _lastClickMs;
    if (sinceClick >= 0 && sinceClick < 70) return;
    _heardStrum = true;
    _strumId++;
    final direction = _lastHandsMs > 0
        ? _motion.directionAt(onset.timestampMs)
        : null;
    final strum = onset.withDirection(direction);
    _lastStrum = strum;
    if (_phase != TeacherPhase.running) return;
    _strums++;
    _needsFreshStrum = false;
    if (_mode != CoachingMode.playAlong) return;
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

  void _enterStep(int now) {
    final steps = learnSteps;
    final chord = steps[_learnIndex];
    final previous = _learnIndex > 0 ? steps[_learnIndex - 1] : null;
    _stepStartMs = now;
    _holdMs = 0;
    _hintLevel = 0;
    _wrongStreak = 0;
    _needsFreshStrum = previous == chord;
    _statFor(chord).attempts++;
    _chordDetector?.target = chord;
    final spoken = ChordSpeech.name(chord);
    final String text;
    final String say;
    if (previous == null) {
      text = 'Play $chord and let it ring.';
      say = "Let's start. Play $spoken.";
    } else if (previous == chord) {
      text = 'Lift your fingers, then place $chord again and strum.';
      say = 'Again. Lift your fingers and play $spoken.';
    } else {
      text = 'Now play $chord.';
      say = 'Now $spoken.';
    }
    _message = CoachMessage(text, atMs: now, speak: true, spoken: say);
    _lastMessageMs = now;
    _lastSoundMs = now;
    final voicing = _voicingFor(chord);
    _shape = voicing == null
        ? ShapeFeedback.none
        : _coach.evaluate(
            voicing: voicing,
            frettingHand: _frettingHand(_lastHands),
          );
  }

  void _completeLearnStep({required bool success}) {
    final now = _clock();
    final chord = learnSteps[_learnIndex];
    final stat = _statFor(chord);
    if (success) {
      stat.successes++;
      stat.msToSuccess += math.max(0, now - _stepStartMs);
      _successes++;
      _combo++;
      _bestCombo = math.max(_bestCombo, _combo);
      _pushCue(CueType.correct, chord);
      _message = CoachMessage(_praise(chord), tone: CoachTone.good, atMs: now);
      _celebrateUntilMs = now + celebrateMs;
    } else {
      stat.skips++;
      _skips++;
      _combo = 0;
      _pushCue(CueType.skipped, chord);
      _message = CoachMessage('Skipped $chord.', atMs: now);
      _celebrateUntilMs = now + skipPauseMs;
    }
    _lastMessageMs = now;
    _holdMs = 0;
    _wrongStreak = 0;
    _pendingAdvance = true;
  }

  String _praise(String chord) {
    if (_combo >= 3) return '$_combo in a row! Keep going.';
    final options = <String>[
      "Nice! That's $chord.",
      'Great $chord!',
      'Yes! $chord sounds right.',
      'Clean $chord!',
    ];
    return options[_successes % options.length];
  }

  void _closeTarget() {
    if (_lastTargetIndex < 0 || _lastTargetIndex >= _plan.targets.length) {
      return;
    }
    final chord = _plan.targets[_lastTargetIndex].chord;
    final stat = _statFor(chord);
    stat.attempts++;
    if (_targetDetections > 0) _chordsPlayed++;
    final ok =
        _targetDetections > 0 && _targetCorrect / _targetDetections >= 0.5;
    if (ok) {
      stat.successes++;
      _combo++;
      _bestCombo = math.max(_bestCombo, _combo);
      _pushCue(CueType.correct, chord);
    } else {
      _mistakes++;
      _combo = 0;
      _pushCue(CueType.missed, chord);
    }
    _targetDetections = 0;
    _targetCorrect = 0;
  }

  void _say(
    String text,
    CoachTone tone,
    int now, {
    int cooldownMs = 2200,
    bool speak = false,
    String? spoken,
  }) {
    if (now - _lastMessageMs < cooldownMs) return;
    _lastMessageMs = now;
    _message = CoachMessage(
      text,
      tone: tone,
      atMs: now,
      speak: speak,
      spoken: spoken,
    );
  }

  void _learnCoach(int now) {
    if (_pendingAdvance) return;
    final chord = _currentChord;
    if (chord == null) return;
    final waited = now - _stepStartMs;

    if (_visionActive && waited > 3000 && now - _lastFrettingSeenMs > 2500) {
      _say(
        'Show your fretting hand to the camera so I can guide your fingers.',
        CoachTone.warn,
        now,
        cooldownMs: 6000,
      );
      return;
    }

    if (_wrongStreak >= 8) {
      final heard = _lastWrongChord;
      final hint = _shape.handVisible && _shape.hints.isNotEmpty
          ? ' ${_shape.hints.first}'
          : '';
      _say(
        heard == null
            ? 'Not quite $chord yet.$hint'
            : 'That sounds like $heard. Try $chord again.$hint',
        CoachTone.warn,
        now,
        cooldownMs: 4000,
        speak: true,
        spoken: heard == null
            ? 'Not quite yet.'
            : 'That sounds like ${ChordSpeech.name(heard)}.',
      );
      _wrongStreak = 0;
      return;
    }

    if (waited > strongHintAfterMs && _hintLevel < 2) {
      _hintLevel = 2;
      _say(
        "Take your time. Tap 'Hear it' to hear $chord, or Skip to move on.",
        CoachTone.info,
        now,
        cooldownMs: 0,
        speak: true,
        spoken: 'Take your time. You can tap hear it, or skip.',
      );
      return;
    }

    if (waited > hintAfterMs && _hintLevel < 1) {
      _hintLevel = 1;
      final voicing = _voicingFor(chord);
      final lines = voicing == null
          ? const <String>[]
          : ChordShapeCoach.placementText(voicing);
      final tip = lines.isEmpty
          ? 'Press just behind the fret and strum all the strings.'
          : lines.first;
      _say(
        'Tip: $tip',
        CoachTone.info,
        now,
        cooldownMs: 0,
        speak: true,
        spoken: tip,
      );
      return;
    }

    if (_audioActive && waited > 4000 && now - _lastSoundMs > 4000) {
      _say(
        'Strum all the strings once and let them ring.',
        CoachTone.warn,
        now,
        cooldownMs: 6000,
        speak: true,
      );
    }
  }

  void _playAlongCoach(int now, double currentBeat) {
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
      _message = CoachMessage(
        'Next: ${next.chord}',
        atMs: now,
        speak: true,
        spoken: ChordSpeech.name(next.chord),
      );
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

    if (_audioActive && now - _lastSoundMs > beatMs * _plan.beatsPerBar * 1.5) {
      _say("Strum the strings — I can't hear you yet.", CoachTone.warn, now);
      return;
    }

    if (_wrongStreak >= 3 && target != null) {
      final heard = _lastWrongChord;
      final hint = _shape.handVisible && _shape.hints.isNotEmpty
          ? ' ${_shape.hints.first}'
          : '';
      _say(
        heard == null
            ? "That doesn't sound like ${target.chord} yet.$hint"
            : 'That sounds like $heard — target is ${target.chord}.$hint',
        CoachTone.warn,
        now,
      );
      _wrongStreak = 0;
      return;
    }

    if (_lateStreak >= 3) {
      _say(
        "You're strumming late — relax and land on the click.",
        CoachTone.warn,
        now,
      );
      _lateStreak = 0;
      return;
    }
    if (_earlyStreak >= 3) {
      _say("You're rushing — wait for the click.", CoachTone.warn, now);
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

  double _score() {
    if (_mode == CoachingMode.learn) {
      final attempted = _successes + _skips;
      return attempted == 0 ? 0 : 100 * _successes / attempted;
    }
    final chord = _detTotal == 0 ? 0.0 : _detCorrect / _detTotal;
    final timingWeight = _strums > 0 ? 0.4 : 0.0;
    return ((chord * (1 - timingWeight) + _timing.accuracy * timingWeight) *
            100)
        .clamp(0.0, 100.0);
  }

  String _finishText(double score) {
    if (_mode == CoachingMode.learn) {
      final total = learnSteps.length;
      if (_successes == 0 && _skips == 0) {
        return 'Session ended. Press start whenever you are ready.';
      }
      if (_successes == total) return 'You played every chord!';
      return 'You played $_successes of $total chords.';
    }
    if (score >= 85) return 'Excellent! ${score.round()}% — that was clean.';
    if (score >= 65) {
      return "Nice work: ${score.round()}%. A little more polish and it's there.";
    }
    if (_detTotal == 0) {
      return 'Session over. Turn on the microphone so I can hear you next time.';
    }
    return 'Good effort: ${score.round()}%. Slow the tempo down and try again.';
  }

  String _finishSpoken(double score) {
    if (_mode == CoachingMode.learn) {
      if (_successes == 0) return 'Session ended.';
      return _successes == learnSteps.length
          ? 'Well done. You played every chord.'
          : 'Well done. You played $_successes chords.';
    }
    return 'Session complete. ${score.round()} percent.';
  }

  void _emit() {
    final now = _clock();
    _lastEmitMs = now;
    final idle = _phase == TeacherPhase.idle;
    final learn = _mode == CoachingMode.learn;
    final currentBeat = idle ? 0.0 : beat;

    String? current;
    String? nextChord;
    ChordTarget? target;
    ChordTarget? next;
    int index;
    int count;
    if (learn) {
      final steps = learnSteps;
      count = steps.length;
      index = idle ? 0 : math.min(_learnIndex, count);
      final i = math.min(index, count - 1);
      current = i < 0 ? null : steps[i];
      nextChord = i >= 0 && i + 1 < count && _phase != TeacherPhase.finished
          ? steps[i + 1]
          : null;
    } else {
      count = _plan.targets.length;
      target = count == 0
          ? null
          : idle
          ? _plan.targets.first
          : _plan.targetAt(currentBeat);
      next = idle
          ? (count > 1 ? _plan.targets[1] : null)
          : _plan.nextAfter(currentBeat);
      index = idle ? 0 : math.max(0, _plan.indexAt(currentBeat));
      current = target?.chord;
      nextChord = next?.chord;
    }

    final countInLeft = _phase == TeacherPhase.countIn
        ? (countInBeats - ((now - _startMs) / beatMs).floor()).clamp(
            0,
            countInBeats,
          )
        : 0;
    final celebrating = learn && _pendingAdvance && now < _celebrateUntilMs;

    _snapshot = TeacherSnapshot(
      phase: _phase,
      plan: _plan,
      mode: _mode,
      elapsedMs: idle ? 0 : math.max(0, elapsedRunMs),
      beat: currentBeat,
      countInBeatsLeft: countInLeft,
      targetIndex: index,
      targetCount: count,
      currentChord: current,
      nextChord: nextChord,
      currentTarget: target,
      nextTarget: next,
      targetVoicing: _voicingFor(current),
      nextVoicing: _voicingFor(nextChord),
      detection: _lastDetection,
      lastStrum: _lastStrum,
      lastTiming: _lastTiming,
      recentTimings: List<SlotTiming>.unmodifiable(_timing.recent),
      chordAccuracy: _detTotal == 0 ? 0 : _detCorrect / _detTotal,
      timingAccuracy: _timing.accuracy,
      chordsPlayed: learn ? _successes : _chordsPlayed,
      mistakes: learn ? _skips : _mistakes,
      strums: _strums,
      holdProgress: learn
          ? (celebrating ? 1.0 : (_holdMs / holdToAcceptMs).clamp(0.0, 1.0))
          : (target?.progressAt(currentBeat) ?? 0),
      combo: _combo,
      bestCombo: _bestCombo,
      hintLevel: _hintLevel,
      score: _score(),
      cue: _cue,
      stats: _stats.values.map((s) => s.copy()).toList(growable: false),
      message: _message,
      hands: _lastHands,
      shape: _shape,
      visionActive: _visionActive,
      audioActive: _audioActive,
      inputLevel: _level,
      heardStrum: _heardStrum,
      handSeen: _lastFrettingSeenMs > 0 && now - _lastFrettingSeenMs < 1500,
      listeningPaused: now < _suppressUntilMs,
      pose: _poseTracker.pose,
      strumId: _strumId,
      celebrating: celebrating,
      waitingForFreshStrum: learn && _needsFreshStrum && !_pendingAdvance,
    );
    if (!_controller.isClosed) _controller.add(_snapshot);
  }
}
