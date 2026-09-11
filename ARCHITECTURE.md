# SurSaar architecture

SurSaar is one Flutter codebase that ships as a **web app** (GitHub Pages), an
**Android app** and an **iOS app**, plus a static **landing site** and a
**content pipeline** that lives in the same repository.

```
┌───────────────────────────── GitHub Pages (pallavsharmaofficial.github.io/SurSaar) ─────────────────────────────┐
│  /            landing site (site/)             /app/  Flutter web build           /content/  sursaar_content.json │
└───────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
                 ▲                                          ▲                                      ▲
   deploy-pages.yml (on push to main)                       │                                      │ ingest-song.yml
                                                            │                                      │ (issue "song-request")
┌──────────────────────────── Flutter app (lib/) ───────────┴──────────────────────────┐   ┌───────┴──────────┐
│ screens/  ── BLoCs ──  repositories/  ── data/local (LocalStore, shared_preferences) │   │ tools/ingest      │
│                              │                                                       │   │ search → fetch → │
│                        ContentRepository  ← asset bundle + remote JSON + cache       │   │ parse → merge     │
│                                                                                      │   └───────────────────┘
│ teacher/  engine (PracticePlan, TeacherEngine)                                       │
│           analysis (FFT, chroma, chord templates, onset, timing, hand coach)         │
│           services (vision / audio / metronome – web, mobile, stub)                  │
│                 │ JS interop (web)                                                   │
│         web/teacher/sursaar_teacher.js  – getUserMedia, MediaPipe HandLandmarker,    │
│                                          AudioWorklet capture, click                 │
└──────────────────────────────────────────────────────────────────────────────────────┘
```

## Layers

| Layer | Folder | Notes |
|---|---|---|
| UI | `lib/screens`, `lib/widgets` | Material 3, responsive shell (rail on wide screens, bottom bar on phones). All screens are URL-addressable (`go_router`, hash strategy) so web deep links work on Pages. |
| State | `lib/blocs` | `flutter_bloc`. One BLoC per screen; `TeacherBloc` wires services to the engine. |
| Domain | `lib/models` | `json_serializable` models: `Song`, `Lesson`, `Course`, `ChordVoicing`, `StrummingPattern`, `SongSection`. |
| Data | `lib/repositories`, `lib/data` | `ContentRepository` (asset → remote → cache merge), `ChordLibrary` (stored voicings + derived barre shapes), `AppDatabase` over a `LocalStore` (JSON docs in `shared_preferences`, so identical on web and mobile). |
| Teacher | `lib/teacher` | Pure-Dart signal processing and the coaching engine; platform services behind conditional imports. |

## Why these choices

* **No sqlite, no `dart:io` in shared code.** The v1 app used `sqflite` and file
  I/O, neither of which compiles for the web. All local state is small, so a
  JSON document store over `shared_preferences` (localStorage on web) is
  simpler and runs everywhere.
* **Content is a static JSON file served from the same Pages site.** No backend,
  no CORS problems (`raw.githubusercontent.com` also sends `*`), works offline
  from the bundled copy, and the ingestion workflow can commit to it.
* **Signal processing in Dart, sensors in JS.** Chord recognition, onset
  detection and timing scoring are plain Dart so they are unit-tested and shared
  with mobile. Only what the browser must own (camera element, MediaPipe wasm,
  AudioWorklet) lives in `sursaar_teacher.js`, behind `dart:js_interop`.
* **Honest AR.** Without fretboard registration a camera cannot know which fret
  a finger is on, so the overlay guides *which finger goes where* and checks
  posture, while the microphone decides whether the chord is right.

## Data flow of one practice session

1. A route (`/practice/song/:id`, `/practice/lesson/:id`, `/practice/adhoc?…`)
   resolves to a `PracticePlan`: a timeline of `ChordTarget`s (beats) plus a
   `StrummingPattern` grid and tempo. Song chords are transposed for the capo.
2. `TeacherBloc` starts `VisionService` and `AudioCaptureService` on the user's
   tap (browsers need a gesture) and forwards `HandFrame`s / `AudioFrame`s to
   `TeacherEngine`.
3. The engine runs a count-in, then a 30 Hz tick: metronome clicks, current
   target, misses. Audio frames feed `ChordDetector` (Hann → FFT → chroma →
   template cosine → vote) and `OnsetDetector` (spectral flux). Onsets are
   judged by `TimingScorer` against the pattern grid; direction comes from the
   strumming hand's vertical motion when tracked.
4. `ChordShapeCoach` turns the fretting hand landmarks + target voicing into
   fingertip guides and posture hints. A cooldown-based coach chooses one
   message: next chord, wrong chord ("sounds like Em"), late/early, silence,
   hand not visible, praise.
5. Every tick emits a `TeacherSnapshot`; the screen paints the camera stage
   (preview + `HandOverlayPainter` + cards) and the panel (ribbon, grid,
   controls). On finish the session is stored and progress/streak/achievements
   update.

## Platforms

| Capability | Web | Android / iOS | Desktop |
|---|---|---|---|
| Camera preview | ✔ getUserMedia | ✔ `camera` plugin | ✖ |
| Hand landmarks | ✔ MediaPipe (wasm) | roadmap | ✖ |
| Microphone chord/timing coaching | ✔ AudioWorklet | ✔ `record` PCM stream | ✔ |
| Metronome click | ✔ WebAudio | system click | ✖ |
| Persistence | localStorage | app storage | app storage |

## Repository map

```
lib/                 Flutter app (see PROJECT_STRUCTURE.md)
web/                 web shell + teacher/sursaar_teacher.js
site/                landing site (copied to Pages root)
content/             sursaar_content.json – the published catalogue
assets/data/         local_bundle.json (offline copy) + chords.json (voicings)
tools/ingest/        Node CLI: search/parse/merge chord sheets
.github/workflows/   ci.yml, deploy-pages.yml, ingest-song.yml
docs/                CONTENT_SCHEMA, TEACHER_ENGINE, DEPLOYMENT, INGESTION
```
