import 'local_store.dart';

/// Local persistence facade.
///
/// Keeps the same API the repositories already depend on, but stores JSON
/// documents in a [LocalStore] instead of sqlite so the exact same code runs
/// on the web.
class AppDatabase {
  AppDatabase({required LocalStore store}) : _store = store;

  final LocalStore _store;

  static const String _favoritesKey = 'favorites';
  static const String _lessonProgressKey = 'lesson_progress';
  static const String _userProgressKey = 'user_progress';
  static const String _practiceSessionsKey = 'practice_sessions';
  static const String _achievementsKey = 'achievements';
  static const String _profileKey = 'profile';
  static const String _settingsKey = 'settings';
  static const String _courseProgressKey = 'course_progress';

  // ---------------------------------------------------------------- favorites

  Future<Set<String>> getFavoriteSongIds() async {
    final map = await _store.getJsonMap(_favoritesKey) ?? <String, dynamic>{};
    return map.entries
        .where((entry) => entry.value == true)
        .map((entry) => entry.key)
        .toSet();
  }

  Future<void> setFavorite(String songId, bool isFavorite) async {
    final map = await _store.getJsonMap(_favoritesKey) ?? <String, dynamic>{};
    map[songId] = isFavorite;
    await _store.setJsonMap(_favoritesKey, map);
  }

  // ---------------------------------------------------------- lesson progress

  Future<Map<String, LessonProgressRow>> getLessonProgress() async {
    final map =
        await _store.getJsonMap(_lessonProgressKey) ?? <String, dynamic>{};
    final result = <String, LessonProgressRow>{};
    for (final entry in map.entries) {
      final value = entry.value;
      if (value is Map<String, dynamic>) {
        result[entry.key] = LessonProgressRow.fromMap(value);
      }
    }
    return result;
  }

  Future<void> upsertLessonProgress(LessonProgressRow progress) async {
    final map =
        await _store.getJsonMap(_lessonProgressKey) ?? <String, dynamic>{};
    map[progress.lessonId] = progress.toMap();
    await _store.setJsonMap(_lessonProgressKey, map);
  }

  // ------------------------------------------------------------ user progress

  Future<UserProgressRow> getUserProgress() async {
    final map = await _store.getJsonMap(_userProgressKey);
    if (map == null) return UserProgressRow.initial();
    return UserProgressRow.fromMap(map);
  }

  Future<void> saveUserProgress(UserProgressRow progress) =>
      _store.setJsonMap(_userProgressKey, progress.toMap());

  // -------------------------------------------------------- practice sessions

  Future<void> insertPracticeSession(PracticeSessionRow session) async {
    final list = await _store.getJsonList(_practiceSessionsKey) ?? <dynamic>[];
    list.removeWhere(
      (item) => item is Map<String, dynamic> && item['id'] == session.id,
    );
    list.add(session.toMap());
    await _store.setJsonList(_practiceSessionsKey, list);
  }

  Future<List<PracticeSessionRow>> getPracticeSessions() async {
    final list = await _store.getJsonList(_practiceSessionsKey) ?? <dynamic>[];
    return list
        .whereType<Map<String, dynamic>>()
        .map(PracticeSessionRow.fromMap)
        .toList(growable: false);
  }

  Future<int> getPracticeSessionCount() async =>
      (await getPracticeSessions()).length;

  // ------------------------------------------------------------- achievements

  Future<List<AchievementRow>> getAchievements() async {
    final list = await _store.getJsonList(_achievementsKey) ?? <dynamic>[];
    final rows = list
        .whereType<Map<String, dynamic>>()
        .map(AchievementRow.fromMap)
        .toList();
    rows.sort((a, b) => b.earnedAt.compareTo(a.earnedAt));
    return rows;
  }

  Future<void> insertAchievement(AchievementRow achievement) async {
    final list = await _store.getJsonList(_achievementsKey) ?? <dynamic>[];
    final exists = list.any(
      (item) => item is Map<String, dynamic> && item['id'] == achievement.id,
    );
    if (exists) return; // achievements are earned once
    list.add(achievement.toMap());
    await _store.setJsonList(_achievementsKey, list);
  }

  // ------------------------------------------------------------------ profile

  Future<ProfileRow> getProfile() async {
    final map = await _store.getJsonMap(_profileKey);
    if (map == null) return ProfileRow.initial();
    return ProfileRow.fromMap(map);
  }

  Future<void> saveProfile(ProfileRow profile) =>
      _store.setJsonMap(_profileKey, profile.toMap());

  // ----------------------------------------------------------------- settings

  Future<Map<String, dynamic>> getSettings() async =>
      await _store.getJsonMap(_settingsKey) ?? <String, dynamic>{};

  Future<void> saveSettings(Map<String, dynamic> settings) =>
      _store.setJsonMap(_settingsKey, settings);

  // ---------------------------------------------------------- course progress

  Future<Map<String, dynamic>> getCourseProgress() async =>
      await _store.getJsonMap(_courseProgressKey) ?? <String, dynamic>{};

  Future<void> saveCourseProgress(Map<String, dynamic> progress) =>
      _store.setJsonMap(_courseProgressKey, progress);
}

class LessonProgressRow {
  LessonProgressRow({
    required this.lessonId,
    required this.progress,
    required this.isCompleted,
    required this.updatedAt,
  });

  final String lessonId;
  final double progress;
  final bool isCompleted;
  final DateTime updatedAt;

  Map<String, Object?> toMap() => <String, Object?>{
    'lesson_id': lessonId,
    'progress': progress,
    'is_completed': isCompleted,
    'updated_at': updatedAt.millisecondsSinceEpoch,
  };

  factory LessonProgressRow.fromMap(Map<String, Object?> map) {
    return LessonProgressRow(
      lessonId: map['lesson_id'] as String,
      progress: (map['progress'] as num).toDouble(),
      isCompleted: _asBool(map['is_completed']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        (map['updated_at'] as num).toInt(),
      ),
    );
  }
}

class UserProgressRow {
  UserProgressRow({
    required this.totalPracticeTime,
    required this.songsLearned,
    required this.currentStreak,
    required this.longestStreak,
    required this.averageAccuracy,
    required this.lessonsCompleted,
    required this.level,
    required this.xp,
    this.lastPracticeDay,
  });

  factory UserProgressRow.initial() => UserProgressRow(
    totalPracticeTime: 0,
    songsLearned: 0,
    currentStreak: 0,
    longestStreak: 0,
    averageAccuracy: 0,
    lessonsCompleted: 0,
    level: 1,
    xp: 0,
  );

  final int totalPracticeTime;
  final int songsLearned;
  final int currentStreak;
  final int longestStreak;
  final double averageAccuracy;
  final int lessonsCompleted;
  final int level;
  final int xp;

  /// Calendar day (yyyy-mm-dd) of the last saved practice, for streaks.
  final String? lastPracticeDay;

  Map<String, Object?> toMap() => <String, Object?>{
    'total_practice_time': totalPracticeTime,
    'songs_learned': songsLearned,
    'current_streak': currentStreak,
    'longest_streak': longestStreak,
    'average_accuracy': averageAccuracy,
    'lessons_completed': lessonsCompleted,
    'level': level,
    'xp': xp,
    'last_practice_day': lastPracticeDay,
  };

  factory UserProgressRow.fromMap(Map<String, Object?> map) {
    return UserProgressRow(
      totalPracticeTime: (map['total_practice_time'] as num?)?.toInt() ?? 0,
      songsLearned: (map['songs_learned'] as num?)?.toInt() ?? 0,
      currentStreak: (map['current_streak'] as num?)?.toInt() ?? 0,
      longestStreak: (map['longest_streak'] as num?)?.toInt() ?? 0,
      averageAccuracy: (map['average_accuracy'] as num?)?.toDouble() ?? 0,
      lessonsCompleted: (map['lessons_completed'] as num?)?.toInt() ?? 0,
      level: (map['level'] as num?)?.toInt() ?? 1,
      xp: (map['xp'] as num?)?.toInt() ?? 0,
      lastPracticeDay: map['last_practice_day'] as String?,
    );
  }
}

class AchievementRow {
  AchievementRow({
    required this.id,
    required this.title,
    required this.description,
    required this.iconAsset,
    required this.earnedAt,
  });

  final String id;
  final String title;
  final String description;
  final String iconAsset;
  final DateTime earnedAt;

  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'title': title,
    'description': description,
    'icon_asset': iconAsset,
    'earned_at': earnedAt.millisecondsSinceEpoch,
  };

  factory AchievementRow.fromMap(Map<String, Object?> map) {
    return AchievementRow(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      iconAsset: map['icon_asset'] as String,
      earnedAt: DateTime.fromMillisecondsSinceEpoch(
        (map['earned_at'] as num).toInt(),
      ),
    );
  }
}

class ProfileRow {
  ProfileRow({required this.name, required this.bio, this.photoData});

  factory ProfileRow.initial() => ProfileRow(
    name: 'Music Learner',
    bio: 'Learning music, one chord at a time.',
  );

  final String name;
  final String bio;

  /// Base64 data URL of the profile photo (platform independent).
  final String? photoData;

  Map<String, Object?> toMap() => <String, Object?>{
    'name': name,
    'bio': bio,
    'photo_data': photoData,
  };

  factory ProfileRow.fromMap(Map<String, Object?> map) {
    return ProfileRow(
      name: map['name'] as String? ?? 'Music Learner',
      bio: map['bio'] as String? ?? '',
      photoData: map['photo_data'] as String?,
    );
  }
}

class PracticeSessionRow {
  PracticeSessionRow({
    required this.id,
    required this.songId,
    required this.startTime,
    required this.duration,
    required this.accuracy,
    required this.chordsPlayed,
    required this.mistakes,
    this.timingAccuracy,
    this.mode,
  });

  final String id;
  final String songId;
  final DateTime startTime;
  final int duration;
  final double accuracy;
  final int chordsPlayed;
  final int mistakes;
  final double? timingAccuracy;
  final String? mode;

  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'song_id': songId,
    'start_time': startTime.millisecondsSinceEpoch,
    'duration': duration,
    'accuracy': accuracy,
    'chords_played': chordsPlayed,
    'mistakes': mistakes,
    'timing_accuracy': timingAccuracy,
    'mode': mode,
  };

  factory PracticeSessionRow.fromMap(Map<String, Object?> map) {
    return PracticeSessionRow(
      id: map['id'] as String,
      songId: map['song_id'] as String,
      startTime: DateTime.fromMillisecondsSinceEpoch(
        (map['start_time'] as num).toInt(),
      ),
      duration: (map['duration'] as num).toInt(),
      accuracy: (map['accuracy'] as num).toDouble(),
      chordsPlayed: (map['chords_played'] as num).toInt(),
      mistakes: (map['mistakes'] as num).toInt(),
      timingAccuracy: (map['timing_accuracy'] as num?)?.toDouble(),
      mode: map['mode'] as String?,
    );
  }
}

bool _asBool(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  return false;
}
