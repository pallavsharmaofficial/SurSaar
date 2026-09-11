import test from 'node:test';
import assert from 'node:assert/strict';
import { htmlToText, parseChordSheet, guessDifficulty } from '../lib/parse.mjs';
import { isChordLine, normalizeChord } from '../lib/chords.mjs';
import { mergeSong, validateBundle } from '../lib/bundle.mjs';
import { songFromParsed } from '../lib/ingest.mjs';

test('normalizes chord spellings', () => {
  assert.equal(normalizeChord('Bb'), 'A#');
  assert.equal(normalizeChord('Amin'), 'Am');
  assert.equal(normalizeChord('Cmaj7'), 'Cmaj7');
  assert.equal(normalizeChord('G/B'), 'G/B');
  assert.equal(normalizeChord('hello'), null);
  assert.equal(normalizeChord('A'), 'A');
});

test('detects chord lines vs lyric lines', () => {
  assert.equal(isChordLine('G    Em    C    D'), true);
  assert.equal(isChordLine('I am a lyric line with An A'), false);
  assert.equal(isChordLine('Am F C G'), true);
});

test('parses chords-above-lyrics sheets without keeping lyrics', () => {
  const sheet = `Kabira Chords - Tochi Raina
Capo on 2nd fret
Strumming Pattern: D DU UDU
Key: D Major

[Intro]
D    G    A    G

[Verse]
D           G
Kaara kaara mausam
A           G
kaisa yeh gaana

[Chorus]
Bm   G    D    A
la la la la
`;
  const parsed = parseChordSheet(sheet);
  assert.deepEqual(parsed.chords, ['D', 'G', 'A', 'Bm']);
  assert.equal(parsed.capo, 2);
  assert.equal(parsed.key, 'D');
  assert.equal(parsed.strumming, 'D DU UDU');
  assert.deepEqual(parsed.sections.map((s) => s.name), ['Intro', 'Verse', 'Chorus']);
  assert.equal(parsed.sections[1].lines.length, 2);
  assert.equal(parsed.sections[1].lines[0].lyric, '');
  assert.deepEqual(parsed.sections[2].lines[0].chords.map((c) => c.chord), ['Bm', 'G', 'D', 'A']);
});

test('parses ChordPro inline chords', () => {
  const parsed = parseChordSheet('[Am]Hello [F]there [C]my [G]friend\n');
  assert.deepEqual(parsed.chords, ['Am', 'F', 'C', 'G']);
  assert.equal(parsed.sections[0].lines[0].chords[1].position > 0, true);
});

test('reduces html to text', () => {
  const text = htmlToText('<pre>G   C<br>lyric</pre><script>x()</script>');
  assert.match(text, /G   C\nlyric/);
  assert.doesNotMatch(text, /x\(\)/);
});

test('builds a valid song and merges into a bundle', () => {
  const parsed = parseChordSheet('[Verse]\nG C D Em\n');
  const song = songFromParsed(parsed, { title: 'Test Song', artist: 'Someone', sourceUrl: 'https://example.com/x' });
  assert.equal(song.id, 'test_song_someone');
  assert.equal(song.difficulty, 'beginner');
  const bundle = { songs: [], lessons: [], courses: [], chords: [] };
  assert.equal(mergeSong(bundle, song), 'added');
  assert.equal(mergeSong(bundle, { ...song, bpm: 90 }), 'updated');
  assert.equal(bundle.songs[0].bpm, 90);
  assert.deepEqual(validateBundle(bundle), []);
});

test('difficulty heuristic', () => {
  assert.equal(guessDifficulty(['G', 'C', 'D']), 'beginner');
  assert.equal(guessDifficulty(['G', 'C', 'D', 'F', 'Am']), 'intermediate');
  assert.equal(guessDifficulty(['F', 'Bm', 'C#m', 'G#m', 'A', 'B', 'E']), 'advanced');
});

test('validate rejects lyrics in the bundle', () => {
  const errors = validateBundle({ songs: [{ id: 'x', title: 't', artist: 'a', difficulty: 'beginner', strummingPattern: 'D', originalChords: ['G'], lyrics: 'nope' }], lessons: [], courses: [] });
  assert.equal(errors.length, 1);
});
