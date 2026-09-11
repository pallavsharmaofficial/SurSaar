# Roadmap

The goal: the fastest, most independent way to learn guitar — a teacher that
watches, listens and corrects in real time, on the web and on phones.

## Done (v1.1 – this release)

- Web build + GitHub Pages site with the app at `/app/` and content at `/content/`.
- Web-compatible persistence (no sqlite / dart:io in shared code).
- Content schema v2: key, capo, structured sections, tags, provenance; courses;
  chord voicing library with derived barre shapes; legacy JSON still parses.
- AI teacher v1: count-in metronome, chroma-based chord recognition with
  "sounds like X" feedback, onset + timing scoring against the strumming grid,
  MediaPipe hand tracking with per-finger AR guides and posture hints (web),
  audio-only coaching on mobile, session scoring, streaks, achievements.
- Courses or ad-hoc practice; song search; song requests via GitHub issues;
  ingestion CLI + workflow that extracts chords / key / capo / strumming /
  structure from allow-listed sources (never lyrics).

## Done (v1.2 – beginner experience)

- **Learn mode** that waits on every chord, with celebrations, streaks, escalating hints, skip, stars and "practise the tricky chords".
- Guided setup on the practice screen: turn on camera & mic, live checks for "I can see your hand" and "I can hear your guitar".
- Animated chord diagrams with one colour per finger (also on the camera overlay), tap-any-chord sheet with **Hear it**, voice coach.
- Guitar **tuner** (YIN pitch detection, animated needle, per-string check marks).
- First-run onboarding, a "Start here" card (first chord in Learn mode), page transitions.
- Camera fixes: hand tracking in a Web Worker and preloaded, persistent preview (no freeze after the first session), single detection loop, idempotent microphone start.

## Next

1. **Fretboard registration.** Detect strings and frets in the frame (edge /
   line detection on the neck, or a fiducial sticker) so a fingertip can be
   mapped to a string/fret and the coach can say "your ring finger is one fret
   too high".
2. **Hand tracking on Android / iOS.** Run the same MediaPipe hand landmarker
   natively (`camera` image stream → TFLite/MediaPipe task) and feed `HandFrame`s
   to the existing engine.
3. **Better rhythm.** Sampled click, accent patterns, backing loop at song
   tempo, swing feel; per-slot up/down direction from audio (spectral
   centroid) when the hand is not visible.
4. **Content depth.** Lyrics-with-chords display from licensed / user-pasted
   sheets (never bundled), ChordPro import in-app, tabs & single-note melodies
   with pitch tracking.
5. **Adaptive lessons.** Drills generated from the learner's weak transitions
   and timing errors; spaced repetition of chord changes.
6. **Accounts & sync.** Optional Supabase/Firebase sync of progress, sharing
   sessions, leaderboards.
7. **More instruments.** Piano (note detection), vocals (pitch), drums (onset
   classification) reuse the same engine shape.

## Ideas parked

- Multi-camera (top-down + front) for better fretting-hand visibility.
- Teacher voice (TTS) so you don't have to read while playing.
- Offline PWA install prompt on the web.
