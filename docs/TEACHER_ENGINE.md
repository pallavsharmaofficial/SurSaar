# The AI teacher

`lib/teacher/` is the real-time coach. It is deliberately split into pure Dart
analysis (unit-tested, platform independent) and thin platform services.

## Inputs

| Stream | Source | Model |
|---|---|---|
| `AudioFrame` (Float32 PCM, sample rate, capture time) | web: AudioWorklet in `sursaar_teacher.js` (AGC/echo/noise off); mobile: `record` 16-bit stream | `teacher/models/audio_frame.dart` |
| `HandFrame` (≤2 hands × 21 normalised landmarks, handedness, image size) | web: MediaPipe HandLandmarker (VIDEO mode, GPU→CPU fallback); mobile: none yet | `teacher/models/hand_frame.dart` |

MediaPipe reports handedness for a *mirrored* selfie image. The raw camera
stream is not mirrored, so the web service swaps the labels; the preview is
mirrored with CSS and `HandOverlayPainter` flips x accordingly.

## Analysis

* **`FFT`** – radix-2, cached twiddles, Hann window.
* **`ChromaExtractor`** – bins 70–2200 Hz → 12 pitch classes, log compression,
  lower octaves weighted higher, L2-normalised.
* **`ChordTemplates`** – weighted binary templates (root 1.0, third .95,
  fifth .8) for major/minor/7/m7/maj7/sus/dim/aug/add9/6.
* **`ChordDetector`** – ~0.18 s frames every 0.1 s, silence gate at −50 dBFS,
  EMA smoothing of chroma, cosine similarity against the song's chords + all 24
  triads, 5-frame majority vote, margin-based confidence. Reports the best
  chord and the target's own score.
* **`OnsetDetector`** – 1024-point spectral flux (log magnitude, half-wave
  rectified), adaptive threshold = max(1.6 × median, 1.15 × mean) + floor,
  peak picking, 90 ms refractory. Timestamps in the engine clock.
* **`TimingScorer`** – expected slot times from BPM and the pattern grid.
  Each onset matches the nearest sounding slot within ±2 × tolerance
  (110 ms): hit / early / late; otherwise extra. Passed slots without an onset
  become misses. Accuracy = (hits + ½ early/late) / (judged + ½ extras).
* **`HandMotionTracker`** – vertical velocity of the strumming hand's index MCP
  around an onset → down/up.
* **`ChordShapeCoach`** – for the target voicing: which finger goes on which
  string/fret (labels drawn on the fingertips), used vs idle fingers, curl
  heuristics ("curl your ring finger"), barre flatness, hand visibility.

## Engine

`TeacherEngine(plan, chordLibrary, settings, clock)`:

* `start()` → count-in (4 beats, clicks) → running. `tick()` at 30 Hz.
* Chord accuracy counts non-silent detections after a 350 ms grace window at
  each change. A target counts as a *mistake* if fewer than half of its
  detections matched. "Same chord family" is lenient: `G/B`, `Gmaj7` match `G`;
  `Gm` does not.
* Onsets within 70 ms after a metronome click are ignored (the click can leak
  into an open microphone).
* Coaching messages have priorities and a 2.2 s cooldown: next chord (1 beat
  ahead) › fretting hand not visible › silence › wrong chord (with the first
  shape hint) › late / early streaks › stroke direction › praise.
* `overallScore = 60 % chord + 40 % timing` (chord only until the first strum).

`TeacherSnapshot` is what the UI renders; it is emitted on every tick and on
every input that changes state.

## Adding hand tracking on mobile

Implement `VisionService` for the platform (e.g. `camera` image stream →
MediaPipe Tasks / TFLite hand landmarker) and emit `HandFrame`s with
landmarks normalised to the frame. Nothing else changes: the engine, coach and
overlay are shared.

## Known limits (v1)

* No fretboard registration → the coach guides finger *assignment* and posture,
  not exact fret placement. The microphone is the source of truth for whether
  the chord is right.
* Chroma templates cannot distinguish inversions or a chord from its relative
  (e.g. C vs Am when the bass is muddy); the candidate set is limited to the
  song's chords + triads to keep it robust.
* Onset detection on a phone speaker+mic without headphones may pick up the
  click; use headphones or turn the metronome off.
