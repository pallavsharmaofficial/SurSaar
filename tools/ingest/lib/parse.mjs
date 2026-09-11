// Generic chord-sheet parser. Works on plain text (ChordPro-ish or
// "chords above lyrics"), and on HTML by first reducing it to text.
//
// It deliberately extracts only facts that are not copyrightable: chord
// names and order, section names, key, capo and the strumming pattern.
// Lyrics are dropped unless `includeLyrics` is explicitly set.

import { chordsInLine, isChordLine, normalizeChord } from './chords.mjs';

const SECTION_RE = /^\s*[\[(]?\s*(intro|verse|chorus|pre-?chorus|bridge|outro|interlude|hook|solo|antara|mukhda|sthayi|refrain|instrumental|ending|coda)\s*\d*\s*[\])]?\s*:?\s*$/i;
const CAPO_RE = /capo\s*(?:on|at|:)?\s*(?:fret\s*)?(\d{1,2})/i;
const KEY_RE = /(?:^|\b)(?:key|scale)\s*(?:of|:)?\s*([A-G][#b]?)\s*(m\b|minor|major|maj)?/i;
const STRUM_RE = /strum(?:ming)?(?:\s*pattern)?\s*[:\-–]?\s*([DdUuXx\-.\s_]{4,40})/i;
const BPM_RE = /(\d{2,3})\s*bpm/i;

export function htmlToText(html) {
  return html
    .replace(/<script[\s\S]*?<\/script>/gi, ' ')
    .replace(/<style[\s\S]*?<\/style>/gi, ' ')
    .replace(/<br\s*\/?>/gi, '\n')
    .replace(/<\/(p|div|li|h\d|tr|pre)>/gi, '\n')
    .replace(/<[^>]+>/g, '')
    .replace(/&nbsp;/g, ' ')
    .replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&#39;|&apos;/g, "'")
    .replace(/&quot;/g, '"')
    .replace(/\r/g, '');
}

/** Extracts `[G]lyric [C]lyric` ChordPro lines into chords + lyric. */
function parseChordPro(line) {
  const chords = [];
  let lyric = '';
  const re = /\[([^\]]+)\]/g;
  let last = 0;
  let m;
  while ((m = re.exec(line))) {
    lyric += line.slice(last, m.index);
    const chord = normalizeChord(m[1]);
    if (chord) chords.push({ chord, position: lyric.length });
    last = re.lastIndex;
  }
  lyric += line.slice(last);
  return { chords, lyric };
}

export function parseChordSheet(text, { includeLyrics = false } = {}) {
  const lines = text.split('\n');
  const sections = [];
  let current = null;
  let pendingChordLine = null;
  const allChords = [];
  let key = null;
  let capo = 0;
  let strumming = null;
  let bpm = null;

  const ensureSection = (name) => {
    if (!current || (name && current.name !== name)) {
      current = { name: name || (sections.length ? `Part ${sections.length + 1}` : 'Progression'), lines: [] };
      sections.push(current);
    }
    return current;
  };

  const pushLine = (chords, lyric) => {
    if (!chords.length) return;
    const section = ensureSection();
    section.lines.push({
      lyric: includeLyrics ? lyric.trim() : '',
      chords: chords.map((c) => (typeof c === 'string' ? { chord: c, position: 0 } : c)),
    });
    for (const c of chords) allChords.push(typeof c === 'string' ? c : c.chord);
  };

  for (const raw of lines) {
    const line = raw.replace(/\t/g, '    ');
    const trimmed = line.trim();
    if (!trimmed) {
      if (pendingChordLine) {
        pushLine(pendingChordLine, '');
        pendingChordLine = null;
      }
      continue;
    }
    const capoMatch = CAPO_RE.exec(trimmed);
    if (capoMatch && !capo) capo = parseInt(capoMatch[1], 10);
    const keyMatch = KEY_RE.exec(trimmed);
    if (keyMatch && !key && !isChordLine(trimmed)) {
      const minor = keyMatch[2] && /^m/i.test(keyMatch[2]) && !/^maj/i.test(keyMatch[2]);
      key = normalizeChord(keyMatch[1] + (minor ? 'm' : '')) || null;
    }
    const strumMatch = STRUM_RE.exec(trimmed);
    if (strumMatch && !strumming) {
      const pattern = strumMatch[1].trim().toUpperCase().replace(/\s+/g, ' ');
      if (/[DU]/.test(pattern)) strumming = pattern;
    }
    const bpmMatch = BPM_RE.exec(trimmed);
    if (bpmMatch && !bpm) bpm = parseInt(bpmMatch[1], 10);

    const sectionMatch = SECTION_RE.exec(trimmed);
    if (sectionMatch) {
      if (pendingChordLine) {
        pushLine(pendingChordLine, '');
        pendingChordLine = null;
      }
      const name = sectionMatch[1][0].toUpperCase() + sectionMatch[1].slice(1).toLowerCase();
      ensureSection(name);
      continue;
    }

    if (/\[[A-G][^\]]*\]/.test(trimmed)) {
      const { chords, lyric } = parseChordPro(trimmed);
      if (chords.length) {
        pushLine(chords, lyric);
        continue;
      }
    }

    if (isChordLine(trimmed)) {
      if (pendingChordLine) pushLine(pendingChordLine, '');
      pendingChordLine = chordsInLine(trimmed);
      continue;
    }

    // lyric line following a chord line
    if (pendingChordLine) {
      pushLine(pendingChordLine, trimmed);
      pendingChordLine = null;
    }
  }
  if (pendingChordLine) pushLine(pendingChordLine, '');

  const unique = [];
  for (const c of allChords) if (!unique.includes(c)) unique.push(c);

  return {
    chords: unique,
    key,
    capo,
    strumming,
    bpm,
    sections: sections.filter((s) => s.lines.length),
  };
}

export function guessDifficulty(chords) {
  const barre = chords.filter((c) => /^(F|B|Bm|Fm|F#|F#m|C#m|G#m|A#|A#m|D#|D#m|Cm|Gm)(?!\w)/.test(c)).length;
  if (chords.length <= 4 && barre === 0) return 'beginner';
  if (chords.length <= 6 && barre <= 1) return 'intermediate';
  return 'advanced';
}
