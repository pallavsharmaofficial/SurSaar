import 'dart:convert';

import 'package:image_picker/image_picker.dart';

import '../data/local/app_database.dart';
import '../models/profile.dart';

class ProfileRepository {
  ProfileRepository({required AppDatabase database, ImagePicker? picker})
    : _database = database,
      _picker = picker ?? ImagePicker();

  final AppDatabase _database;
  final ImagePicker _picker;

  Future<Profile> getProfile() async {
    final row = await _database.getProfile();
    return Profile(name: row.name, bio: row.bio, photoData: row.photoData);
  }

  Future<void> saveProfile(Profile profile) async {
    await _database.saveProfile(
      ProfileRow(
        name: profile.name,
        bio: profile.bio,
        photoData: profile.photoData,
      ),
    );
  }

  /// Lets the user pick a photo and returns it as a base64 data URL so it
  /// can be stored and displayed on every platform (including web).
  Future<String?> pickProfilePhoto() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (image == null) return null;
    final bytes = await image.readAsBytes();
    final mime = image.mimeType ?? _guessMime(image.name);
    return 'data:$mime;base64,${base64Encode(bytes)}';
  }

  static String _guessMime(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }
}
