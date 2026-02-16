import '../core/utils/chord_transposer.dart';
import '../data/local/app_database.dart';
import '../models/song.dart';

class SongRepository {
  const SongRepository({
    required AppDatabase database,
  }) : _database = database;

  final AppDatabase _database;

  List<Song> _baseSongs() => const <Song>[
        Song(
          id: 'o_sanam',
          title: 'O Sanam',
          artist: 'Lucky Ali',
          difficulty: SongDifficulty.beginner,
          strummingPattern: 'D D U U D U',
          originalChords: <String>['G', 'C', 'D', 'Em'],
          tutorialUrl: 'https://www.youtube.com/watch?v=uiL9Q2PKi1A',
          bpm: 92,
          duration: 248,
        ),
        Song(
          id: 'yaaron',
          title: 'Yaaron',
          artist: 'KK',
          difficulty: SongDifficulty.beginner,
          strummingPattern: 'D D U U D U',
          originalChords: <String>['G', 'Em', 'C', 'D'],
          tutorialUrl: 'https://www.youtube.com/watch?v=j2Oa8G9vLZY',
          bpm: 88,
          duration: 301,
        ),
        Song(
          id: 'channa_mereya',
          title: 'Channa Mereya',
          artist: 'Arijit Singh',
          difficulty: SongDifficulty.intermediate,
          strummingPattern: 'D DU UDU',
          originalChords: <String>['C', 'Am', 'F', 'G'],
          tutorialUrl: 'https://www.youtube.com/watch?v=QF9mJf8siXc',
          bpm: 75,
          duration: 294,
        ),
        Song(
          id: 'tum_hi_ho',
          title: 'Tum Hi Ho',
          artist: 'Arijit Singh',
          difficulty: SongDifficulty.intermediate,
          strummingPattern: 'D D U U D U',
          originalChords: <String>['Em', 'C', 'D', 'G'],
          tutorialUrl: 'https://www.youtube.com/watch?v=0RszmOFN2U4',
          bpm: 78,
          duration: 262,
        ),
        Song(
          id: 'tere_sang_yaara',
          title: 'Tere Sang Yaara',
          artist: 'Atif Aslam',
          difficulty: SongDifficulty.beginner,
          strummingPattern: 'D DU UDU',
          originalChords: <String>['C', 'G', 'Am', 'F'],
          tutorialUrl: 'https://www.youtube.com/watch?v=example',
          bpm: 82,
          duration: 285,
        ),
        Song(
          id: 'pal',
          title: 'Pal',
          artist: 'KK',
          difficulty: SongDifficulty.beginner,
          strummingPattern: 'D D U U D U',
          originalChords: <String>['G', 'D', 'Em', 'C'],
          tutorialUrl: 'https://www.youtube.com/watch?v=example',
          bpm: 90,
          duration: 315,
        ),
        Song(
          id: 'tera_ban_jaunga',
          title: 'Tera Ban Jaunga',
          artist: 'Akhil Sachdeva',
          difficulty: SongDifficulty.intermediate,
          strummingPattern: 'D DU UDU',
          originalChords: <String>['Em', 'G', 'D', 'C'],
          tutorialUrl: 'https://www.youtube.com/watch?v=example',
          bpm: 80,
          duration: 275,
        ),
        Song(
          id: 'raabta',
          title: 'Raabta',
          artist: 'Arijit Singh',
          difficulty: SongDifficulty.advanced,
          strummingPattern: 'D DUDUDU',
          originalChords: <String>['Am', 'F', 'C', 'G', 'Em'],
          tutorialUrl: 'https://www.youtube.com/watch?v=example',
          bpm: 95,
          duration: 242,
        ),
      ];

  Future<List<Song>> getSongs() async {
    final favorites = await _database.getFavoriteSongIds();
    return _baseSongs()
        .map(
          (song) => song.copyWith(
            isFavorite: favorites.contains(song.id),
          ),
        )
        .toList(growable: false);
  }

  Future<List<Song>> filterSongs({
    required String rootChord,
    required int capoFret,
  }) async {
    final songs = await getSongs();
    return songs.where((song) {
      final playableChords = ChordTransposer.transposeProgression(
        song.originalChords,
        -capoFret,
      );
      return playableChords.contains(rootChord);
    }).toList(growable: false);
  }

  Future<List<Song>> searchSongs(String query) async {
    final songs = await getSongs();
    final lowerQuery = query.toLowerCase();
    return songs
        .where(
          (song) =>
              song.title.toLowerCase().contains(lowerQuery) ||
              song.artist.toLowerCase().contains(lowerQuery),
        )
        .toList(growable: false);
  }

  Future<List<Song>> getSongsByDifficulty(SongDifficulty difficulty) async {
    final songs = await getSongs();
    return songs
        .where((song) => song.difficulty == difficulty)
        .toList(growable: false);
  }

  Future<Song?> getSongById(String id) async {
    final songs = await getSongs();
    try {
      return songs.firstWhere((song) => song.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> toggleFavorite(String songId, bool isFavorite) async {
    await _database.setFavorite(songId, isFavorite);
  }

  /// Update songs from fetched content bundle
  Future<void> updateSongs(List<Song> songs) async {
    // Store songs in memory and optionally in database if needed
    // This method can be extended to persist songs to database if desired
  }
}
