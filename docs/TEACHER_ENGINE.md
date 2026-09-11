# The AI teacher

`lib/teacher/` is the real-time coach. Pure Dart analysis (unit-tested,
platform independent) sits behind thin platform services.

## Coaching modes

| Mode | Pacing | Scoring |
|---|---|---|
| **Learn** (default) | Waits on every chord. It moves on only after the target chord has rung correctly for 400 ms, celebrates, then shows the next chord. Repeated chords need a fresh strum. | Chords played vs. skipped, time to success per chord, combo streaks, stars. |
| **Play along** | Count-in, then chords change on the beat at the song tempo (tempo presets: slow 60 %, medium 80 %, song speed). | Chord accuracy + strum timing against the pattern grid. |

Learn-mode steps come from `PracticePlan.learnSteps`: a song's chord changes
(back-to-back repeats merged), or a drill's chords twice (a single chord three
times). Hints escalate while the learner is stuck: after 7 s the first finger
placement, after 15 s "tap Hear it or Skip". Wrong chords get "that sounds like
Em", and silence gets "strum all the strings".

At the end the learner gets 0–3 stars, their best streak, and the chords worth
practising again. "Practise these" starts a Learn session with just those chords.
Sessions are saved automatically.

## Inputs

| Stream | Web | Android / iOS |
|---|---|---|
| `AudioFrame` (Float32 PCM) | AudioWorklet in `web/teacher/sursaar_teacher.js`, AGC / echo / noise suppression off | `record` 16-bit PCM stream |
| `HandFrame` (≤ 2 hands × 21 landmarks) | MediaPipe Hand Landmarker in a **Web Worker** (`web/teacher/hand_worker.js`), GPU with CPU fallback | not yet |

### Web camera runtime

* Hand tracking is **preloaded when the practice screen opens**. Model
  download, WebGL shader compilation and inference all run in the worker, so
  the page never freezes. If module workers are unavailable it falls back to
  the main thread at 15 fps.
* The page sends `ImageBitmap`s with one frame in flight at a time (≤ 30 fps).
* One persistent `<video>` is adopted by each platform view
  (`createVisionView`). A watchdog resumes playback if the browser pauses the
  element, and a generation counter guarantees a single detection loop.
* Camera and microphone stay on for the whole practice screen. Finishing and
  replaying a session never restarts them. They stop when the learner leaves
  or toggles them off.
* MediaPipe labels handedness for a mirrored selfie image. The worker gets the
  raw frame, so labels are swapped; the preview is mirrored with CSS and the
  overlay flips x.

## Analysis

* **Chords** – Hann → FFT → 12-bin chroma (70–2200 Hz, log compressed,
  low octaves weighted) → cosine against templates for the plan's chords plus
  all 24 triads → 5-frame vote. `TeacherEngine.accepts` counts a detection when
  it is the same chord family (`G/B`, `Gmaj7` ≈ `G`) or the target scores
  ≥ 0.8 and within 0.03 of the best match.
* **Strums** – spectral-flux onsets with an adaptive threshold; clicks from
  the metronome are ignored. Direction comes from the strumming hand's motion.
* **Timing** – onsets matched to the nearest sounding slot of the strumming
  grid (±110 ms hit, ±220 ms early/late, otherwise extra); passed slots are
  misses.
* **Hand shape** – `ChordShapeCoach` maps the target voicing to fingertip
  guides (one colour per finger, shared with every diagram) and posture hints.
* **Pitch** – YIN (`pitch_detector.dart`) for the tuner, median-smoothed per
  string (`tuner.dart`).

## Sounds and voice

`TeacherSoundService`:

* Web: metronome click, **Hear it** plays the chord as a Karplus-Strong
  strum, and the **voice coach** (Web Speech API) says the next chord and hints.
* While a reference chord plays the engine calls `suppressListening`, so the
  app never "hears itself".
* Mobile: platform click only for now.

## Tests

* `test/teacher/` – synthetic chords, strums and tones drive the detectors, the
  learn-mode engine (accept, celebrate, skip, repeat, suppression, hints) and
  the tuner.
* `test/screens/` – every route rendered at phone and tablet sizes.
* An end-to-end check (`tools`-free, run from a scratch folder during
  development) drives the web build in headless Chrome with a fake camera: turn
  on camera and mic, start, finish, play again and play along. It confirms the
  video never pauses and a single tracking loop runs.

## Known limits

* No fretboard registration: the camera guides which finger goes where and
  checks posture, and the microphone decides whether the chord is right.
* Chroma templates can confuse relative chords (C / Am) when the bass is muddy.
* Coach messages and speech are English only.
