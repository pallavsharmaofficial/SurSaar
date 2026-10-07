import 'package:flutter/foundation.dart';

import '../data/content/chord_library.dart';
import '../data/local/app_database.dart';
import '../models/song.dart';
import '../repositories/song_repository.dart';
import '../teacher/engine/performance_recorder.dart';
import 'journey.dart';
import 'skill_profile.dart';
import 'tutor_brain.dart';

/// The tutor's memory: loads/saves the [SkillProfile], starts journeys and
/// turns finished sessions into feedback.
class TutorRepository {
  TutorRepository({
    required AppDatabase database,
    required SongRepository songs,
    required ChordLibrary chordLibrary,
  }) : _database = database,
       _songs = songs,
       brain = TutorBrain(voicingFor: chordLibrary.voicingFor);

  final AppDatabase _database;
  final SongRepository _songs;
  final TutorBrain brain;

  /// Bumped after every change so screens can refresh.
  final ValueNotifier<int> revision = ValueNotifier<int>(0);

  SkillProfile? _cache;

  Future<SkillProfile> profile() async {
    final cached = _cache;
    if (cached != null) return cached;
    final json = await _database.getSkillProfile();
    SkillProfile loaded;
    try {
      loaded = SkillProfile.fromJson(json);
    } catch (_) {
      loaded = SkillProfile();
    }
    return _cache = loaded;
  }

  Future<void> _save(SkillProfile profile) async {
    _cache = profile;
    await _database.saveSkillProfile(profile.toJson());
    revision.value++;
  }

  Future<List<Song>> songs() => _songs.getSongs();

  Future<Song?> song(String id) => _songs.getSongById(id);

  Future<List<TutorPick>> recommendations({SongCollection? collection}) async =>
      brain.recommend(
        await profile(),
        await _songs.getSongs(),
        collection: collection,
      );

  /// The journey for [song], created (and remembered) on first use.
  Future<SongJourney> journeyFor(Song song) async {
    final current = await profile();
    final existing = current.journeys[song.id];
    if (existing != null && existing.stages.isNotEmpty) return existing;
    final updated = current.copy();
    final journey = JourneyBuilder.build(song, updated, isBarre: brain.isBarre);
    // Nothing to learn yet (no chords, no tab): don't remember it.
    if (journey.stages.isEmpty) return journey;
    updated.journeys[song.id] = journey;
    final shelf = song.collection?.name;
    if (shelf != null) {
      updated.collections[shelf] = (updated.collections[shelf] ?? 0) + 1;
    }
    await _save(updated);
    return journey;
  }

  /// Rebuilds the journey from the player's current skills.
  Future<SongJourney> restartJourney(Song song) async {
    final updated = (await profile()).copy()..journeys.remove(song.id);
    await _save(updated);
    return journeyFor(song);
  }

  /// Learns from a finished session and returns the tutor's feedback.
  Future<TutorFeedback> recordSession(
    SessionReport report, {
    String? songId,
    int? stageIndex,
    String? title,
  }) async {
    final before = await profile();
    final draft = brain.feedback(
      report,
      profile: before,
      journey: songId == null ? null : before.journeys[songId],
      stageIndex: stageIndex,
    );
    final after = brain.applyReport(
      before,
      report,
      songId: songId,
      stageIndex: stageIndex,
      title: title,
      headline: draft.headline,
    );
    await _save(after);
    return TutorFeedback(
      headline: draft.headline,
      verdict: draft.verdict,
      score: draft.score,
      passScore: draft.passScore,
      wentWell: draft.wentWell,
      improve: draft.improve,
      style: brain.styleNotes(after),
      nextStageIndex: draft.nextStageIndex,
      nextLabel: draft.nextLabel,
    );
  }

  Future<void> reset() async {
    _cache = SkillProfile();
    await _database.clearSkillProfile();
    revision.value++;
  }

  void dispose() => revision.dispose();
}
