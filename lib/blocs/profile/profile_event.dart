import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => <Object?>[];
}

class ProfileLoadRequested extends ProfileEvent {
  const ProfileLoadRequested();
}

class ProfileSaved extends ProfileEvent {
  const ProfileSaved({required this.name, required this.bio});

  final String name;
  final String bio;

  @override
  List<Object?> get props => <Object?>[name, bio];
}

class ProfilePhotoUpdated extends ProfileEvent {
  const ProfilePhotoUpdated();
}
