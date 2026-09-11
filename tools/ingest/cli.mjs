#!/usr/bin/env node
// SurSaar content ingestion CLI.
//
//   node cli.mjs ingest "Kabira" --artist "Tochi Raina" --out ../../content/sursaar_content.json
//   node cli.mjs ingest "Kabira" --url https://allowed-site/kabira-chords --out ...
//   node cli.mjs parse sheet.txt              # parse a local text/ChordPro file, print JSON
//   node cli.mjs validate ../../content/sursaar_content.json
//   node cli.mjs resolve-request              # GitHub Action helper (reads ISSUE_* env)

import { readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { htmlToText, parseChordSheet } from './lib/parse.mjs';
import { ingestIntoBundle, songFromParsed } from './lib/ingest.mjs';
import { mergeSong, readBundle, validateBundle, writeBundle } from './lib/bundle.mjs';

const here = path.dirname(fileURLToPath(import.meta.url));
const DEFAULT_OUT = path.join(here, '..', '..', 'content', 'sursaar_content.json');

function args(argv) {
  const positional = [];
  const flags = {};
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a.startsWith('--')) {
      const key = a.slice(2);
      const next = argv[i + 1];
      if (next === undefined || next.startsWith('--')) flags[key] = true;
      else { flags[key] = next; i++; }
    } else positional.push(a);
  }
  return { positional, flags };
}

async function main() {
  const { positional, flags } = args(process.argv.slice(2));
  const command = positional[0];

  if (command === 'validate') {
    const file = positional[1] || DEFAULT_OUT;
    const errors = validateBundle(await readBundle(file));
    if (errors.length) {
      console.error(errors.join('\n'));
      process.exit(1);
    }
    console.log(`✔ ${file} is valid`);
    return;
  }

  if (command === 'parse') {
    const text = await readFile(positional[1], 'utf8');
    const parsed = parseChordSheet(/<[a-z][\s\S]*>/i.test(text) ? htmlToText(text) : text, {
      includeLyrics: !!flags['include-lyrics'],
    });
    if (flags.title) {
      console.log(JSON.stringify(songFromParsed(parsed, { title: flags.title, artist: flags.artist, sourceUrl: flags.url }), null, 2));
    } else {
      console.log(JSON.stringify(parsed, null, 2));
    }
    return;
  }

  if (command === 'import') {
    // import a parsed/handwritten song JSON file into the bundle
    const song = JSON.parse(await readFile(positional[1], 'utf8'));
    const file = flags.out || DEFAULT_OUT;
    const bundle = await readBundle(file);
    const action = mergeSong(bundle, song);
    const errors = validateBundle(bundle);
    if (errors.length) { console.error(errors.join('\n')); process.exit(1); }
    await writeBundle(file, bundle);
    console.log(`✔ ${action} ${song.id}`);
    return;
  }

  if (command === 'resolve-request') {
    // Turns a GitHub issue (title/body) or workflow inputs into query/artist/url.
    const inputQuery = process.env.INPUT_QUERY || '';
    const inputUrl = process.env.INPUT_URL || '';
    const title = process.env.ISSUE_TITLE || '';
    const body = process.env.ISSUE_BODY || '';
    const field = (label) => {
      const m = new RegExp(`###\\s*${label}[^\\n]*\\n+([^\\n#]+)`, 'i').exec(body);
      return m ? m[1].trim() : '';
    };
    let query = inputQuery || field('Song title') || title.replace(/^song request:\s*/i, '').trim();
    let artist = field('Artist') || '';
    let url = inputUrl || field('Chord sheet URL') || '';
    if (/^_?no response_?$/i.test(artist)) artist = '';
    if (/^_?no response_?$/i.test(url)) url = '';
    if (!artist && query.includes(' - ')) [query, artist] = query.split(' - ').map((s) => s.trim());
    // Values go to $GITHUB_OUTPUT: strip newlines so they cannot inject
    // extra output keys, and cap the length.
    const clean = (v) => String(v || '').replace(/[\r\n]+/g, ' ').trim().slice(0, 200);
    console.log(`query=${clean(query)}`);
    console.log(`artist=${clean(artist)}`);
    console.log(`url=${clean(url)}`);
    return;
  }

  if (command === 'ingest') {
    const query = positional[1];
    if (!query) throw new Error('usage: ingest "<title>" [--artist name] [--url sheetUrl] [--out bundle.json] [--report file.md]');
    const file = flags.out || DEFAULT_OUT;
    const report = [];
    try {
      const result = await ingestIntoBundle({ file, query, artist: flags.artist, url: flags.url });
      const s = result.song;
      report.push(`### ✅ ${result.action === 'added' ? 'Added' : 'Updated'} **${s.title}** — ${s.artist}`);
      report.push('');
      report.push(`- Chords: ${s.originalChords.join(', ')}`);
      report.push(`- Key: ${s.key || 'unknown'} · Capo: ${s.capo} · Strumming: \`${s.strummingPattern}\`${s.bpm ? ` · ${s.bpm} BPM` : ''}`);
      report.push(`- Sections: ${s.sections.map((x) => `${x.name} (${x.lines.length})`).join(', ') || 'none'}`);
      report.push(`- Source: ${result.source}`);
      if (result.warnings.length) report.push(`- Notes: ${result.warnings.join('; ')}`);
      report.push('');
      report.push('Open it in the app: `#/song/' + s.id + '` (after the next Pages deploy).');
      console.log(report.join('\n'));
    } catch (err) {
      report.push(`### ❌ Could not ingest "${query}"`);
      report.push('');
      report.push(err.message);
      report.push('');
      report.push('A maintainer can add the song by hand with `node tools/ingest/cli.mjs parse sheet.txt --title "…" --artist "…" > song.json && node tools/ingest/cli.mjs import song.json`.');
      console.error(report.join('\n'));
      if (!flags.report) process.exit(1);
    } finally {
      if (flags.report) await writeFile(flags.report, report.join('\n') + '\n', 'utf8');
    }
    return;
  }

  console.error('commands: ingest | parse | import | validate | resolve-request');
  process.exit(1);
}

main().catch((err) => {
  console.error(err.message);
  process.exit(1);
});
