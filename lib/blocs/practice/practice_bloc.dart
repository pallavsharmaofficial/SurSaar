import 'package:flutter_bloc/flutter_bloc.dart';
import 'practice_event.dart';
import 'practice_state.dart';

class PracticeBloc extends Bloc<PracticeEvent, PracticeState> {
  PracticeBloc() : super(PracticeState.initial()) {
    on<PracticeStarted>(_onStarted);
    on<PracticeStopped>(_onStopped);
    on<PracticeAccuracyUpdated>(_onAccuracyUpdated);
    on<PracticeChordDetected>(_onChordDetected);
  }

  void _onStarted(
    PracticeStarted event,
    Emitter<PracticeState> emit,
  ) {
    emit(state.copyWith(status: PracticeStatus.listening));
  }

  void _onStopped(
    PracticeStopped event,
    Emitter<PracticeState> emit,
  ) {
    emit(state.copyWith(status: PracticeStatus.idle));
  }

  void _onAccuracyUpdated(
    PracticeAccuracyUpdated event,
    Emitter<PracticeState> emit,
  ) {
    emit(state.copyWith(accuracy: event.accuracy));
  }

  void _onChordDetected(
    PracticeChordDetected event,
    Emitter<PracticeState> emit,
  ) {
    emit(state.copyWith(activeChord: event.chord));
  }
}
