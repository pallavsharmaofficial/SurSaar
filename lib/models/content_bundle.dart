import 'package:json_annotation/json_annotation.dart';
import 'lesson.dart';
import 'song.dart';

part 'content_bundle.g.dart';

@JsonSerializable(explicitToJson: true)
class ContentBundle {
  ContentBundle({
    required this.lessons,
    required this.songs,
    this.version = '1.0',
    this.lastUpdated,
  });

  factory ContentBundle.fromJson(Map<String, dynamic> json) =>
      _$ContentBundleFromJson(json);

  final List<Lesson> lessons;
  final List<Song> songs;
  final String version;
  final String? lastUpdated;

  Map<String, dynamic> toJson() => _$ContentBundleToJson(this);
}
