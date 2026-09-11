# Project structure

```
lib/
├── main.dart                         # loads the chord library, injects the store
├── core/
│   ├── app.dart                      # repositories + MaterialApp.router
│   ├── constants/app_constants.dart  # chords, strumming presets, URLs
│   ├── routing/app_router.dart       # go_router – all screens are deep-linkable
│   ├── theme/                        # Material 3 dark theme, Poppins
│   └── utils/chord_transposer.dart
├── data/
│   ├── content/
│   │   ├── content_normalizer.dart   # legacy + v2 JSON → v2 models
│   │   └── chord_library.dart        # voicings + derived barre shapes
│   └── local/
│       ├── local_store.dart          # LocalStore (shared_preferences / in-memory)
│       └── app_database.dart         # JSON document store facade (web-safe)
├── models/                           # Song, Lesson, Course, ChordVoicing, StrummingPattern,
│                                     # SongSection, ContentBundle, UserSettings, …
├── repositories/                     # content, song, lesson, course, progress, practice,
│                                     # achievement, profile, settings
├── blocs/                            # song_finder, lesson, course, progress, profile, teacher
├── teacher/
│   ├── models/                       # AudioFrame, HandFrame, ChordDetection, StrumEvent
│   ├── analysis/                     # fft, chroma, chord_templates, chord_detector,
│   │                                 # onset_detector, timing_scorer, hand_motion_tracker,
│   │                                 # chord_shape_coach
│   ├── engine/                       # practice_plan, teacher_engine
│   └── services/                     # vision / audio_capture / metronome
│                                     # (_web via dart:js_interop, _mobile/_record, _stub)
├── screens/
│   ├── shell/app_shell_screen.dart   # rail (wide) / bottom bar (phone)
│   ├── home/                         # teacher hero, quick practice, chord+capo finder
│   ├── songs/                        # search, detail (diagrams, strumming grid, sections)
│   ├── learn/                        # courses + lesson library
│   ├── courses/                      # course detail
│   ├── lessons/                      # lesson detail (+ practise button)
│   ├── teacher/teacher_screen.dart   # camera stage + AR overlay + panel
│   ├── progress/                     # stats, level, sessions, achievements
│   └── profile/                      # profile, teacher settings, links
├── widgets/
│   ├── teacher/                      # chord_diagram, strumming_timeline, hand_overlay_painter,
│   │                                 # coach_banner, chord_ribbon, accuracy_ring
│   └── …                             # cards, chips, slider, quick_practice_sheet
└── l10n/                             # app_en.arb, app_hi.arb (+ generated)

web/teacher/sursaar_teacher.js        # camera, MediaPipe hands, AudioWorklet, click
site/                                 # landing page (Pages root)
content/sursaar_content.json          # published catalogue
assets/data/{local_bundle,chords}.json
tools/ingest/                         # Node ingestion CLI + tests
.github/workflows/                    # ci, deploy-pages, ingest-song
test/                                 # models, analysis, engine, normaliser, widget
```

Run:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
flutter run -d chrome          # web (camera + hand tracking)
flutter run                    # Android / iOS (audio coaching)
flutter analyze && flutter test
```
