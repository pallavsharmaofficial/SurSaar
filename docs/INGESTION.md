# Song ingestion

"I type a song name, the system finds the chords, strumming and structure and
turns them into a lesson." That is `tools/ingest` plus
`.github/workflows/ingest-song.yml`.

## In the app

Three ways a learner gets a song that is missing:

1. **Find chords online** – opens a web search for "<song> guitar chords".
   Copy the sheet you like.
2. **Paste a chord sheet** – "Add a song" parses what you paste, previews the
   chords and sections it found, and saves the song to your device. Lyrics
   stay local; the shared catalogue never stores them.
3. **Request this song** – files a GitHub issue that the ingestion workflow
   below picks up, so the song reaches everyone.

"Check for new songs" in search re-fetches the published catalogue, so songs
added by the workflow appear without reinstalling.

## Flow

```
app: Search → "Request this song"  ─▶  GitHub issue (label song-request, template)
                                         │
                                         ▼  ingest-song.yml
             resolve-request ─▶ search allow-listed sources ─▶ fetch (robots.txt honoured)
             ─▶ parse (chords / key / capo / strumming / sections) ─▶ merge into
             content/sursaar_content.json ─▶ commit to main ─▶ comment on the issue
                                         │
                                         ▼  deploy-pages.yml
                               new catalogue live at /content/ – the app picks it up
```

Manual use:

```bash
cd tools/ingest
node cli.mjs ingest "Kabira" --artist "Tochi Raina"                  # search + parse + merge
node cli.mjs ingest "Kabira" --url https://allowed-site/kabira-chords
node cli.mjs parse sheet.txt --title "Kabira" --artist "…" > song.json # local text / ChordPro / HTML
node cli.mjs import song.json                                        # merge a hand-made song
node cli.mjs validate ../../content/sursaar_content.json
npm test
```

## Sources are opt-in

`tools/ingest/sources.json` is an **empty allow-list by default**. The tool will
not fetch from a host that is not listed, it checks `robots.txt`, and it
identifies itself as `SurSaarIngest/1.0`. Before adding a site, read its terms
of service. Many chord sites forbid scraping; some publish APIs or permit
personal use only. Add only what you are allowed to use, and keep the
`attribution` text so the song's `notes` credit the source.

Set the repository variable `SURSAAR_SEARCH_PROVIDER=ddg` to discover pages via
DuckDuckGo instead of each source's own search page (results are still
filtered to the allow-list).

## What is stored

Chord names and order, section names, key, capo, strumming, BPM, the source
URL and a note. **Lyrics are never stored**; the bundle validator fails if any
lyric text is present. Chord progressions are facts; lyrics are copyrighted.

## Parser

`lib/parse.mjs` handles "chords above lyrics" sheets, ChordPro `[G]lyric`
lines and HTML (reduced to text). It recognises section headers (Intro, Verse,
Chorus, Bridge, Antara, Mukhda…), `Capo on 2nd fret`, `Key: D Major`,
`Strumming: D DU UDU`, `84 BPM`, and normalises chord spellings (`Bb → A#`,
`Amin → Am`). Difficulty is estimated from the number of chords and barres.
