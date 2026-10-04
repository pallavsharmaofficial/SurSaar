import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sursaar/data/content/chord_library.dart';
import 'package:sursaar/data/content/content_normalizer.dart';
import 'package:sursaar/models/content_bundle.dart';
import 'package:sursaar/models/song.dart';
import 'package:sursaar/teacher/analysis/chord_templates.dart';
import 'package:sursaar/teacher/melody/tab_parser.dart';
import 'package:sursaar/tutor/journey.dart';
import 'package:sursaar/tutor/skill_profile.dart';
import 'package:sursaar/tutor/tutor_brain.dart';

/// Checks the tutor library that ships with the app.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<Song> songs;
  late ChordLibrary library;

  setUpAll(() async {
    library = await ChordLibrary.loadFromAsset();
    final raw = File('assets/data/local_bundle.json').readAsStringSync();
    final bundle = ContentBundle.fromJson(
      ContentNormalizer.normalize(jsonDecode(raw) as Map<String, dynamic>),
    );
    songs = bundle.songs;
  });

  test('bundled and published catalogues are identical', () {
    expect(
      File('assets/data/local_bundle.json').readAsStringSync(),
      File('content/sursaar_content.json').readAsStringSync(),
    );
  });

  test(
    'four shelves: 30 Bollywood, 30 global, 30 band, 10 instrumental new',
    () {
      int count(SongCollection c) =>
          songs.where((s) => s.collection == c).length;
      expect(count(SongCollection.bollywood), greaterThanOrEqualTo(30));
      expect(count(SongCollection.global), 30);
      expect(count(SongCollection.band), 30);
      expect(count(SongCollection.instrumental), 10);
      expect(songs.map((s) => s.id).toSet().length, songs.length);
      for (final id in <String>[
        'chanakya',
        'the_burning_ghat',
        'jana_gana_mana',
      ]) {
        expect(songs.any((s) => s.id == id), isTrue, reason: id);
      }
    },
  );

  test('no lyrics ship', () {
    for (final song in songs) {
      for (final section in song.sections) {
        for (final line in section.lines) {
          expect(line.lyric, isEmpty, reason: '${song.id} ${section.name}');
        }
      }
      expect(song.lyrics, isNull, reason: song.id);
    }
  });

  test('every chord can be shown and recognised', () {
    for (final song in songs) {
      for (final chord in song.uniqueChords) {
        expect(
          library.voicingFor(chord),
          isNotNull,
          reason: '${song.id}: $chord',
        );
        expect(
          ChordTemplates.templateFor(chord),
          isNotNull,
          reason: '${song.id}: $chord',
        );
      }
    }
  });

  test('melody tabs parse and stay on the fretboard', () {
    final melodies = songs.where((s) => s.hasMelody).toList();
    expect(melodies.length, greaterThanOrEqualTo(8));
    for (final song in melodies) {
      final tab = TabParser.parse(song.tabs!);
      expect(tab.notes.length, greaterThan(8), reason: song.id);
      expect(tab.notes.every((n) => n.fret >= 0 && n.fret <= 15), isTrue);
    }
    final anthem = songs.firstWhere((s) => s.id == 'jana_gana_mana');
    final first = TabParser.parse(
      anthem.tabs!,
    ).notes.take(3).map((n) => n.midi);
    // Sa Re Ga with Sa = C4.
    expect(first, <int>[60, 62, 64]);
  });

  test('every playable song gets a journey whose steps all build plans', () {
    final brain = TutorBrain(voicingFor: library.voicingFor);
    for (final song in songs) {
      final journey = JourneyBuilder.build(
        song,
        SkillProfile(),
        isBarre: brain.isBarre,
        nowMs: 1,
      );
      if (!song.hasMelody && song.uniqueChords.isEmpty) {
        expect(journey.stages, isEmpty, reason: song.id);
        continue;
      }
      expect(journey.stages.length, greaterThanOrEqualTo(3), reason: song.id);
      for (final stage in journey.stages) {
        final plan = JourneyBuilder.planFor(song, stage);
        expect(plan.targets, isNotEmpty, reason: '${song.id}: ${stage.title}');
        expect(
          plan.learnSteps,
          isNotEmpty,
          reason: '${song.id}: ${stage.title}',
        );
      }
    }
  });

  test('a first-day player is pointed at a friendly song', () {
    final brain = TutorBrain(voicingFor: library.voicingFor);
    final picks = brain.recommend(SkillProfile(), songs);
    final top = picks.first.song;
    expect(top.difficulty, SongDifficulty.beginner);
    expect(top.hasMelody, isFalse);
    expect(top.uniqueChords.where(brain.isBarre), isEmpty);
    // The top few are all barre-free beginner songs.
    for (final pick in picks.take(5)) {
      final journey = JourneyBuilder.build(
        pick.song,
        SkillProfile(),
        isBarre: brain.isBarre,
        nowMs: 1,
      );
      final chords = journey.stages.expand(
        (s) => <String>[...s.chords, ...s.sequence],
      );
      expect(chords.where(brain.isBarre), isEmpty, reason: pick.song.id);
    }
    // Songs waiting for a pasted tab come last.
    expect(picks.last.song.uniqueChords, isEmpty);
    expect(picks.last.song.hasMelody, isFalse);
  });
}
