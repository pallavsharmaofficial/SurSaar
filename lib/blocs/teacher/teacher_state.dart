import 'package:equatable/equatable.dart';

import '../../models/user_settings.dart';
import '../../teacher/engine/practice_plan.dart';
import '../../teacher/engine/teacher_engine.dart';
import '../../teacher/services/vision_service.dart';

enum TeacherStatus { initial, ready, active, finished }

class TeacherState extends Equatable {
  const TeacherState({
    this.status = TeacherStatus.initial,
    this.plan,
    this.snapshot,
    this.mode = CoachingMode.learn,
    this.bpm = 80,
    this.songBpm = 80,
    this.capo = 0,
    this.cameraEnabled = true,
    this.micEnabled = true,
    this.metronomeEnabled = false,
    this.voiceEnabled = true,
    this.cameraSupported = false,
    this.handTrackingSupported = false,
    this.micSupported = false,
    this.canPlayChords = false,
    this.canSpeak = false,
    this.cameraRunning = false,
    this.micRunning = false,
    this.servicesStarting = false,
    this.trackingStatus = TrackingStatus.unavailable,
    this.cameraError,
    this.micError,
    this.settings = const UserSettings(),
    this.saved = false,
    this.saving = false,
    this.startedAt,
  });

  final TeacherStatus status;
  final PracticePlan? plan;
  final TeacherSnapshot? snapshot;
  final CoachingMode mode;
  final int bpm;

  /// The plan's own tempo, for the speed presets.
  final int songBpm;
  final int capo;
  final bool cameraEnabled;
  final bool micEnabled;
  final bool metronomeEnabled;
  final bool voiceEnabled;
  final bool cameraSupported;
  final bool handTrackingSupported;
  final bool micSupported;
  final bool canPlayChords;
  final bool canSpeak;
  final bool cameraRunning;
  final bool micRunning;
  final bool servicesStarting;
  final TrackingStatus trackingStatus;
  final String? cameraError;
  final String? micError;
  final UserSettings settings;
  final bool saved;
  final bool saving;
  final DateTime? startedAt;

  TeacherPhase get phase => snapshot?.phase ?? TeacherPhase.idle;

  bool get isRunning =>
      phase == TeacherPhase.countIn || phase == TeacherPhase.running;

  bool get isPaused => phase == TeacherPhase.paused;

  bool get isFinished => phase == TeacherPhase.finished;

  bool get inSession => isRunning || isPaused;

  bool get servicesOn => cameraRunning || micRunning;

  /// Show the "turn on camera & mic" card.
  bool get showSetup => !servicesOn && needsSetup && !inSession && !isFinished;

  /// Camera or microphone is wanted but not on yet.
  bool get needsSetup =>
      (cameraSupported && cameraEnabled && !cameraRunning) ||
      (micSupported && micEnabled && !micRunning);

  TeacherState copyWith({
    TeacherStatus? status,
    PracticePlan? plan,
    TeacherSnapshot? snapshot,
    CoachingMode? mode,
    int? bpm,
    int? songBpm,
    int? capo,
    bool? cameraEnabled,
    bool? micEnabled,
    bool? metronomeEnabled,
    bool? voiceEnabled,
    bool? cameraSupported,
    bool? handTrackingSupported,
    bool? micSupported,
    bool? canPlayChords,
    bool? canSpeak,
    bool? cameraRunning,
    bool? micRunning,
    bool? servicesStarting,
    TrackingStatus? trackingStatus,
    String? cameraError,
    bool clearCameraError = false,
    String? micError,
    bool clearMicError = false,
    UserSettings? settings,
    bool? saved,
    bool? saving,
    DateTime? startedAt,
  }) {
    return TeacherState(
      status: status ?? this.status,
      plan: plan ?? this.plan,
      snapshot: snapshot ?? this.snapshot,
      mode: mode ?? this.mode,
      bpm: bpm ?? this.bpm,
      songBpm: songBpm ?? this.songBpm,
      capo: capo ?? this.capo,
      cameraEnabled: cameraEnabled ?? this.cameraEnabled,
      micEnabled: micEnabled ?? this.micEnabled,
      metronomeEnabled: metronomeEnabled ?? this.metronomeEnabled,
      voiceEnabled: voiceEnabled ?? this.voiceEnabled,
      cameraSupported: cameraSupported ?? this.cameraSupported,
      handTrackingSupported:
          handTrackingSupported ?? this.handTrackingSupported,
      micSupported: micSupported ?? this.micSupported,
      canPlayChords: canPlayChords ?? this.canPlayChords,
      canSpeak: canSpeak ?? this.canSpeak,
      cameraRunning: cameraRunning ?? this.cameraRunning,
      micRunning: micRunning ?? this.micRunning,
      servicesStarting: servicesStarting ?? this.servicesStarting,
      trackingStatus: trackingStatus ?? this.trackingStatus,
      cameraError: clearCameraError ? null : (cameraError ?? this.cameraError),
      micError: clearMicError ? null : (micError ?? this.micError),
      settings: settings ?? this.settings,
      saved: saved ?? this.saved,
      saving: saving ?? this.saving,
      startedAt: startedAt ?? this.startedAt,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    plan,
    snapshot,
    mode,
    bpm,
    capo,
    cameraEnabled,
    micEnabled,
    metronomeEnabled,
    voiceEnabled,
    cameraSupported,
    handTrackingSupported,
    micSupported,
    canPlayChords,
    canSpeak,
    cameraRunning,
    micRunning,
    servicesStarting,
    trackingStatus,
    cameraError,
    micError,
    settings,
    saved,
    saving,
    startedAt,
  ];
}
