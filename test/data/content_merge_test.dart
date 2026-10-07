import 'package:flutter_test/flutter_test.dart';
import 'package:sursaar/models/content_bundle.dart';
import 'package:sursaar/models/song.dart';

Song song(String id, {SongCollection? collection}) => Song(
  id: id,
  title: id,
  artist: 'A',
  difficulty: SongDifficulty.beginner,
  strummingPattern: 'D D D D',
  originalChords: const <String>['G'],
  collection: collection,
);

ContentBundle bundle(String version, List<Song> songs) =>
    ContentBundle(lessons: const [], songs: songs, version: version);

void main() {
  test('versions compare numerically', () {
    expect(ContentBundle.compareVersions('2.10.0', '2.9'), greaterThan(0));
    expect(ContentBundle.compareVersions('2.0', '2.0.0'), 0);
    expect(ContentBundle.compareVersions('2.0.0', '2.1.0'), lessThan(0));
  });

  test('a newer or equal remote overrides the bundle', () {
    final local = bundle('2.1.0', <Song>[song('a')]);
    final remote = bundle('2.1.0', <Song>[
      song('a', collection: SongCollection.band),
      song('b'),
    ]);
    final merged = local.merge(remote);
    expect(
      merged.songs.firstWhere((s) => s.id == 'a').collection,
      SongCollection.band,
    );
    expect(merged.songs.length, 2);
  });

  test('an older remote only adds songs, it never downgrades the bundle', () {
    final local = bundle('2.1.0', <Song>[
      song('a', collection: SongCollection.bollywood),
    ]);
    final remote = bundle('2.0.0', <Song>[song('a'), song('requested')]);
    final merged = local.merge(remote);
    expect(
      merged.songs.firstWhere((s) => s.id == 'a').collection,
      SongCollection.bollywood,
    );
    expect(
      merged.songs.map((s) => s.id),
      containsAll(<String>['a', 'requested']),
    );
    expect(merged.version, '2.1.0');
  });
}
