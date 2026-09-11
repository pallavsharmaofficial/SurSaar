import { guessDifficulty, htmlToText, parseChordSheet } from './parse.mjs';
import { fetchPage, isAllowed, loadSources, searchCandidates } from './search.mjs';
import { mergeSong, readBundle, slugify, writeBundle } from './bundle.mjs';

export function songFromParsed(parsed, { title, artist, sourceUrl, attribution }) {
  const chords = parsed.chords.length ? parsed.chords : [];
  return {
    id: slugify(`${title} ${artist || ''}`),
    title,
    artist: artist || 'Unknown',
    difficulty: guessDifficulty(chords),
    key: parsed.key || null,
    capo: parsed.capo || 0,
    bpm: parsed.bpm || null,
    strummingPattern: parsed.strumming || 'D DU UDU',
    originalChords: chords,
    tutorialUrl: `https://www.youtube.com/results?search_query=${encodeURIComponent(`${title} ${artist || ''} guitar chords tutorial`)}`,
    sections: parsed.sections.map((s) => ({ name: s.name, repeat: 1, lines: s.lines })),
    tags: ['requested'],
    sourceUrl: sourceUrl || null,
    notes: [
      'Imported automatically from a community chord sheet; verify against the tutorial.',
      attribution || null,
      parsed.strumming ? null : 'Strumming pattern was not found on the sheet – default used.',
    ].filter(Boolean).join(' '),
  };
}

/**
 * Full pipeline: search (or use the given URL) → fetch → parse → song.
 * Returns { song, source, candidates, warnings } or throws.
 */
export async function ingestSong({ query, artist, url, fetchImpl = fetch, sources, minChords = 2 }) {
  sources ||= await loadSources();
  const warnings = [];
  let title = query;
  if (!artist && query.includes(' - ')) {
    [title, artist] = query.split(' - ').map((s) => s.trim());
  }

  let candidates = [];
  if (url) {
    if (!isAllowed(url, sources)) throw new Error(`${new URL(url).hostname} is not in tools/ingest/sources.json`);
    candidates = [url];
  } else {
    if (!sources.length) {
      throw new Error('No sources configured. Add allow-listed chord sites to tools/ingest/sources.json, or pass --url.');
    }
    candidates = await searchCandidates(`${title} ${artist || ''}`.trim(), { sources, fetchImpl });
    if (!candidates.length) throw new Error(`No chord sheet found for "${query}" on the configured sources.`);
  }

  let best = null;
  for (const candidate of candidates) {
    try {
      const html = await fetchPage(candidate, { fetchImpl });
      const parsed = parseChordSheet(htmlToText(html));
      if (parsed.chords.length >= minChords) {
        const attribution = sources.find((s) => isAllowed(candidate, [s]))?.attribution;
        best = { parsed, source: candidate, attribution };
        break;
      }
      warnings.push(`${candidate}: only ${parsed.chords.length} chords found`);
    } catch (err) {
      warnings.push(`${candidate}: ${err.message}`);
    }
  }
  if (!best) throw new Error(`Could not extract chords. ${warnings.join('; ')}`);

  const song = songFromParsed(best.parsed, { title, artist, sourceUrl: best.source, attribution: best.attribution });
  return { song, source: best.source, candidates, warnings, parsed: best.parsed };
}

export async function ingestIntoBundle({ file, ...rest }) {
  const result = await ingestSong(rest);
  const bundle = await readBundle(file);
  const action = mergeSong(bundle, result.song);
  await writeBundle(file, bundle);
  return { ...result, action };
}
