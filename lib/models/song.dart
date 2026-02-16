import 'package:equatable/equatable.dart';

class Song extends Equatable {
  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.difficulty,
    required this.strummingPattern,
    required this.originalChords,
    required this.tutorialUrl,
  });

  final String id;
  final String title;
  final String artist;
  final String difficulty;
  final String strummingPattern;
  final List<String> originalChords;
  final String tutorialUrl;

  @override
  List<Object?> get props => <Object?>[
        id,
        title,
        artist,
        difficulty,
        strummingPattern,
        originalChords,
        tutorialUrl,
      ];
}
