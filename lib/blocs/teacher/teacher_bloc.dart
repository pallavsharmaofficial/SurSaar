import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../data/content/chord_library.dart';
import '../../repositories/practice_repository.dart';
import '../../repositories/progress_repository.dart';
import '../../repositories/settings_repository.dart';
import '../../teacher/engine/teacher_engine.dart';
import '../../teacher/models/audio_frame.dart';
import '../../teacher/models/hand_frame.dart';
import '../../teacher/services/audio_capture_service.dart';
import '../../teacher/services/sound_service.dart';
import '../../teacher/services/vision_service.dart';
import 'teacher_event.dart';
import 'teacher_state.dart';

/// Glues the camera, microphone, sounds and the [TeacherEngine] to the UI.
///
/// Camera and microphone stay on for the whole practice screen once turned
/// on, so replaying a session never restarts the camera.
class TeacherBloc extends Bloc<TeacherEvent, TeacherState> {
  TeacherBloc({
    required ChordLibrary chordLibrary,
    required SettingsRepository settingsRepository,
    required PracticeRepository practiceRepository,
    required ProgressRepository progressRepository,
    VisionService? visionService,
    AudioCaptureService? audioService,
    TeacherSoundService? soundService,
  }) : _chordLibrary = chordLibrary,
       _settingsRepository = settingsRepository,
       _practiceRepository = practiceRepository,
       _progressRepository = progressRepository,
       _vision = visionService ?? createVisionService(),
       _audio = audioService ?? createAudioCaptureService(),
       _sound = soundService ?? createTeacherSoundService(),
       super(const TeacherState()) {
    on<TeacherInitialized>(_onInitialized);
    on<TeacherServicesRequested>(_onServicesRequested);
    on<TeacherStarted>(_onStarted);
    on<TeacherPaused>((event, emit) => _engine?.pause());
    on<TeacherResumed>((event, emit) => _engine?.resume());
    on<TeacherStopped>(_onStopped);
    on<TeacherModeChanged>(_onModeChanged);
    on<TeacherSkipRequested>((event, emit) => _engine?.skip());
    on<TeacherHearChordRequested>(_onHearChord);
    on<TeacherVoiceToggled>(_onVoiceToggled);
    on<TeacherBpmChanged>(_onBpmChanged);
    on<TeacherCapoChanged>(_onCapoChanged);
    on<TeacherCameraToggled>(_onCameraToggled);
    on<TeacherMicToggled>(_onMicToggled);
    on<TeacherMetronomeToggled>(_onMetronomeToggled);
    on<TeacherSessionSaveRequested>(_onSaveRequested);
    on<TeacherTrackingStatusChanged>(
      (event, emit) => emit(state.copyWith(trackingStatus: event.status)),
    );
    on<TeacherSnapshotArrived>(_onSnapshot);
    _vision.trackingStatus.addListener(_onTrackingStatus);
  }

  final ChordLibrary _chordLibrary;
  final SettingsRepository _settingsRepository;
  final PracticeRepository _practiceRepository;
  final ProgressRepository _progressRepository;
  final VisionService _vision;
  final AudioCaptureService _audio;
  final TeacherSoundService _sound;

  TeacherEngine? _engine;
  StreamSubscription<TeacherSnapshot>? _snapshotSub;
  StreamSubscription<AudioFrame>? _audioSub;
  StreamSubscription<HandFrame>? _handsSub;
  bool _startingServices = false;
  int _lastSpokenAt = -1;

  VisionService get vision => _vision;

  void _onTrackingStatus() {
    if (!isClosed) {
      add(TeacherTrackingStatusChanged(_vision.trackingStatus.value));
    }
  }

  Future<void> _onInitialized(
    TeacherInitialized event,
    Emitter<TeacherState> emit,
  ) async {
    final settings = await _settingsRepository.getSettings();
    final mode = event.mode ?? settings.coachingMode;
    final metronome =
        mode == CoachingMode.playAlong && settings.metronomeEnabled;
    final engine = TeacherEngine(
      plan: event.plan,
      chordLibrary: _chordLibrary,
      settings: settings.copyWith(metronomeEnabled: metronome),
      mode: mode,
    );
    engine.onMetronomeBeat = (beat, accent) => _sound.click(accent: accent);
    _engine?.dispose();
    _engine = engine;
    await _snapshotSub?.cancel();
    _snapshotSub = engine.stream.listen((snapshot) {
      if (!isClosed) add(TeacherSnapshotArrived(snapshot));
    });
    emit(
      state.copyWith(
        status: TeacherStatus.ready,
        plan: event.plan,
        snapshot: engine.snapshot,
        mode: mode,
        bpm: event.plan.bpm,
        songBpm: event.plan.bpm,
        capo: event.plan.capo,
        settings: settings,
        metronomeEnabled: metronome,
        voiceEnabled: settings.voiceEnabled,
        cameraSupported: _vision.supportsPreview,
        handTrackingSupported: _vision.supportsHandTracking,
        micSupported: _audio.isSupported,
        cameraEnabled: _vision.supportsPreview,
        micEnabled: _audio.isSupported,
        canPlayChords: _sound.canPlayChords,
        canSpeak: _sound.canSpeak,
        trackingStatus: _vision.trackingStatus.value,
        saved: false,
      ),
    );
    // Load hand tracking while the learner reads the screen.
    if (_vision.supportsHandTracking) unawaited(_vision.warmUp());
  }

  Future<void> _startServices(Emitter<TeacherState> emit) async {
    final engine = _engine;
    if (engine == null || _startingServices) return;
    final wantCamera =
        state.cameraSupported && state.cameraEnabled && !state.cameraRunning;
    final wantMic = state.micSupported && state.micEnabled && !state.micRunning;
    if (!wantCamera && !wantMic) return;
    _startingServices = true;
    emit(state.copyWith(servicesStarting: true));
    final results = await Future.wait<bool>(<Future<bool>>[
      wantCamera
          ? _vision
                .start(mirror: state.settings.mirrorCamera)
                .then((_) => _vision.isRunning)
          : Future<bool>.value(state.cameraRunning),
      wantMic ? _audio.start() : Future<bool>.value(state.micRunning),
    ]);
    _startingServices = false;
    final cameraRunning = results[0];
    final micRunning = results[1];
    if (cameraRunning) {
      _handsSub ??= _vision.frames.listen(engine.onHands);
    }
    if (micRunning) {
      _audioSub ??= _audio.frames.listen(engine.onAudio);
    }
    if (isClosed) return;
    emit(
      state.copyWith(
        servicesStarting: false,
        cameraRunning: cameraRunning,
        micRunning: micRunning,
        cameraError: wantCamera ? _vision.lastError : null,
        clearCameraError: wantCamera && _vision.lastError == null,
        micError: wantMic ? _audio.lastError : null,
        clearMicError: wantMic && _audio.lastError == null,
      ),
    );
  }

  Future<void> _onServicesRequested(
    TeacherServicesRequested event,
    Emitter<TeacherState> emit,
  ) => _startServices(emit);

  Future<void> _onStarted(
    TeacherStarted event,
    Emitter<TeacherState> emit,
  ) async {
    final engine = _engine;
    if (engine == null || state.isRunning) return;
    await _startServices(emit);
    try {
      await WakelockPlus.enable();
    } catch (_) {}
    engine.setSettings(
      state.settings.copyWith(metronomeEnabled: state.metronomeEnabled),
    );
    engine.start();
    emit(
      state.copyWith(
        status: TeacherStatus.active,
        startedAt: DateTime.now(),
        saved: false,
        snapshot: engine.snapshot,
      ),
    );
  }

  Future<void> _onStopped(
    TeacherStopped event,
    Emitter<TeacherState> emit,
  ) async {
    _engine?.stop();
    try {
      await WakelockPlus.disable();
    } catch (_) {}
  }

  Future<void> _onModeChanged(
    TeacherModeChanged event,
    Emitter<TeacherState> emit,
  ) async {
    final engine = _engine;
    if (engine == null || state.inSession || event.mode == state.mode) return;
    final metronome =
        event.mode == CoachingMode.playAlong && state.settings.metronomeEnabled;
    final settings = state.settings.copyWith(coachingMode: event.mode);
    engine
      ..setSettings(settings.copyWith(metronomeEnabled: metronome))
      ..setMode(event.mode);
    emit(
      state.copyWith(
        mode: event.mode,
        metronomeEnabled: metronome,
        settings: settings,
        status: TeacherStatus.ready,
        snapshot: engine.snapshot,
        saved: false,
      ),
    );
    await _settingsRepository.saveSettings(settings);
  }

  void _onHearChord(
    TeacherHearChordRequested event,
    Emitter<TeacherState> emit,
  ) {
    final voicing = _chordLibrary.voicingFor(event.chord);
    if (voicing == null || !_sound.canPlayChords) return;
    final duration = _sound.playChord(voicing.midiNotes);
    if (duration > Duration.zero) {
      _engine?.suppressListening(duration + const Duration(milliseconds: 300));
    }
  }

  Future<void> _onVoiceToggled(
    TeacherVoiceToggled event,
    Emitter<TeacherState> emit,
  ) async {
    if (!event.enabled) _sound.stopSpeaking();
    final settings = state.settings.copyWith(voiceEnabled: event.enabled);
    emit(state.copyWith(voiceEnabled: event.enabled, settings: settings));
    await _settingsRepository.saveSettings(settings);
  }

  void _onBpmChanged(TeacherBpmChanged event, Emitter<TeacherState> emit) {
    final bpm = event.bpm.clamp(40, 200);
    _engine?.setBpm(bpm);
    emit(state.copyWith(bpm: bpm, plan: _engine?.plan));
  }

  void _onCapoChanged(TeacherCapoChanged event, Emitter<TeacherState> emit) {
    final capo = event.capo.clamp(0, 9);
    _engine?.setCapo(capo);
    emit(state.copyWith(capo: capo, plan: _engine?.plan));
  }

  Future<void> _onCameraToggled(
    TeacherCameraToggled event,
    Emitter<TeacherState> emit,
  ) async {
    if (!event.enabled) {
      await _handsSub?.cancel();
      _handsSub = null;
      await _vision.stop();
      emit(state.copyWith(cameraEnabled: false, cameraRunning: false));
      return;
    }
    emit(state.copyWith(cameraEnabled: true, clearCameraError: true));
    if (state.servicesOn || state.inSession) await _startServices(emit);
  }

  Future<void> _onMicToggled(
    TeacherMicToggled event,
    Emitter<TeacherState> emit,
  ) async {
    if (!event.enabled) {
      await _audioSub?.cancel();
      _audioSub = null;
      await _audio.stop();
      emit(state.copyWith(micEnabled: false, micRunning: false));
      return;
    }
    emit(state.copyWith(micEnabled: true, clearMicError: true));
    if (state.servicesOn || state.inSession) await _startServices(emit);
  }

  void _onMetronomeToggled(
    TeacherMetronomeToggled event,
    Emitter<TeacherState> emit,
  ) {
    _engine?.setSettings(
      state.settings.copyWith(metronomeEnabled: event.enabled),
    );
    emit(state.copyWith(metronomeEnabled: event.enabled));
  }

  void _onSnapshot(TeacherSnapshotArrived event, Emitter<TeacherState> emit) {
    final snapshot = event.snapshot;
    _maybeSpeak(snapshot);
    final justFinished =
        snapshot.phase == TeacherPhase.finished &&
        state.status == TeacherStatus.active;
    emit(
      state.copyWith(
        snapshot: snapshot,
        status: justFinished ? TeacherStatus.finished : null,
      ),
    );
    if (justFinished) {
      unawaited(WakelockPlus.disable().catchError((_) {}));
      if (snapshot.successes > 0 || snapshot.elapsedMs > 5000) {
        add(const TeacherSessionSaveRequested());
      }
    }
  }

  void _maybeSpeak(TeacherSnapshot snapshot) {
    if (!state.voiceEnabled || !_sound.canSpeak) return;
    final message = snapshot.message;
    if (message == null || !message.speak) return;
    if (message.atMs == _lastSpokenAt) return;
    _lastSpokenAt = message.atMs;
    _sound.speak(message.spokenText);
  }

  Future<void> _onSaveRequested(
    TeacherSessionSaveRequested event,
    Emitter<TeacherState> emit,
  ) async {
    final snapshot = state.snapshot;
    final plan = state.plan;
    if (snapshot == null || plan == null || state.saved || state.saving) {
      return;
    }
    emit(state.copyWith(saving: true));
    final startedAt = state.startedAt ?? DateTime.now();
    final duration = (snapshot.elapsedMs / 1000).round();
    final session = _practiceRepository.createSession(
      songId: plan.sourceId ?? 'adhoc',
      startTime: startedAt,
      duration: duration,
      accuracy: snapshot.score,
      chordsPlayed: snapshot.chordsPlayed,
      mistakes: snapshot.mistakes,
      timingAccuracy: state.mode == CoachingMode.playAlong
          ? snapshot.timingAccuracy * 100
          : null,
      mode: '${plan.mode.name}-${state.mode.name}',
    );
    await _practiceRepository.saveSession(session);
    await _progressRepository.recordPracticeSession(
      durationInSeconds: duration,
      accuracy: snapshot.score,
    );
    if (!isClosed) emit(state.copyWith(saving: false, saved: true));
  }

  @override
  Future<void> close() async {
    _vision.trackingStatus.removeListener(_onTrackingStatus);
    await _snapshotSub?.cancel();
    await _handsSub?.cancel();
    await _audioSub?.cancel();
    _sound.stopSpeaking();
    _engine?.dispose();
    await _vision.stop();
    await _audio.stop();
    try {
      await WakelockPlus.disable();
    } catch (_) {}
    await _vision.dispose();
    await _audio.dispose();
    return super.close();
  }
}
