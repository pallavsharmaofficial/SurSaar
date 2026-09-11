import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// A tiny key/value document store used for all local persistence.
///
/// The app previously used sqflite, which has no web implementation. Every
/// piece of local state SurSaar keeps (favourites, lesson progress, sessions,
/// achievements, profile, settings, content cache) is small, so a JSON
/// document store over `shared_preferences` works identically on Android,
/// iOS, desktop and the web (where it is backed by `localStorage`).
abstract class LocalStore {
  Future<String?> getString(String key);

  Future<void> setString(String key, String value);

  Future<void> remove(String key);

  Future<Map<String, dynamic>?> getJsonMap(String key) async {
    final raw = await getString(key);
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    return decoded is Map<String, dynamic> ? decoded : null;
  }

  Future<void> setJsonMap(String key, Map<String, dynamic> value) =>
      setString(key, jsonEncode(value));

  Future<List<dynamic>?> getJsonList(String key) async {
    final raw = await getString(key);
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    return decoded is List<dynamic> ? decoded : null;
  }

  Future<void> setJsonList(String key, List<dynamic> value) =>
      setString(key, jsonEncode(value));
}

/// [LocalStore] backed by `shared_preferences`.
class PrefsLocalStore extends LocalStore {
  PrefsLocalStore({String prefix = 'sursaar.'}) : _prefix = prefix;

  final String _prefix;
  SharedPreferences? _prefs;

  Future<SharedPreferences> get _instance async =>
      _prefs ??= await SharedPreferences.getInstance();

  @override
  Future<String?> getString(String key) async =>
      (await _instance).getString('$_prefix$key');

  @override
  Future<void> setString(String key, String value) async =>
      (await _instance).setString('$_prefix$key', value);

  @override
  Future<void> remove(String key) async =>
      (await _instance).remove('$_prefix$key');
}

/// In-memory [LocalStore] for tests and previews.
class InMemoryLocalStore extends LocalStore {
  final Map<String, String> _data = <String, String>{};

  @override
  Future<String?> getString(String key) async => _data[key];

  @override
  Future<void> setString(String key, String value) async => _data[key] = value;

  @override
  Future<void> remove(String key) async => _data.remove(key);
}
