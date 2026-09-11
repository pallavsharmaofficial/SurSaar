<p align="center">
  <img src="assets/icons/app_logo.svg" width="72" alt="">
</p>

<h1 align="center">SurSaar — an AI guitar teacher that watches, listens and corrects you</h1>

<p align="center">
  <a href="https://pallavsharmaofficial.github.io/SurSaar/"><b>Website</b></a> ·
  <a href="https://pallavsharmaofficial.github.io/SurSaar/app/"><b>Open the web app</b></a> ·
  <a href="ARCHITECTURE.md">Architecture</a> ·
  <a href="ROADMAP.md">Roadmap</a> ·
  <a href="docs/DEPLOYMENT.md">Deploy</a>
</p>

SurSaar is a Flutter app (web, Android, iOS) whose goal is the fastest,
most independent way to learn an instrument — guitar first. Point your camera
at your hands, let the microphone hear your guitar, and the teacher shows you
which finger goes where, tells you whether the chord you played is right,
checks your strumming against the beat and calls the next chord before it
comes. Everything runs on your device; nothing is uploaded.

## What it does today

- **Learn mode for beginners:** the teacher waits on every chord until you play it, celebrates, and gives hints if you're stuck. Play along mode keeps tempo when you're ready.
- **Tuner, voice coach and "Hear it":** tune each string with an animated needle, hear what a chord should sound like, and get spoken cues so your eyes can stay on the guitar.
- **AI teacher (web):** MediaPipe hand tracking paints each fingertip with its
  string and fret for the target chord and flags posture (straight fingers,
  flat barre). A chroma-based recogniser hears the chord you play and says
  *"that sounds like Em — target is G"*. An onset detector scores every strum
  as hit / early / late / missed against the strumming grid. Count-in
  metronome, live score rings, session summary, streaks and achievements.
- **AI teacher (mobile):** same engine with the microphone; camera preview and
  chord diagrams instead of finger tracking (hand tracking on mobile is on the
  roadmap).
- **Courses or ad hoc:** guided paths (Guitar Foundations, Bollywood Rhythm,
  Technique Builder) with progress, lesson drills for chords / strumming /
  technique, or a two-tap *Quick practice* with any chords, pattern and tempo.
- **Songs:** search by title, artist, chord or tag; chord diagrams for every
  chord (49 stored shapes + derived barres) with a capo slider; strumming grid;
  song structure with chord changes; one tap into the teacher.
- **Song requests → automatic ingestion:** *Request this song* opens a GitHub
  issue; a workflow searches allow-listed chord sites, extracts chords, key,
  capo, strumming and structure, commits them to the catalogue and replies on
  the issue. Lyrics are never stored.
- **Web + mobile from one codebase**, English and Hindi, offline-capable.

## Run it

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n

flutter run -d chrome      # web – camera, hand tracking, mic (localhost is a secure context)
flutter run                # Android / iOS
flutter analyze && flutter test
```

The site is published by GitHub Actions from `main`; see
[docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) for the one-time Pages setup.

## How it is built

| Part | Where | Notes |
|---|---|---|
| App | `lib/` | Flutter + BLoC + go_router, Material 3. Persistence is a JSON document store over `shared_preferences` so the same code runs on web and mobile. |
| Teacher engine | `lib/teacher/` | Pure-Dart FFT → chroma → chord templates, spectral-flux onsets, timing scorer, hand-shape coach, plan/engine/coaching. Unit-tested with synthesised chords. |
| Browser runtime | `web/teacher/sursaar_teacher.js` | getUserMedia, MediaPipe Hand Landmarker (wasm), AudioWorklet capture, metronome click — bound with `dart:js_interop`. |
| Content | `content/sursaar_content.json`, `assets/data/` | Schema v2 (songs with key/capo/sections, lessons with teacher targets, courses, chord voicings). Old content-engine JSON still parses. |
| Ingestion | `tools/ingest/` | Node CLI + `ingest-song.yml`. Opt-in source allow-list, robots.txt honoured, no lyrics. |
| Site | `site/` | Static landing page served at the Pages root; the app lives at `/app/`. |

More: [ARCHITECTURE.md](ARCHITECTURE.md) · [docs/TEACHER_ENGINE.md](docs/TEACHER_ENGINE.md) ·
[docs/CONTENT_SCHEMA.md](docs/CONTENT_SCHEMA.md) · [docs/INGESTION.md](docs/INGESTION.md) ·
[PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md)

## Contributing

1. Fork, branch, `flutter analyze && flutter test`, open a PR (CI builds the web app).
2. To add a song by hand: `node tools/ingest/cli.mjs parse sheet.txt --title "…" --artist "…" > song.json && node tools/ingest/cli.mjs import song.json`.
3. Only add chord-sheet sources whose terms allow it (`tools/ingest/sources.json`).

## Privacy

Camera and microphone are processed locally; sessions and progress are stored
on the device. No accounts, no analytics. See
[site/privacy.html](site/privacy.html).

## Licence

MIT.
