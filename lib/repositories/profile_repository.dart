import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../data/local/app_database.dart';
import '../models/profile.dart';

class ProfileRepository {
  ProfileRepository({
    required AppDatabase database,
  }) : _database = database;

  final AppDatabase _database;
  final ImagePicker _picker = ImagePicker();

  Future<Profile> getProfile() async {
    final row = await _database.getProfile();
    return Profile(
      name: row.name,
      bio: row.bio,
      photoPath: row.photoPath,
    );
  }

  Future<void> saveProfile(Profile profile) async {
    await _database.saveProfile(
      ProfileRow(
        name: profile.name,
        bio: profile.bio,
        photoPath: profile.photoPath,
      ),
    );
  }

  Future<String?> pickAndSaveProfilePhoto() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return null;

    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.png';
    final targetPath = p.join(directory.path, fileName);
    await File(image.path).copy(targetPath);
    return targetPath;
  }
}
