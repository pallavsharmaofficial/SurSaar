import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static const String _dbName = 'sursaar.db';
  static const int _dbVersion = 2;

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute(''
        'CREATE TABLE favorites('
        'song_id TEXT PRIMARY KEY,'
        'is_favorite INTEGER NOT NULL'
        ')'
        '');

    await db.execute(''
        'CREATE TABLE lesson_progress('
        'lesson_id TEXT PRIMARY KEY,'
        'progress REAL NOT NULL,'
        'is_completed INTEGER NOT NULL,'
        'updated_at INTEGER NOT NULL'
        ')'
        '');

    await db.execute(''
        'CREATE TABLE practice_sessions('
        'id TEXT PRIMARY KEY,'
        'song_id TEXT NOT NULL,'
        'start_time INTEGER NOT NULL,'
        'duration INTEGER NOT NULL,'
        'accuracy REAL NOT NULL,'
        'chords_played INTEGER NOT NULL,'
        'mistakes INTEGER NOT NULL'
        ')'
        '');

    await db.execute(''
        'CREATE TABLE user_progress('
        'id INTEGER PRIMARY KEY,'
        'total_practice_time INTEGER NOT NULL,'
        'songs_learned INTEGER NOT NULL,'
        'current_streak INTEGER NOT NULL,'
        'longest_streak INTEGER NOT NULL,'
        'average_accuracy REAL NOT NULL,'
        'lessons_completed INTEGER NOT NULL,'
      'level INTEGER NOT NULL,'
      'xp INTEGER NOT NULL'
        ')'
        '');

    await db.execute(''
      'CREATE TABLE achievements('
      'id TEXT PRIMARY KEY,'
      'title TEXT NOT NULL,'
      'description TEXT NOT NULL,'
      'icon_asset TEXT NOT NULL,'
      'earned_at INTEGER NOT NULL'
      ')'
      '');

    await db.execute(''
      'CREATE TABLE profile('
      'id INTEGER PRIMARY KEY,'
      'name TEXT NOT NULL,'
      'bio TEXT NOT NULL,'
      'photo_path TEXT'
      ')'
      '');

    await db.insert('user_progress', <String, Object?>{
      'id': 0,
      'total_practice_time': 0,
      'songs_learned': 0,
      'current_streak': 0,
      'longest_streak': 0,
      'average_accuracy': 0.0,
      'lessons_completed': 0,
      'level': 1,
      'xp': 0,
    });

    await db.insert('profile', <String, Object?>{
      'id': 0,
      'name': 'Music Learner',
      'bio': 'Learning music, one chord at a time.',
      'photo_path': null,
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE user_progress ADD COLUMN xp INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute(''
          'CREATE TABLE achievements('
          'id TEXT PRIMARY KEY,'
          'title TEXT NOT NULL,'
          'description TEXT NOT NULL,'
          'icon_asset TEXT NOT NULL,'
          'earned_at INTEGER NOT NULL'
          ')'
          '');
      await db.execute(''
          'CREATE TABLE profile('
          'id INTEGER PRIMARY KEY,'
          'name TEXT NOT NULL,'
          'bio TEXT NOT NULL,'
          'photo_path TEXT'
          ')'
          '');
      await db.insert('profile', <String, Object?>{
        'id': 0,
        'name': 'Music Learner',
        'bio': 'Learning music, one chord at a time.',
        'photo_path': null,
      });
    }
  }

  Future<Set<String>> getFavoriteSongIds() async {
    final db = await database;
    final rows = await db.query('favorites');
    return rows
        .where((row) => (row['is_favorite'] as int) == 1)
        .map((row) => row['song_id'] as String)
        .toSet();
  }

  Future<void> setFavorite(String songId, bool isFavorite) async {
    final db = await database;
    await db.insert(
      'favorites',
      <String, Object?>{
        'song_id': songId,
        'is_favorite': isFavorite ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, LessonProgressRow>> getLessonProgress() async {
    final db = await database;
    final rows = await db.query('lesson_progress');
    final result = <String, LessonProgressRow>{};
    for (final row in rows) {
      final progress = LessonProgressRow.fromMap(row);
      result[progress.lessonId] = progress;
    }
    return result;
  }

  Future<void> upsertLessonProgress(LessonProgressRow progress) async {
    final db = await database;
    await db.insert(
      'lesson_progress',
      progress.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<UserProgressRow> getUserProgress() async {
    final db = await database;
    final rows = await db.query('user_progress', where: 'id = 0');
    return UserProgressRow.fromMap(rows.first);
  }

  Future<void> saveUserProgress(UserProgressRow progress) async {
    final db = await database;
    await db.update(
      'user_progress',
      progress.toMap(),
      where: 'id = 0',
    );
  }

  Future<void> insertPracticeSession(PracticeSessionRow session) async {
    final db = await database;
    await db.insert(
      'practice_sessions',
      session.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> getPracticeSessionCount() async {
    final db = await database;
    final result =
        await db.rawQuery('SELECT COUNT(*) as count FROM practice_sessions');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<AchievementRow>> getAchievements() async {
    final db = await database;
    final rows = await db.query('achievements', orderBy: 'earned_at DESC');
    return rows.map(AchievementRow.fromMap).toList(growable: false);
  }

  Future<void> insertAchievement(AchievementRow achievement) async {
    final db = await database;
    await db.insert(
      'achievements',
      achievement.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<ProfileRow> getProfile() async {
    final db = await database;
    final rows = await db.query('profile', where: 'id = 0');
    return ProfileRow.fromMap(rows.first);
  }

  Future<void> saveProfile(ProfileRow profile) async {
    final db = await database;
    await db.update(
      'profile',
      profile.toMap(),
      where: 'id = 0',
    );
  }
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
        'is_completed': isCompleted ? 1 : 0,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };

  factory LessonProgressRow.fromMap(Map<String, Object?> map) {
    return LessonProgressRow(
      lessonId: map['lesson_id'] as String,
      progress: (map['progress'] as num).toDouble(),
      isCompleted: (map['is_completed'] as int) == 1,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        map['updated_at'] as int,
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
  });

  final int totalPracticeTime;
  final int songsLearned;
  final int currentStreak;
  final int longestStreak;
  final double averageAccuracy;
  final int lessonsCompleted;
  final int level;
  final int xp;

    Map<String, Object?> toMap() => <String, Object?>{
        'id': 0,
        'total_practice_time': totalPracticeTime,
        'songs_learned': songsLearned,
        'current_streak': currentStreak,
        'longest_streak': longestStreak,
        'average_accuracy': averageAccuracy,
        'lessons_completed': lessonsCompleted,
      'level': level,
      'xp': xp,
      };

  factory UserProgressRow.fromMap(Map<String, Object?> map) {
    return UserProgressRow(
      totalPracticeTime: map['total_practice_time'] as int,
      songsLearned: map['songs_learned'] as int,
      currentStreak: map['current_streak'] as int,
      longestStreak: map['longest_streak'] as int,
      averageAccuracy: (map['average_accuracy'] as num).toDouble(),
      lessonsCompleted: map['lessons_completed'] as int,
      level: map['level'] as int,
      xp: (map['xp'] as int?) ?? 0,
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
        map['earned_at'] as int,
      ),
    );
  }
}

class ProfileRow {
  ProfileRow({
    required this.name,
    required this.bio,
    this.photoPath,
  });

  final String name;
  final String bio;
  final String? photoPath;

  Map<String, Object?> toMap() => <String, Object?>{
        'id': 0,
        'name': name,
        'bio': bio,
        'photo_path': photoPath,
      };

  factory ProfileRow.fromMap(Map<String, Object?> map) {
    return ProfileRow(
      name: map['name'] as String,
      bio: map['bio'] as String,
      photoPath: map['photo_path'] as String?,
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
  });

  final String id;
  final String songId;
  final DateTime startTime;
  final int duration;
  final double accuracy;
  final int chordsPlayed;
  final int mistakes;

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'song_id': songId,
        'start_time': startTime.millisecondsSinceEpoch,
        'duration': duration,
        'accuracy': accuracy,
        'chords_played': chordsPlayed,
        'mistakes': mistakes,
      };
}
