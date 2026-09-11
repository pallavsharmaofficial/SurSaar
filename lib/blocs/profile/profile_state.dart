import 'package:equatable/equatable.dart';
import '../../models/profile.dart';

enum ProfileStatus { initial, loading, ready, error }

class ProfileState extends Equatable {
  const ProfileState({
    required this.status,
    required this.profile,
    this.errorMessage,
  });

  factory ProfileState.initial() => const ProfileState(
    status: ProfileStatus.initial,
    profile: Profile(
      name: 'Music Learner',
      bio: 'Learning music, one chord at a time.',
    ),
  );

  final ProfileStatus status;
  final Profile profile;
  final String? errorMessage;

  ProfileState copyWith({
    ProfileStatus? status,
    Profile? profile,
    String? errorMessage,
  }) {
    return ProfileState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[status, profile, errorMessage];
}
