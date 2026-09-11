import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/lesson_repository.dart';
import 'lesson_event.dart';
import 'lesson_state.dart';

class LessonBloc extends Bloc<LessonEvent, LessonState> {
  LessonBloc({required LessonRepository repository})
    : _repository = repository,
      super(LessonState.initial()) {
    on<LessonLoadRequested>(_onLoadRequested);
    on<LessonDifficultyFilterChanged>(_onDifficultyFilterChanged);
  }

  final LessonRepository _repository;

  Future<void> _onLoadRequested(
    LessonLoadRequested event,
    Emitter<LessonState> emit,
  ) async {
    emit(state.copyWith(status: LessonStatus.loading));
    try {
      final lessons = state.selectedDifficulty == null
          ? await _repository.getLessons()
          : await _repository.getLessonsByDifficulty(state.selectedDifficulty!);
      emit(state.copyWith(status: LessonStatus.loaded, lessons: lessons));
    } catch (e) {
      emit(
        state.copyWith(status: LessonStatus.error, errorMessage: e.toString()),
      );
    }
  }

  Future<void> _onDifficultyFilterChanged(
    LessonDifficultyFilterChanged event,
    Emitter<LessonState> emit,
  ) async {
    if (event.difficulty == null) {
      final lessons = await _repository.getLessons();
      emit(state.copyWith(lessons: lessons, clearDifficulty: true));
    } else {
      final lessons = await _repository.getLessonsByDifficulty(
        event.difficulty!,
      );
      emit(
        state.copyWith(lessons: lessons, selectedDifficulty: event.difficulty),
      );
    }
  }
}
