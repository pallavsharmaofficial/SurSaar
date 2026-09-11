import 'package:json_annotation/json_annotation.dart';
import 'chord_voicing.dart';
import 'course.dart';
import 'lesson.dart';
import 'song.dart';

part 'content_bundle.g.dart';

/// Everything the app needs to teach: lessons, courses, songs and chord
/// voicings. Fetched from GitHub, cached locally, with a bundled fallback.
@JsonSerializable(explicitToJson: true)
class ContentBundle {
  ContentBundle({
    required this.lessons,
    required this.songs,
    this.courses = const <Course>[],
    this.chords = const <ChordVoicing>[],
    this.version = '2.0',
    this.schemaVersion = 2,
    this.lastUpdated,
  });

  factory ContentBundle.fromJson(Map<String, dynamic> json) =>
      _$ContentBundleFromJson(json);

  final List<Lesson> lessons;
  final List<Song> songs;
  final List<Course> courses;
  final List<ChordVoicing> chords;
  final String version;
  final int schemaVersion;
  final String? lastUpdated;

  Map<String, dynamic> toJson() => _$ContentBundleToJson(this);

  ContentBundle merge(ContentBundle other) {
    Map<String, T> byId<T>(List<T> items, String Function(T) id) => <String, T>{
      for (final item in items) id(item): item,
    };
    final lessonsById = byId<Lesson>(lessons, (l) => l.id)
      ..addAll(byId<Lesson>(other.lessons, (l) => l.id));
    final songsById = byId<Song>(songs, (s) => s.id)
      ..addAll(byId<Song>(other.songs, (s) => s.id));
    final coursesById = byId<Course>(courses, (c) => c.id)
      ..addAll(byId<Course>(other.courses, (c) => c.id));
    final chordsByName = byId<ChordVoicing>(chords, (c) => c.name)
      ..addAll(byId<ChordVoicing>(other.chords, (c) => c.name));
    return ContentBundle(
      lessons: lessonsById.values.toList(growable: false),
      songs: songsById.values.toList(growable: false),
      courses: coursesById.values.toList(growable: false),
      chords: chordsByName.values.toList(growable: false),
      version: other.version,
      schemaVersion: other.schemaVersion,
      lastUpdated: other.lastUpdated ?? lastUpdated,
    );
  }
}
