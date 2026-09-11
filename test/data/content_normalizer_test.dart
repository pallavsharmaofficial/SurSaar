import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sursaar/models/lesson.dart';
import 'package:sursaar/models/song.dart';
import 'package:sursaar/repositories/content_repository.dart';

const legacyContent = '''
{
  "metadata": {"version": "1.2.0", "app_name": "SurSaar AI"},
  "lessons": [
    {
      "id": "gtr_lesson_201",
      "category": "Technique",
      "title": "Bollywood Strumming: The 8-Beat Flow",
      "difficulty": "Intermediate",
      "instrument": "Guitar",
      "ai_config": {"mode": "rhythm_tracking", "target_bpm": 85, "pattern": "D-X-DU-X-DU"},
      "content": {"description": "Muted slap.", "steps": ["Downstroke.", "Mute.", "Up-down."]}
    },
    {
      "id": "gtr_lesson_101",
      "title": "The Open Chord Foundation",
      "difficulty": "Beginner",
      "ai_config": {"mode": "audio_analysis"},
      "content": {"description": "Learn to play the G-Major and C-Major open chords.", "steps": ["a"]}
    }
  ],
  "songs": [
    {
      "id": "s_bolly_004",
      "title": "Kabira",
      "artist": "Tochi Raina",
      "movie": "YJHD",
      "difficulty": "Easy",
      "base_key": "D Major",
      "capo": 0,
      "strumming": "D - DU - D - DU",
      "chords": ["D", "G", "A", "Bm"],
      "progression": ["D", "G", "A", "G"],
      "tags": ["Folk-Pop"]
    }
  ],
  "exercises": [
    {"id": "ex_001", "title": "Spider Walk", "target": "Dexterity", "bpm_range": [60, 120], "instruction": "1-2-3-4 on every string."}
  ]
}
''';

void main() {
  test('legacy content-engine JSON parses into v2 models', () {
    final bundle = ContentRepository.parseBundle(legacyContent);

    expect(bundle.songs.length, 1);
    final song = bundle.songs.first;
    expect(song.difficulty, SongDifficulty.beginner);
    expect(song.key, 'D');
    expect(song.album, 'YJHD');
    expect(song.originalChords, <String>['D', 'G', 'A', 'Bm']);
    expect(song.strummingPattern, 'D - DU - D - DU');
    expect(song.sections.first.chordSequence, <String>['D', 'G', 'A', 'G']);

    expect(bundle.lessons.length, 3);
    final strum = bundle.lessons.firstWhere((l) => l.id == 'gtr_lesson_201');
    expect(strum.kind, LessonKind.strumming);
    expect(strum.targetStrumming, 'D-X-DU-X-DU');
    expect(strum.targetBpm, 85);
    expect(strum.steps.length, 3);
    expect(strum.difficulty, LessonDifficulty.intermediate);

    final chords = bundle.lessons.firstWhere((l) => l.id == 'gtr_lesson_101');
    expect(chords.kind, LessonKind.chord);
    expect(chords.targetChords, <String>['G', 'C']);

    final exercise = bundle.lessons.firstWhere((l) => l.id == 'ex_001');
    expect(exercise.kind, LessonKind.exercise);
    expect(exercise.targetBpm, 60);
  });

  test('v2 JSON round-trips', () {
    final bundle = ContentRepository.parseBundle(legacyContent);
    final encoded = jsonEncode(bundle.toJson());
    final again = ContentRepository.parseBundle(encoded);
    expect(again.songs.first.toJson(), bundle.songs.first.toJson());
    expect(again.lessons.length, bundle.lessons.length);
  });
}
