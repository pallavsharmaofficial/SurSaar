import 'package:equatable/equatable.dart';

abstract class PracticeEvent extends Equatable {
  const PracticeEvent();

  @override
  List<Object?> get props => <Object?>[];
}

class PracticeStarted extends PracticeEvent {
  const PracticeStarted();
}

class PracticeStopped extends PracticeEvent {
  const PracticeStopped();
}

class PracticeAccuracyUpdated extends PracticeEvent {
  const PracticeAccuracyUpdated(this.accuracy);

  final double accuracy;

  @override
  List<Object?> get props => <Object?>[accuracy];
}

class PracticeChordDetected extends PracticeEvent {
  const PracticeChordDetected(this.chord);

  final String chord;

  @override
  List<Object?> get props => <Object?>[chord];
}
