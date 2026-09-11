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
    final byId = <String, Song>{for (final song in bundle.songs) song.id: song};
    // The learner's own imports win over a catalogue song with the same id.
    for (final song in await userSongs()) {
      byId[song.id] = song;
    }
    final songs = byId.values
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

  /// Songs the learner imported on this device.
  Future<List<Song>> userSongs() async {
    final rows = await _database.getUserSongs();
    final songs = <Song>[];
    for (final row in rows) {
      try {
        songs.add(Song.fromJson(row).copyWith(addedByUser: true));
      } catch (_) {
        // skip anything that no longer parses
      }
    }
    return songs;
  }

  /// Stores [song] on this device; returns it with its final id.
  Future<Song> addUserSong(Song song) async {
    final rows = await _database.getUserSongs();
    rows.removeWhere((row) => row['id'] == song.id);
    final stored = song.copyWith(addedByUser: true);
    rows.add(stored.toJson());
    await _database.saveUserSongs(rows);
    return stored;
  }

  Future<void> deleteUserSong(String id) async {
    final rows = await _database.getUserSongs()
      ..removeWhere((row) => row['id'] == id);
    await _database.saveUserSongs(rows);
    await _database.setFavorite(id, false);
  }

  /// Every song id in use, for generating a unique id for an import.
  Future<Set<String>> knownIds() async =>
      (await getSongs()).map((song) => song.id).toSet();

  /// Fetches the published catalogue again ("check for new songs").
  Future<int> refreshCatalogue() async {
    final bundle = await _content.refresh();
    return bundle.songs.length;
  }
}
