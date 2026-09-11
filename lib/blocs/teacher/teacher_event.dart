import 'package:equatable/equatable.dart';

import '../../models/user_settings.dart';
import '../../teacher/engine/practice_plan.dart';
import '../../teacher/engine/teacher_engine.dart';
import '../../teacher/services/vision_service.dart';

abstract class TeacherEvent extends Equatable {
  const TeacherEvent();

  @override
  List<Object?> get props => <Object?>[];
}

class TeacherInitialized extends TeacherEvent {
  const TeacherInitialized(this.plan, {this.mode});

  final PracticePlan plan;

  /// Overrides the learner's saved preference (e.g. from a link).
  final CoachingMode? mode;

  @override
  List<Object?> get props => <Object?>[plan, mode];
}

/// Turn on the camera and microphone without starting the session.
class TeacherServicesRequested extends TeacherEvent {
  const TeacherServicesRequested();
}

class TeacherStarted extends TeacherEvent {
  const TeacherStarted();
}

class TeacherPaused extends TeacherEvent {
  const TeacherPaused();
}

class TeacherResumed extends TeacherEvent {
  const TeacherResumed();
}

class TeacherStopped extends TeacherEvent {
  const TeacherStopped();
}

class TeacherModeChanged extends TeacherEvent {
  const TeacherModeChanged(this.mode);

  final CoachingMode mode;

  @override
  List<Object?> get props => <Object?>[mode];
}

class TeacherSkipRequested extends TeacherEvent {
  const TeacherSkipRequested();
}

class TeacherHearChordRequested extends TeacherEvent {
  const TeacherHearChordRequested(this.chord);

  final String chord;

  @override
  List<Object?> get props => <Object?>[chord];
}

class TeacherVoiceToggled extends TeacherEvent {
  const TeacherVoiceToggled(this.enabled);

  final bool enabled;

  @override
  List<Object?> get props => <Object?>[enabled];
}

class TeacherBpmChanged extends TeacherEvent {
  const TeacherBpmChanged(this.bpm);

  final int bpm;

  @override
  List<Object?> get props => <Object?>[bpm];
}

class TeacherCapoChanged extends TeacherEvent {
  const TeacherCapoChanged(this.capo);

  final int capo;

  @override
  List<Object?> get props => <Object?>[capo];
}

class TeacherCameraToggled extends TeacherEvent {
  const TeacherCameraToggled(this.enabled);

  final bool enabled;

  @override
  List<Object?> get props => <Object?>[enabled];
}

class TeacherMicToggled extends TeacherEvent {
  const TeacherMicToggled(this.enabled);

  final bool enabled;

  @override
  List<Object?> get props => <Object?>[enabled];
}

class TeacherMetronomeToggled extends TeacherEvent {
  const TeacherMetronomeToggled(this.enabled);

  final bool enabled;

  @override
  List<Object?> get props => <Object?>[enabled];
}

class TeacherSessionSaveRequested extends TeacherEvent {
  const TeacherSessionSaveRequested();
}

class TeacherSnapshotArrived extends TeacherEvent {
  const TeacherSnapshotArrived(this.snapshot);

  final TeacherSnapshot snapshot;

  @override
  List<Object?> get props => <Object?>[snapshot];
}

class TeacherTrackingStatusChanged extends TeacherEvent {
  const TeacherTrackingStatusChanged(this.status);

  final TrackingStatus status;

  @override
  List<Object?> get props => <Object?>[status];
}

class TeacherSettingsChanged extends TeacherEvent {
  const TeacherSettingsChanged(this.settings);

  final UserSettings settings;

  @override
  List<Object?> get props => <Object?>[settings];
}
