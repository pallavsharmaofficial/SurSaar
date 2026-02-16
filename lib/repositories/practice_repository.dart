import 'package:uuid/uuid.dart';
import '../data/local/app_database.dart';
import '../models/practice_session.dart';

class PracticeRepository {
  PracticeRepository({
    required AppDatabase database,
  }) : _database = database;

  final AppDatabase _database;
  static const _uuid = Uuid();

  Future<void> saveSession(PracticeSession session) async {
    await _database.insertPracticeSession(
      PracticeSessionRow(
        id: session.id,
        songId: session.songId,
        startTime: session.startTime,
        duration: session.duration,
        accuracy: session.accuracyScore,
        chordsPlayed: session.chordsPlayed,
        mistakes: session.mistakeCount,
      ),
    );
  }

  PracticeSession createSession({
    required String songId,
    required DateTime startTime,
    required int duration,
    required double accuracy,
    required int chordsPlayed,
    required int mistakes,
  }) {
    return PracticeSession(
      id: _uuid.v4(),
      songId: songId,
      startTime: startTime,
      duration: duration,
      accuracyScore: accuracy,
      chordsPlayed: chordsPlayed,
      mistakeCount: mistakes,
    );
  }
}
