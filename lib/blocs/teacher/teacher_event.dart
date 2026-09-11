import 'package:equatable/equatable.dart';

import '../../teacher/engine/practice_plan.dart';
import '../../teacher/engine/teacher_engine.dart';

abstract class TeacherEvent extends Equatable {
  const TeacherEvent();

  @override
  List<Object?> get props => <Object?>[];
}

class TeacherInitialized extends TeacherEvent {
  const TeacherInitialized(this.plan);

  final PracticePlan plan;

  @override
  List<Object?> get props => <Object?>[plan];
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
  List<Object?> get props => <Object?>[
    snapshot.phase,
    snapshot.elapsedMs,
    snapshot.beat,
  ];
}
