import 'package:equatable/equatable.dart';

class Profile extends Equatable {
  const Profile({
    required this.name,
    required this.bio,
    this.photoPath,
  });

  final String name;
  final String bio;
  final String? photoPath;

  Profile copyWith({
    String? name,
    String? bio,
    String? photoPath,
  }) {
    return Profile(
      name: name ?? this.name,
      bio: bio ?? this.bio,
      photoPath: photoPath ?? this.photoPath,
    );
  }

  @override
  List<Object?> get props => <Object?>[name, bio, photoPath];
}
