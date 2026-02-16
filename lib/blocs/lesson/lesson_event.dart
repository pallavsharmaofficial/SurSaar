import 'package:equatable/equatable.dart';
import '../../models/lesson.dart';

abstract class LessonEvent extends Equatable {
  const LessonEvent();

  @override
  List<Object?> get props => <Object?>[];
}

class LessonLoadRequested extends LessonEvent {
  const LessonLoadRequested();
}

class FetchContentEvent extends LessonEvent {
  const FetchContentEvent();
}

class LessonDifficultyFilterChanged extends LessonEvent {
  const LessonDifficultyFilterChanged(this.difficulty);

  final LessonDifficulty? difficulty;

  @override
  List<Object?> get props => <Object?>[difficulty];
}
