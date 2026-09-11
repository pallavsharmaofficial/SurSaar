import 'package:equatable/equatable.dart';

import '../../models/user_settings.dart';
import '../../teacher/engine/practice_plan.dart';
import '../../teacher/engine/teacher_engine.dart';

enum TeacherStatus { initial, ready, starting, active, finished, error }

class TeacherState extends Equatable {
  const TeacherState({
    this.status = TeacherStatus.initial,
    this.plan,
    this.snapshot,
    this.bpm = 80,
    this.capo = 0,
    this.cameraEnabled = true,
    this.micEnabled = true,
    this.metronomeEnabled = true,
    this.cameraSupported = false,
    this.handTrackingSupported = false,
    this.micSupported = false,
    this.cameraRunning = false,
    this.micRunning = false,
    this.cameraError,
    this.micError,
    this.settings = const UserSettings(),
    this.saved = false,
    this.saving = false,
    this.errorMessage,
    this.startedAt,
  });

  final TeacherStatus status;
  final PracticePlan? plan;
  final TeacherSnapshot? snapshot;
  final int bpm;
  final int capo;
  final bool cameraEnabled;
  final bool micEnabled;
  final bool metronomeEnabled;
  final bool cameraSupported;
  final bool handTrackingSupported;
  final bool micSupported;
  final bool cameraRunning;
  final bool micRunning;
  final String? cameraError;
  final String? micError;
  final UserSettings settings;
  final bool saved;
  final bool saving;
  final String? errorMessage;
  final DateTime? startedAt;

  bool get isActive => status == TeacherStatus.active;

  bool get isPaused => snapshot?.phase == TeacherPhase.paused;

  TeacherState copyWith({
    TeacherStatus? status,
    PracticePlan? plan,
    TeacherSnapshot? snapshot,
    int? bpm,
    int? capo,
    bool? cameraEnabled,
    bool? micEnabled,
    bool? metronomeEnabled,
    bool? cameraSupported,
    bool? handTrackingSupported,
    bool? micSupported,
    bool? cameraRunning,
    bool? micRunning,
    String? cameraError,
    bool clearCameraError = false,
    String? micError,
    bool clearMicError = false,
    UserSettings? settings,
    bool? saved,
    bool? saving,
    String? errorMessage,
    DateTime? startedAt,
  }) {
    return TeacherState(
      status: status ?? this.status,
      plan: plan ?? this.plan,
      snapshot: snapshot ?? this.snapshot,
      bpm: bpm ?? this.bpm,
      capo: capo ?? this.capo,
      cameraEnabled: cameraEnabled ?? this.cameraEnabled,
      micEnabled: micEnabled ?? this.micEnabled,
      metronomeEnabled: metronomeEnabled ?? this.metronomeEnabled,
      cameraSupported: cameraSupported ?? this.cameraSupported,
      handTrackingSupported:
          handTrackingSupported ?? this.handTrackingSupported,
      micSupported: micSupported ?? this.micSupported,
      cameraRunning: cameraRunning ?? this.cameraRunning,
      micRunning: micRunning ?? this.micRunning,
      cameraError: clearCameraError ? null : (cameraError ?? this.cameraError),
      micError: clearMicError ? null : (micError ?? this.micError),
      settings: settings ?? this.settings,
      saved: saved ?? this.saved,
      saving: saving ?? this.saving,
      errorMessage: errorMessage ?? this.errorMessage,
      startedAt: startedAt ?? this.startedAt,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    plan,
    snapshot,
    bpm,
    capo,
    cameraEnabled,
    micEnabled,
    metronomeEnabled,
    cameraSupported,
    handTrackingSupported,
    micSupported,
    cameraRunning,
    micRunning,
    cameraError,
    micError,
    settings,
    saved,
    saving,
    errorMessage,
    startedAt,
  ];
}
