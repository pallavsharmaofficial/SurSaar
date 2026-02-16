import '../core/utils/chord_transposer.dart';
import '../models/song.dart';

class SongRepository {
  const SongRepository();

  List<Song> getSongs() => const <Song>[
        Song(
          id: 'o_sanam',
          title: 'O Sanam',
          artist: 'Lucky Ali',
          difficulty: 'Beginner',
          strummingPattern: 'D D U U D U',
          originalChords: <String>['G', 'C', 'D', 'Em'],
          tutorialUrl: 'https://www.youtube.com/watch?v=uiL9Q2PKi1A',
        ),
        Song(
          id: 'yaaron',
          title: 'Yaaron',
          artist: 'KK',
          difficulty: 'Beginner',
          strummingPattern: 'D D U U D U',
          originalChords: <String>['G', 'Em', 'C', 'D'],
          tutorialUrl: 'https://www.youtube.com/watch?v=j2Oa8G9vLZY',
        ),
        Song(
          id: 'channa_mereya',
          title: 'Channa Mereya',
          artist: 'Arijit Singh',
          difficulty: 'Intermediate',
          strummingPattern: 'D DU UDU',
          originalChords: <String>['C', 'Am', 'F', 'G'],
          tutorialUrl: 'https://www.youtube.com/watch?v=QF9mJf8siXc',
        ),
        Song(
          id: 'tum_hi_ho',
          title: 'Tum Hi Ho',
          artist: 'Arijit Singh',
          difficulty: 'Intermediate',
          strummingPattern: 'D D U U D U',
          originalChords: <String>['Em', 'C', 'D', 'G'],
          tutorialUrl: 'https://www.youtube.com/watch?v=0RszmOFN2U4',
        ),
      ];

  List<Song> filterSongs({
    required String rootChord,
    required int capoFret,
  }) {
    final songs = getSongs();
    return songs.where((song) {
      final playableChords = ChordTransposer.transposeProgression(
        song.originalChords,
        -capoFret,
      );
      return playableChords.contains(rootChord);
    }).toList(growable: false);
  }
}
