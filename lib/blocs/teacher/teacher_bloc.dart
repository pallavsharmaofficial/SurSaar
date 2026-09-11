import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../data/content/chord_library.dart';
import '../../repositories/practice_repository.dart';
import '../../repositories/progress_repository.dart';
import '../../repositories/settings_repository.dart';
import '../../teacher/engine/teacher_engine.dart';
import '../../teacher/services/audio_capture_service.dart';
import '../../teacher/services/metronome_service.dart';
import '../../teacher/services/vision_service.dart';
import 'teacher_event.dart';
import 'teacher_state.dart';

/// Glues the platform services and the [TeacherEngine] to the UI.
class TeacherBloc extends Bloc<TeacherEvent, TeacherState> {
  TeacherBloc({
    required ChordLibrary chordLibrary,
    required SettingsRepository settingsRepository,
    required PracticeRepository practiceRepository,
    required ProgressRepository progressRepository,
    VisionService? visionService,
    AudioCaptureService? audioService,
    MetronomeService? metronomeService,
  }) : _chordLibrary = chordLibrary,
       _settingsRepository = settingsRepository,
       _practiceRepository = practiceRepository,
       _progressRepository = progressRepository,
       _vision = visionService ?? createVisionService(),
       _audio = audioService ?? createAudioCaptureService(),
       _metronome = metronomeService ?? createMetronomeService(),
       super(const TeacherState()) {
    on<TeacherInitialized>(_onInitialized);
    on<TeacherStarted>(_onStarted);
    on<TeacherPaused>(_onPaused);
    on<TeacherResumed>(_onResumed);
    on<TeacherStopped>(_onStopped);
    on<TeacherBpmChanged>(_onBpmChanged);
    on<TeacherCapoChanged>(_onCapoChanged);
    on<TeacherCameraToggled>(_onCameraToggled);
    on<TeacherMicToggled>(_onMicToggled);
    on<TeacherMetronomeToggled>(_onMetronomeToggled);
    on<TeacherSessionSaveRequested>(_onSaveRequested);
    on<TeacherSnapshotArrived>(
      _onSnapshot,
      transformer: (events, mapper) => events.asyncExpand(mapper),
    );
  }

  final ChordLibrary _chordLibrary;
  final SettingsRepository _settingsRepository;
  final PracticeRepository _practiceRepository;
  final ProgressRepository _progressRepository;
  final VisionService _vision;
  final AudioCaptureService _audio;
  final MetronomeService _metronome;

  TeacherEngine? _engine;
  StreamSubscription<TeacherSnapshot>? _snapshotSub;
  StreamSubscription<dynamic>? _audioSub;
  StreamSubscription<dynamic>? _handsSub;

  VisionService get vision => _vision;

  Future<void> _onInitialized(
    TeacherInitialized event,
    Emitter<TeacherState> emit,
  ) async {
    final settings = await _settingsRepository.getSettings();
    final engine = TeacherEngine(
      plan: event.plan,
      chordLibrary: _chordLibrary,
      settings: settings,
    );
    engine.onMetronomeBeat = (beat, accent) => _metronome.click(accent: accent);
    _engine?.dispose();
    _engine = engine;
    await _snapshotSub?.cancel();
    _snapshotSub = engine.stream.listen(
      (snapshot) => add(TeacherSnapshotArrived(snapshot)),
    );
    emit(
      state.copyWith(
        status: TeacherStatus.ready,
        plan: event.plan,
        snapshot: engine.snapshot,
        bpm: event.plan.bpm,
        capo: event.plan.capo,
        settings: settings,
        metronomeEnabled: settings.metronomeEnabled,
        cameraSupported: _vision.supportsPreview,
        handTrackingSupported: _vision.supportsHandTracking,
        micSupported: _audio.isSupported,
        cameraEnabled: _vision.supportsPreview,
        micEnabled: _audio.isSupported,
        saved: false,
      ),
    );
  }

  Future<void> _onStarted(
    TeacherStarted event,
    Emitter<TeacherState> emit,
  ) async {
    final engine = _engine;
    if (engine == null) return;
    emit(state.copyWith(status: TeacherStatus.starting, saved: false));

    var cameraRunning = state.cameraRunning;
    String? cameraError;
    if (state.cameraEnabled && !cameraRunning) {
      await _vision.start(mirror: state.settings.mirrorCamera);
      cameraRunning = _vision.isRunning;
      cameraError = _vision.lastError;
      if (cameraRunning) {
        await _handsSub?.cancel();
        _handsSub = _vision.frames.listen(engine.onHands);
      }
    }

    var micRunning = state.micRunning;
    String? micError;
    if (state.micEnabled && !micRunning) {
      micRunning = await _audio.start();
      micError = _audio.lastError;
      if (micRunning) {
        await _audioSub?.cancel();
        _audioSub = _audio.frames.listen(engine.onAudio);
      }
    }

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
        cameraRunning: cameraRunning,
        micRunning: micRunning,
        cameraError: cameraError,
        clearCameraError: cameraError == null,
        micError: micError,
        clearMicError: micError == null,
        startedAt: DateTime.now(),
        snapshot: engine.snapshot,
      ),
    );
  }

  void _onPaused(TeacherPaused event, Emitter<TeacherState> emit) {
    _engine?.pause();
  }

  void _onResumed(TeacherResumed event, Emitter<TeacherState> emit) {
    _engine?.resume();
  }

  Future<void> _onStopped(
    TeacherStopped event,
    Emitter<TeacherState> emit,
  ) async {
    final engine = _engine;
    engine?.stop();
    await _stopServices();
    emit(
      state.copyWith(
        status: TeacherStatus.finished,
        snapshot: engine?.snapshot,
        cameraRunning: false,
        micRunning: false,
      ),
    );
  }

  Future<void> _stopServices() async {
    await _handsSub?.cancel();
    _handsSub = null;
    await _audioSub?.cancel();
    _audioSub = null;
    await _vision.stop();
    await _audio.stop();
    try {
      await WakelockPlus.disable();
    } catch (_) {}
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
    if (!event.enabled && state.cameraRunning) {
      await _handsSub?.cancel();
      _handsSub = null;
      await _vision.stop();
      emit(state.copyWith(cameraEnabled: false, cameraRunning: false));
      return;
    }
    if (event.enabled && state.isActive && !state.cameraRunning) {
      await _vision.start(mirror: state.settings.mirrorCamera);
      final running = _vision.isRunning;
      if (running && _engine != null) {
        _handsSub = _vision.frames.listen(_engine!.onHands);
      }
      emit(
        state.copyWith(
          cameraEnabled: true,
          cameraRunning: running,
          cameraError: _vision.lastError,
          clearCameraError: _vision.lastError == null,
        ),
      );
      return;
    }
    emit(state.copyWith(cameraEnabled: event.enabled));
  }

  Future<void> _onMicToggled(
    TeacherMicToggled event,
    Emitter<TeacherState> emit,
  ) async {
    if (!event.enabled && state.micRunning) {
      await _audioSub?.cancel();
      _audioSub = null;
      await _audio.stop();
      emit(state.copyWith(micEnabled: false, micRunning: false));
      return;
    }
    if (event.enabled && state.isActive && !state.micRunning) {
      final running = await _audio.start();
      if (running && _engine != null) {
        _audioSub = _audio.frames.listen(_engine!.onAudio);
      }
      emit(
        state.copyWith(
          micEnabled: true,
          micRunning: running,
          micError: _audio.lastError,
          clearMicError: _audio.lastError == null,
        ),
      );
      return;
    }
    emit(state.copyWith(micEnabled: event.enabled));
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
    final finished = snapshot.phase == TeacherPhase.finished;
    if (finished && state.status == TeacherStatus.active) {
      unawaited(_stopServices());
    }
    emit(
      state.copyWith(
        snapshot: snapshot,
        status: finished
            ? TeacherStatus.finished
            : (state.status == TeacherStatus.starting
                  ? TeacherStatus.active
                  : state.status),
        cameraRunning: finished ? false : state.cameraRunning,
        micRunning: finished ? false : state.micRunning,
      ),
    );
  }

  Future<void> _onSaveRequested(
    TeacherSessionSaveRequested event,
    Emitter<TeacherState> emit,
  ) async {
    final snapshot = state.snapshot;
    final plan = state.plan;
    if (snapshot == null || plan == null || state.saved) return;
    emit(state.copyWith(saving: true));
    final startedAt = state.startedAt ?? DateTime.now();
    final duration = (snapshot.elapsedMs / 1000).round();
    final session = _practiceRepository.createSession(
      songId: plan.sourceId ?? 'adhoc',
      startTime: startedAt,
      duration: duration,
      accuracy: snapshot.overallScore,
      chordsPlayed: snapshot.chordsPlayed,
      mistakes: snapshot.mistakes,
      timingAccuracy: snapshot.timingAccuracy * 100,
      mode: plan.mode.name,
    );
    await _practiceRepository.saveSession(session);
    await _progressRepository.recordPracticeSession(
      durationInSeconds: duration,
      accuracy: snapshot.overallScore,
    );
    emit(state.copyWith(saving: false, saved: true));
  }

  @override
  Future<void> close() async {
    await _snapshotSub?.cancel();
    await _stopServices();
    _engine?.dispose();
    await _vision.dispose();
    await _audio.dispose();
    return super.close();
  }
}
