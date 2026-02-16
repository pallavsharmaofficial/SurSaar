import 'package:equatable/equatable.dart';
import '../../models/lesson.dart';

enum LessonStatus {
  initial,
  loading,
  loaded,
  error,
}

class LessonState extends Equatable {
  const LessonState({
    required this.status,
    required this.lessons,
    required this.selectedDifficulty,
    this.errorMessage,
  });

  factory LessonState.initial() => const LessonState(
        status: LessonStatus.initial,
        lessons: <Lesson>[],
        selectedDifficulty: null,
      );

  final LessonStatus status;
  final List<Lesson> lessons;
  final LessonDifficulty? selectedDifficulty;
  final String? errorMessage;

  LessonState copyWith({
    LessonStatus? status,
    List<Lesson>? lessons,
    LessonDifficulty? selectedDifficulty,
    String? errorMessage,
    bool clearDifficulty = false,
  }) {
    return LessonState(
      status: status ?? this.status,
      lessons: lessons ?? this.lessons,
      selectedDifficulty:
          clearDifficulty ? null : (selectedDifficulty ?? this.selectedDifficulty),
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      <Object?>[status, lessons, selectedDifficulty, errorMessage];
}
