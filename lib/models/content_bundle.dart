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

  /// Combines this bundle with [other]; on matching ids [other] wins –
  /// unless it is an older catalogue than this one (e.g. the published file
  /// before a new app release reaches it), in which case it only adds what
  /// this bundle doesn't have.
  ContentBundle merge(ContentBundle other) {
    final otherIsOlder = compareVersions(other.version, version) < 0;
    final (base, top) = otherIsOlder ? (other, this) : (this, other);
    Map<String, T> byId<T>(List<T> items, String Function(T) id) => <String, T>{
      for (final item in items) id(item): item,
    };
    final lessonsById = byId<Lesson>(base.lessons, (l) => l.id)
      ..addAll(byId<Lesson>(top.lessons, (l) => l.id));
    final songsById = byId<Song>(base.songs, (s) => s.id)
      ..addAll(byId<Song>(top.songs, (s) => s.id));
    final coursesById = byId<Course>(base.courses, (c) => c.id)
      ..addAll(byId<Course>(top.courses, (c) => c.id));
    final chordsByName = byId<ChordVoicing>(base.chords, (c) => c.name)
      ..addAll(byId<ChordVoicing>(top.chords, (c) => c.name));
    return ContentBundle(
      lessons: lessonsById.values.toList(growable: false),
      songs: songsById.values.toList(growable: false),
      courses: coursesById.values.toList(growable: false),
      chords: chordsByName.values.toList(growable: false),
      version: top.version,
      schemaVersion: top.schemaVersion,
      lastUpdated: top.lastUpdated ?? base.lastUpdated,
    );
  }

  /// Compares dotted versions numerically ("2.10.0" > "2.9").
  static int compareVersions(String a, String b) {
    List<int> parts(String v) => v
        .split('.')
        .map((p) => int.tryParse(p.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
        .toList();
    final pa = parts(a);
    final pb = parts(b);
    for (var i = 0; i < pa.length || i < pb.length; i++) {
      final x = i < pa.length ? pa[i] : 0;
      final y = i < pb.length ? pb[i] : 0;
      if (x != y) return x.compareTo(y);
    }
    return 0;
  }
}
