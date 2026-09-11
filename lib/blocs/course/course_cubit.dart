import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../repositories/course_repository.dart';

class CourseState extends Equatable {
  const CourseState({
    this.loading = true,
    this.courses = const <CourseProgress>[],
  });

  final bool loading;
  final List<CourseProgress> courses;

  @override
  List<Object?> get props => <Object?>[loading, courses];
}

class CourseCubit extends Cubit<CourseState> {
  CourseCubit({required CourseRepository repository})
    : _repository = repository,
      super(const CourseState());

  final CourseRepository _repository;

  Future<void> load() async {
    final courses = await _repository.getCourses();
    if (isClosed) return;
    emit(CourseState(loading: false, courses: courses));
  }
}
