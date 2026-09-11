import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/progress_repository.dart';
import 'progress_event.dart';
import 'progress_state.dart';

class ProgressBloc extends Bloc<ProgressEvent, ProgressState> {
  ProgressBloc({required ProgressRepository repository})
    : _repository = repository,
      super(ProgressState.initial()) {
    on<ProgressLoadRequested>(_onLoadRequested);
    on<ProgressPracticeTimeUpdated>(_onPracticeTimeUpdated);
    on<ProgressSongLearnedIncremented>(_onSongLearnedIncremented);
    on<ProgressStreakUpdated>(_onStreakUpdated);
  }

  final ProgressRepository _repository;

  Future<void> _onLoadRequested(
    ProgressLoadRequested event,
    Emitter<ProgressState> emit,
  ) async {
    emit(state.copyWith(status: ProgressStatus.loading));
    try {
      final progress = await _repository.getProgress();
      emit(state.copyWith(status: ProgressStatus.loaded, progress: progress));
    } catch (e) {
      emit(
        state.copyWith(
          status: ProgressStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onPracticeTimeUpdated(
    ProgressPracticeTimeUpdated event,
    Emitter<ProgressState> emit,
  ) async {
    try {
      await _repository.updatePracticeTime(event.minutes);
      final progress = await _repository.getProgress();
      emit(state.copyWith(progress: progress));
    } catch (e) {
      emit(
        state.copyWith(
          status: ProgressStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onSongLearnedIncremented(
    ProgressSongLearnedIncremented event,
    Emitter<ProgressState> emit,
  ) async {
    try {
      await _repository.incrementSongsLearned();
      final progress = await _repository.getProgress();
      emit(state.copyWith(progress: progress));
    } catch (e) {
      emit(
        state.copyWith(
          status: ProgressStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onStreakUpdated(
    ProgressStreakUpdated event,
    Emitter<ProgressState> emit,
  ) async {
    try {
      await _repository.updateStreak(event.streak);
      final progress = await _repository.getProgress();
      emit(state.copyWith(progress: progress));
    } catch (e) {
      emit(
        state.copyWith(
          status: ProgressStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
