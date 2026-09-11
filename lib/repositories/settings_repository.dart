import '../data/local/app_database.dart';
import '../models/user_settings.dart';

class SettingsRepository {
  const SettingsRepository({required AppDatabase database})
    : _database = database;

  final AppDatabase _database;

  Future<UserSettings> getSettings() async =>
      UserSettings.fromMap(await _database.getSettings());

  Future<void> saveSettings(UserSettings settings) =>
      _database.saveSettings(settings.toMap());
}
