# The tutor

The tutor sits on top of the AI teacher (`lib/teacher/`). The teacher listens
and watches during one session; the tutor remembers every session, decides
what to play next, walks the learner through a song step by step and explains
what went well and what to fix.

```
 Learn tab ── TutorHub ── "Today's lesson" ──▶ JourneyScreen (/tutor/song/:id)
                │                                 │  steps 1..n
                ├── shelves ──▶ LibraryScreen      ▼
                └── style ───▶ InsightsScreen    TeacherScreen (/tutor/song/:id/step/:i)
                                                  camera · song sheet / tab · coach
                                                  │ finish
                                                  ▼
          TeacherEngine ── SessionReport ──▶ TutorRepository.recordSession
                                              ├─ TutorBrain.feedback  → TutorFeedbackCard
                                              └─ TutorBrain.applyReport → SkillProfile (saved)
```

Everything under `lib/tutor/` is pure Dart and unit-tested.

## Library

`Song.collection` puts each song on one of four shelves: `bollywood`,
`global`, `band` and `instrumental`. The researched shelves live in
`content/catalog/*.json` and are merged into both bundles by

```bash
python3 tools/catalog/build_catalog.py          # write content + asset bundle
python3 tools/catalog/build_catalog.py --check  # validate only
```

The script normalises chord spellings (sharps), drops anything that isn't a
strumming pattern, tags charts that several sources agree on as `verified`,
and adds a confidence note. It stores facts only: chords, sections, key, capo,
tempo and strumming. No lyrics are stored.

Instrumental pieces:

| Status | What ships |
|---|---|
| Public domain (traditional, or composer died more than 60 years ago) | The melody as a single-note tab, converted from sargam (Sa = C4 by default, first position, one finger per fret). Note lengths are approximate. |
| Copyrighted, scale known | A warm-up tab written for SurSaar: the scale up and down, then a pattern in threes, plus the backing chord vamp. **Not** the composition. |
| Copyrighted, nothing published | No tab. The learner pastes one (**⋯ → Paste a single-note tab**), and it stays on the device. |

## Skill profile (`skill_profile.dart`)

Stored under `skill_profile` in local storage.

* **Chords:** mastery 0..1 per chord (65% success rate, 35% speed), as an
  exponential moving average across sessions. Mastery of 0.6 or more counts as
  *known*; 0.82 or more counts as *mastered*.
* **Transitions:** average time from one chord to the next (`G>C`), plus
  failures.
* **Timing:** mean offset from the beat (negative means rushing), spread,
  accuracy, and how often strokes go in the right direction.
* **Style:** how much of the time the fretting hand is visible, playing
  volume, recurring posture hints (decaying), pitch offset and one-fret slips
  for melodies, skips, and uses of "Hear it".
* **Journeys, diary and taste:** frozen journeys per song, the last 40
  verdicts, and which shelves the learner starts songs from.
* **Level:** first day, beginner (fewer than 5 known chords), improver (fewer
  than 10) or confident.

## Recommendations (`TutorBrain.recommend`)

* A started, unfinished journey always comes first.
* **First day:** songs with 3–4 chords score best, and barre chords are
  penalised heavily.
* **Afterwards, i + 1:** one new chord on top of known ones is ideal. Each
  extra new chord costs more, and so does each new barre chord for beginners.
* The song's difficulty is matched to the level, and the learner's favourite
  shelves get a small boost.
* Melodies rank a little lower for new players. The hub still shows the best
  pick from each shelf.
* Songs with nothing to play yet (no chords and no tab) always come last.

Every pick carries its reason ("You know G, D, C – this adds just Am."), which
the hub shows as the tutor's words.

## Journeys (`journey.dart`)

Built once per song from the current profile and then frozen, so step numbers
stay stable.

| Step | Mode | Pass mark | Shown when |
|---|---|---|---|
| Meet the chords | Learn | 70 | The song has chords the learner doesn't know |
| Smooth changes (A→B, A→B…) | Learn | 75 | Up to 3 changes that are new or slower than 2.5 s |
| Groove on two chords | Play along at 60% | 65 | Always |
| Each section, chord by chord (up to 4) | Learn | 80 | The song has sections |
| Play along – slow | Play along at 60% | 70 | Always |
| Perform it | Play along at 85% (beginners) or 100% | 80 | Always |

Melody songs instead get *Meet the notes*, one step per phrase, a backing
groove (open chords only for beginners), then *slow* and *perform*.

After every attempt the step keeps its best score. A pass moves the journey
on. A score 15 or more points under the pass mark on a play-along step lowers
that step's tempo by 10%, down to 50%.

## Session report (`teacher/engine/performance_recorder.dart`)

`TeacherEngine` fills a `PerformanceRecorder` while it runs and publishes a
`SessionReport` on the final snapshot. The report contains:

* chord results (attempts, successes, time to land, skips)
* transitions with the time to the first correct detection after each
  change; failures count as slow
* confusions: per step, the wrong chord heard most often, counted only after
  at least 3 frames, so the previous chord still ringing doesn't count
* timing: hits, early, late, misses (by stroke direction), extras, signed
  offsets and direction checks
* camera: the share of the time the hand was visible, and posture hints from
  `ChordShapeCoach` (generic finger reminders excluded)
* volume, per-section hits, melody pitch offset in cents, wrong-note distance
  in semitones, uses of "Hear it", and hints shown

## Feedback (`TutorBrain.feedback`)

* **Went well:** chords that landed fast every time, quick changes, long
  streaks, on-beat strumming, the right stroke directions, in-tune notes, and
  no skips.
* **To improve (at most 4, each with a drill where it helps):**
  * the slowest or failed changes ("Drill G ↔ C")
  * chord confusions, explained with chord tones and strings: *"I'm not
    hearing the A note and I hear G instead. Make sure your middle finger
    presses the D string at fret 2."*
  * skipped chords
  * rushing or dragging (more than 45 ms), wobbly timing (more than ±75 ms),
    missed up-strokes, mixed-up stroke directions
  * the most frequent posture hint, poor hand visibility, playing too softly
  * notes ringing sharp or flat, and one-fret slips
* **Verdict:** pass → next step; within 15 points of the pass mark → repeat;
  further below → easier (slower or broken down).
* **Style:** long-term notes from the profile, such as "You tend to rush, about
  60 ms ahead across 5 sessions", strongest chords, the slowest change, habits,
  and favourite shelf.

## Melody mode (`teacher/melody/`, `teacher/analysis/note_detector.dart`)

* `TabParser` reads ASCII tab. It handles six-line and partial blocks,
  multi-digit frets and section headers. When several strings sound in one
  column, the highest string is the melody. Rhythm comes from the spacing:
  the most common gap is one beat. `TabParser.format` writes tabs back in the
  same form.
* `PracticePlan.forMelody` turns notes into targets (`n:<string>:<fret>`), so
  learn mode, play-along, the chord ribbon and stats all work unchanged.
  Repeated notes need a fresh pluck.
* `NoteDetector` runs YIN on audio decimated to about 24 kHz with a 3-frame
  median. A note counts after ringing 150 ms within 0.6 semitones of the
  target, on any string.
* Wrong notes get "That's C#4. Move 1 fret lower – B string · 1st fret."
* The camera overlay and diagram show a one-dot shape, using one finger per
  fret from the phrase's lowest fret.

## Tests

* `test/tutor/tutor_brain_test.dart`: chord theory, recommendations,
  journeys, profile updates, feedback rules and verdicts.
* `test/tutor/tutor_flow_test.dart`: a fake microphone strums through a
  journey step on a real `TeacherBloc`, then checks the feedback, that the step
  passed and that G is now known.
* `test/teacher/melody_test.dart` and
  `test/teacher/melody_engine_and_report_test.dart`: the tab parser, note
  detection at 44.1 and 48 kHz, melody learn mode, and session reports.
* `test/data/tutor_catalogue_test.dart`: shelf counts, no lyrics, every chord
  has a shape and a template, tabs parse, every journey step builds, and a
  sensible first pick.
