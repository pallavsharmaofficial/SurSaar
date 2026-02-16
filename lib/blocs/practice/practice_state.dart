import 'package:equatable/equatable.dart';

enum PracticeStatus {
  idle,
  listening,
}

class PracticeState extends Equatable {
  const PracticeState({
    required this.status,
    required this.accuracy,
    required this.activeChord,
  });

  factory PracticeState.initial() => const PracticeState(
        status: PracticeStatus.idle,
        accuracy: 0.0,
        activeChord: 'G',
      );

  final PracticeStatus status;
  final double accuracy;
  final String activeChord;

  PracticeState copyWith({
    PracticeStatus? status,
    double? accuracy,
    String? activeChord,
  }) {
    return PracticeState(
      status: status ?? this.status,
      accuracy: accuracy ?? this.accuracy,
      activeChord: activeChord ?? this.activeChord,
    );
  }

  @override
  List<Object?> get props => <Object?>[status, accuracy, activeChord];
}
