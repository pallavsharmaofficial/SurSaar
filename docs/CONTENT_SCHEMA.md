# Content schema v2

`content/sursaar_content.json` (published) and `assets/data/local_bundle.json`
(offline copy) share one schema. `ContentNormalizer` also accepts the older
"content engine" layout (`metadata`, `chords`, `strumming`, `base_key`,
`content.steps`, `ai_config`, `exercises`), so existing files keep working.

```jsonc
{
  "version": "2.0.0",
  "schemaVersion": 2,
  "lastUpdated": "2026-09-11",
  "songs":   [ Song ],
  "lessons": [ Lesson ],
  "courses": [ Course ],
  "chords":  [ ChordVoicing ]     // optional extra voicings merged into the library
}
```

## Song

```jsonc
{
  "id": "kabira",                       // stable slug
  "title": "Kabira",
  "artist": "Tochi Raina, Rekha Bhardwaj",
  "album": "Yeh Jawaani Hai Deewani",   // or film
  "difficulty": "beginner",             // beginner | intermediate | advanced
  "key": "D",                           // "G", "Am" …
  "capo": 0,                            // suggested capo fret
  "bpm": 84,
  "duration": 223,                      // seconds
  "strummingPattern": "D DU D DU",      // guitarist notation, see below
  "originalChords": ["D", "G", "A", "Bm"],  // shapes to fret with the capo on `capo` (as chord sheets list them)
  "sections": [
    { "name": "Verse", "repeat": 2, "barsPerChord": 1,
      "lines": [ { "lyric": "", "chords": [ {"chord": "D", "position": 0, "beats": 4}, {"chord": "G"} ] } ] }
  ],
  "tags": ["folk-pop", "wedding"],
  "language": "hi",
  "tutorialUrl": "https://…",
  "sourceUrl": "https://…",             // attribution for imported sheets
  "notes": "Community-sourced progression…",
  "tabs": null                          // optional ASCII tab block
}
```

* `lyric` is empty in everything SurSaar ships. The validator rejects bundles
  that contain lyric text. Chord names, order, key, capo and strumming are facts.
* `position` is the character offset of the change within the lyric (used when
  a user pastes their own sheet); `beats` overrides the even split.
* `originalChords` and section chords are the shapes played with the capo on
  `capo`, exactly as chord sheets list them; `key` is the sounding key
  (shape key + capo). Choosing a different capo in the app re-transposes the
  shapes by `capo - newCapo`.

## Strumming notation

`StrummingPattern.parse` turns any of these into an eighth-note grid:

| Written | Grid (1 & 2 & 3 & 4 &) |
|---|---|
| `D DU UDU` / `D D U U D U` / `D - DU - UDU` | `D - D U - U D U` |
| `D X DU X DU` | `D X D U X - D U` |
| `D - D - UU - D - DU` | two bars |

`D` down, `U` up, `X`/`M` mute, `-` `.` `_` rest. A down that would fall on an
"and" is pushed to the next beat and an up that would fall on a beat to the
next "and".

## Lesson

```jsonc
{
  "id": "basic_chords",
  "title": "Basic Guitar Chords",
  "description": "…",
  "difficulty": "beginner",
  "kind": "chord",                      // chord | strumming | song | exercise | theory
  "category": "Fundamentals",
  "instrument": "guitar",
  "targetChords": ["C", "G", "D", "Em", "Am"],
  "targetStrumming": "D D D D",
  "targetBpm": 70,
  "songId": null,                       // for kind = song
  "videoUrl": null,
  "duration": 25, "topicsCount": 5,     // minutes / steps
  "steps": [ { "title": "…", "description": "…", "durationMinutes": 6 } ],
  "isCompleted": false, "progress": 0.0 // overwritten by local progress
}
```

A lesson is *practicable* (shows the AI Teacher button) when it has target
chords, a target strumming or a song.

## Course

```jsonc
{ "id": "course_guitar_foundations", "title": "Guitar Foundations", "emoji": "🎸",
  "difficulty": "beginner", "description": "…", "instrument": "guitar",
  "lessonIds": ["open_chord_foundation", "basic_chords"], "estimatedMinutes": 96 }
```

## ChordVoicing (`assets/data/chords.json`)

```jsonc
{ "name": "G", "frets": [3, 2, 0, 0, 0, 3], "fingers": [2, 1, 0, 0, 0, 3],
  "baseFret": 1, "barres": [ { "fret": 1, "startString": 0, "endString": 5, "finger": 1 } ],
  "label": "open" }
```

Strings are low E → high e. `frets`: `-1` muted, `0` open. `fingers`: 1 index …
4 pinky, 5 thumb. Chords without a stored voicing are derived from movable
E-shape / A-shape templates (major, minor, 7, m7, maj7, sus2, sus4).
