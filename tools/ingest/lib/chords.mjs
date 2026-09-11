// Chord-token utilities shared by the parser and the tests.

export const NOTE_NAMES = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
const FLAT_TO_SHARP = { Db: 'C#', Eb: 'D#', Gb: 'F#', Ab: 'G#', Bb: 'A#', Cb: 'B', Fb: 'E' };

// A chord token like G, Am, F#m7, Cadd9, Dsus4, G/B, Bbmaj7, E7sus4, Cdim, Aaug
export const CHORD_TOKEN =
  /^([A-G])([#b]?)((?:maj|min|m|M|dim|aug|sus|add|\+|-)?\d*(?:sus\d|add\d|maj\d|b\d|#\d|dim|aug)*)(?:\/([A-G][#b]?))?$/;

export function normalizeChord(token) {
  const t = token.trim().replace(/♯/g, '#').replace(/♭/g, 'b');
  const m = CHORD_TOKEN.exec(t);
  if (!m) return null;
  let root = m[1] + m[2];
  root = FLAT_TO_SHARP[root] || root;
  let suffix = m[3] || '';
  suffix = suffix
    .replace(/^M(?!aj)/, 'maj')
    .replace(/^min/, 'm')
    .replace(/^-/, 'm');
  if (suffix === 'maj') suffix = '';
  let bass = m[4] ? FLAT_TO_SHARP[m[4]] || m[4] : null;
  return bass ? `${root}${suffix}/${bass}` : `${root}${suffix}`;
}

export function isChordToken(token) {
  return normalizeChord(token) !== null;
}

/**
 * A line is a "chord line" when most of its non-space tokens are chord
 * tokens. Chord sheets place chords above lyrics on their own lines.
 */
export function isChordLine(line) {
  const tokens = line.trim().split(/\s+/).filter(Boolean);
  if (!tokens.length) return false;
  const chordTokens = tokens.filter((t) => isChordToken(t.replace(/[()\[\]|,.]/g, '')));
  return chordTokens.length / tokens.length >= 0.7 && chordTokens.length >= 1;
}

export function chordsInLine(line) {
  return line
    .trim()
    .split(/\s+/)
    .map((t) => normalizeChord(t.replace(/[()\[\]|,.]/g, '')))
    .filter(Boolean);
}
