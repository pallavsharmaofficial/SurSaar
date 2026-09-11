import 'package:equatable/equatable.dart';

class Profile extends Equatable {
  const Profile({required this.name, required this.bio, this.photoData});

  final String name;
  final String bio;

  /// Base64 data URL (`data:image/...;base64,...`) so the photo persists on
  /// every platform, including the web.
  final String? photoData;

  Profile copyWith({String? name, String? bio, String? photoData}) {
    return Profile(
      name: name ?? this.name,
      bio: bio ?? this.bio,
      photoData: photoData ?? this.photoData,
    );
  }

  @override
  List<Object?> get props => <Object?>[name, bio, photoData];
}
