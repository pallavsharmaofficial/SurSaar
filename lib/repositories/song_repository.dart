import '../core/utils/chord_transposer.dart';
import '../data/local/app_database.dart';
import '../models/song.dart';
import 'content_repository.dart';

class SongRepository {
  const SongRepository({
    required AppDatabase database,
    required ContentRepository content,
  }) : _database = database,
       _content = content;

  final AppDatabase _database;
  final ContentRepository _content;

  Future<List<Song>> getSongs() async {
    final bundle = await _content.ensureLoaded();
    final favorites = await _database.getFavoriteSongIds();
    final songs = bundle.songs
        .map((song) => song.copyWith(isFavorite: favorites.contains(song.id)))
        .toList();
    songs.sort(
      (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
    );
    return songs;
  }

  /// Songs whose shapes include [rootChord] when played with a capo on
  /// [capoFret] (sheet shapes are relative to the song's own capo).
  Future<List<Song>> filterSongs({
    required String rootChord,
    required int capoFret,
  }) async {
    final songs = await getSongs();
    return songs
        .where((song) {
          final playableChords = ChordTransposer.transposeProgression(
            song.originalChords,
            song.capo - capoFret,
          );
          return playableChords.contains(rootChord);
        })
        .toList(growable: false);
  }

  /// Free-text search over title, artist, album, tags and chord names.
  Future<List<Song>> searchSongs(String query) async {
    final songs = await getSongs();
    final terms = query
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList(growable: false);
    if (terms.isEmpty) return songs;

    int score(Song song) {
      final haystack = <String>[
        song.title.toLowerCase(),
        song.artist.toLowerCase(),
        (song.album ?? '').toLowerCase(),
        ...song.tags.map((t) => t.toLowerCase()),
        ...song.uniqueChords.map((c) => c.toLowerCase()),
      ];
      var total = 0;
      for (final term in terms) {
        if (song.title.toLowerCase().startsWith(term)) total += 5;
        if (haystack.any((h) => h == term)) total += 3;
        if (haystack.any((h) => h.contains(term))) total += 1;
      }
      return total;
    }

    final scored = <(Song, int)>[
      for (final song in songs)
        if (score(song) > 0) (song, score(song)),
    ]..sort((a, b) => b.$2.compareTo(a.$2));
    return scored.map((e) => e.$1).toList(growable: false);
  }

  Future<List<Song>> getSongsByDifficulty(SongDifficulty difficulty) async {
    final songs = await getSongs();
    return songs
        .where((song) => song.difficulty == difficulty)
        .toList(growable: false);
  }

  Future<Song?> getSongById(String id) async {
    final songs = await getSongs();
    for (final song in songs) {
      if (song.id == id) return song;
    }
    return null;
  }

  Future<void> toggleFavorite(String songId, bool isFavorite) async {
    await _database.setFavorite(songId, isFavorite);
  }
}
