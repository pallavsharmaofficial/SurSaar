import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sursaar/blocs/teacher/teacher_bloc.dart';
import 'package:sursaar/blocs/teacher/teacher_event.dart';
import 'package:sursaar/blocs/teacher/teacher_state.dart';
import 'package:sursaar/data/content/chord_library.dart';
import 'package:sursaar/data/local/app_database.dart';
import 'package:sursaar/data/local/local_store.dart';
import 'package:sursaar/models/coaching_mode.dart';
import 'package:sursaar/models/song.dart';
import 'package:sursaar/models/song_section.dart';
import 'package:sursaar/repositories/content_repository.dart';
import 'package:sursaar/repositories/practice_repository.dart';
import 'package:sursaar/repositories/progress_repository.dart';
import 'package:sursaar/repositories/settings_repository.dart';
import 'package:sursaar/repositories/song_repository.dart';
import 'package:sursaar/teacher/models/audio_frame.dart';
import 'package:sursaar/teacher/models/hand_frame.dart';
import 'package:sursaar/teacher/services/audio_capture_service.dart';
import 'package:sursaar/teacher/services/sound_service.dart';
import 'package:sursaar/teacher/services/vision_service.dart';
import 'package:sursaar/tutor/journey.dart';
import 'package:sursaar/tutor/tutor_brain.dart';
import 'package:sursaar/tutor/tutor_repository.dart';

import '../teacher/audio_fixtures.dart';

/// A microphone the test plays into.
class FakeMic implements AudioCaptureService {
  final StreamController<AudioFrame> _frames =
      StreamController<AudioFrame>.broadcast();
  bool _running = false;

  @override
  bool get isSupported => true;
  @override
  bool get isRunning => _running;
  @override
  String? get lastError => null;
  @override
  Stream<AudioFrame> get frames => _frames.stream;
  @override
  Future<bool> start() async => _running = true;
  @override
  Future<void> stop() async => _running = false;
  @override
  Future<void> dispose() => _frames.close();

  /// Plays a strummed chord, stamped with the engine's wall clock.
  void strumChord(List<int> midi, {int rate = 22050}) {
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final frame in chunks(strum(midi, rate, 1.2), rate, startMs: now)) {
      _frames.add(frame);
    }
  }
}

class NoCamera implements VisionService {
  final ValueNotifier<TrackingStatus> _status = ValueNotifier<TrackingStatus>(
    TrackingStatus.unavailable,
  );

  @override
  bool get supportsPreview => false;
  @override
  bool get supportsHandTracking => false;
  @override
  bool get isRunning => false;
  @override
  String? get lastError => null;
  @override
  ValueListenable<TrackingStatus> get trackingStatus => _status;
  @override
  Stream<HandFrame> get frames => const Stream<HandFrame>.empty();
  @override
  Future<void> warmUp() async {}
  @override
  Future<void> start({bool frontCamera = true, bool mirror = true}) async {}
  @override
  Future<void> stop() async {}
  @override
  Widget buildPreview(BuildContext context) => const SizedBox.shrink();
  @override
  Future<void> dispose() async => _status.dispose();
}

class Silent implements TeacherSoundService {
  @override
  bool get canPlayChords => false;
  @override
  bool get canSpeak => false;
  @override
  void click({bool accent = false}) {}
  @override
  Duration playChord(List<int> midiNotes, {bool down = true}) => Duration.zero;
  @override
  Duration playNote(int midi) => Duration.zero;
  @override
  void speak(String text, {String language = 'en-US', double rate = 1}) {}
  @override
  void stopSpeaking() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'a journey step: play → tutor feedback → step passed → skill learned',
    () async {
      final store = InMemoryLocalStore();
      final database = AppDatabase(store: store);
      final content = ContentRepository(
        store: store,
        client: MockClient((_) async => http.Response('offline', 503)),
      );
      final library = await ChordLibrary.loadFromAsset();
      final songs = SongRepository(database: database, content: content);
      final tutor = TutorRepository(
        database: database,
        songs: songs,
        chordLibrary: library,
      );
      final song = await songs.addUserSong(
        Song(
          id: 'one_chord_wonder',
          title: 'One Chord Wonder',
          artist: 'Test',
          difficulty: SongDifficulty.beginner,
          strummingPattern: 'D D D D',
          originalChords: const <String>['G'],
          bpm: 80,
          collection: SongCollection.global,
          sections: <SongSection>[
            SongSection(
              name: 'Verse',
              lines: <SongLine>[
                SongLine.chords(const <String>['G', 'G']),
              ],
            ),
          ],
        ),
      );

      final journey = await tutor.journeyFor(song);
      expect(journey.stages.first.kind, StageKind.meetChords);
      final plan = JourneyBuilder.planFor(song, journey.stages.first);
      expect(plan.learnSteps, <String>['G', 'G', 'G']);

      final mic = FakeMic();
      final bloc = TeacherBloc(
        chordLibrary: library,
        settingsRepository: SettingsRepository(database: database),
        practiceRepository: PracticeRepository(database: database),
        progressRepository: ProgressRepository(database: database),
        tutorRepository: tutor,
        visionService: NoCamera(),
        audioService: mic,
        soundService: Silent(),
      );
      addTearDown(bloc.close);

      Future<TeacherState> waitFor(bool Function(TeacherState s) done) async =>
          done(bloc.state)
          ? bloc.state
          : bloc.stream.firstWhere(done).timeout(const Duration(seconds: 10));

      bloc.add(
        TeacherInitialized(
          plan,
          mode: CoachingMode.learn,
          journeySongId: song.id,
          stageIndex: 0,
        ),
      );
      await waitFor((s) => s.status == TeacherStatus.ready);
      bloc.add(const TeacherStarted());
      await waitFor((s) => s.micRunning && s.isRunning);

      for (var i = 0; i < 3; i++) {
        mic.strumChord(gMajor);
        // The tutor celebrates each chord before moving on.
        await Future<void>.delayed(const Duration(milliseconds: 1300));
      }

      final done = await waitFor((s) => s.feedback != null);
      final feedback = done.feedback!;
      expect(done.isFinished, isTrue);
      expect(done.snapshot!.successes, 3);
      expect(feedback.verdict, TutorVerdict.advance);
      expect(feedback.nextStageIndex, 1);
      expect(feedback.wentWell, isNotEmpty);

      final profile = await tutor.profile();
      expect(profile.sessions, 1);
      expect(profile.knows('G'), isTrue);
      expect(profile.journeys[song.id]!.stages.first.passed, isTrue);
      expect(profile.journeys[song.id]!.current, 1);
      expect(profile.diary.single.headline, feedback.headline);
      expect(profile.collections['global'], 1);

      // The next recommendation builds on what was just learned.
      final picks = await tutor.recommendations();
      expect(picks.first.song.id, song.id, reason: 'unfinished journey first');
    },
    timeout: const Timeout(Duration(seconds: 40)),
  );
}
