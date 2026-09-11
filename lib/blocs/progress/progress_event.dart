import 'package:equatable/equatable.dart';

abstract class ProgressEvent extends Equatable {
  const ProgressEvent();

  @override
  List<Object?> get props => <Object?>[];
}

class ProgressLoadRequested extends ProgressEvent {
  const ProgressLoadRequested();
}

class ProgressPracticeTimeUpdated extends ProgressEvent {
  const ProgressPracticeTimeUpdated(this.minutes);

  final int minutes;

  @override
  List<Object?> get props => <Object?>[minutes];
}

class ProgressSongLearnedIncremented extends ProgressEvent {
  const ProgressSongLearnedIncremented();
}

class ProgressStreakUpdated extends ProgressEvent {
  const ProgressStreakUpdated(this.streak);

  final int streak;

  @override
  List<Object?> get props => <Object?>[streak];
}
