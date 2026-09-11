import 'package:equatable/equatable.dart';
import '../../models/user_progress.dart';

enum ProgressStatus { initial, loading, loaded, error }

class ProgressState extends Equatable {
  const ProgressState({
    required this.status,
    required this.progress,
    this.errorMessage,
  });

  factory ProgressState.initial() => ProgressState(
    status: ProgressStatus.initial,
    progress: UserProgress.initial(),
  );

  final ProgressStatus status;
  final UserProgress progress;
  final String? errorMessage;

  ProgressState copyWith({
    ProgressStatus? status,
    UserProgress? progress,
    String? errorMessage,
  }) {
    return ProgressState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[status, progress, errorMessage];
}
