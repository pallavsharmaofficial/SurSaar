import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sursaar/data/content/chord_sheet_parser.dart';
import 'package:sursaar/data/local/app_database.dart';
import 'package:sursaar/data/local/local_store.dart';
import 'package:sursaar/repositories/content_repository.dart';
import 'package:sursaar/repositories/song_repository.dart';

import 'chord_sheet_parser_test.dart' show gluedSheet;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  SongRepository buildRepository() {
    final store = InMemoryLocalStore();
    return SongRepository(
      database: AppDatabase(store: store),
      content: ContentRepository(
        store: store,
        client: MockClient((_) async => http.Response('offline', 503)),
      ),
    );
  }

  test('an imported song joins the catalogue and is searchable', () async {
    final repository = buildRepository();
    final before = await repository.getSongs();
    expect(before.any((s) => s.addedByUser), isFalse);

    final sheet = ChordSheetParser.parse(gluedSheet);
    final id = ChordSheetParser.idFor(
      'Tere Paas Main',
      'Unknown',
      await repository.knownIds(),
    );
    final saved = await repository.addUserSong(
      sheet.toSong(id: id, title: 'Tere Paas Main', artist: 'Unknown'),
    );
    expect(saved.addedByUser, isTrue);

    final songs = await repository.getSongs();
    expect(songs.length, before.length + 1);
    expect(songs.firstWhere((s) => s.id == id).title, 'Tere Paas Main');

    final found = await repository.searchSongs('tere paas');
    expect(found.map((s) => s.id), contains(id));

    final byChord = await repository.filterSongs(rootChord: 'Am', capoFret: 0);
    expect(byChord.map((s) => s.id), contains(id));

    await repository.deleteUserSong(id);
    expect((await repository.getSongs()).length, before.length);
  });

  test('an import can replace a catalogue song of the same id', () async {
    final repository = buildRepository();
    final kabira = (await repository.getSongs()).firstWhere(
      (song) => song.id == 'kabira',
    );
    await repository.addUserSong(kabira.copyWith(strummingPattern: 'D D D D'));
    final updated = (await repository.getSongs()).firstWhere(
      (song) => song.id == 'kabira',
    );
    expect(updated.strummingPattern, 'D D D D');
    expect(updated.addedByUser, isTrue);
  });
}
