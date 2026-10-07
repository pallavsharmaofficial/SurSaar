// Phone screenshots for the Play listing, drawn by the app itself.
//
// Regenerate them with
//
//     flutter test --update-goldens test/screenshots_test.dart
//
// and they land in store/screenshots/ as 1080 x 1920 PNGs. No device or
// emulator is involved: each screen is pumped on a 360 x 640 dp phone at 3x,
// in the dark theme the app forces, with Poppins loaded from
// tools/branding/fonts, a learner with a week of practice behind them, and a
// microphone that plays a synthesised guitar into the real chord and pitch
// detectors.
//
// Without --update-goldens this file still runs, but it does not compare
// pixels. Text rasterises a little differently on every OS and the dates on
// the progress screen move every day, so a byte-exact golden would fail on the
// Linux CI runner that gates the deploy. What it checks instead is what
// actually goes wrong: the screen must build without an exception or an
// overflow, must show its content rather than a spinner, and the PNG already
// in store/screenshots/ must be present and 1080 x 1920.

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sursaar/blocs/teacher/teacher_bloc.dart';
import 'package:sursaar/core/app.dart';
import 'package:sursaar/data/content/chord_library.dart';
import 'package:sursaar/data/local/app_database.dart';
import 'package:sursaar/data/local/local_store.dart';
import 'package:sursaar/models/chord_voicing.dart';
import 'package:sursaar/models/song.dart';
import 'package:sursaar/repositories/content_repository.dart';
import 'package:sursaar/repositories/practice_repository.dart';
import 'package:sursaar/repositories/progress_repository.dart';
import 'package:sursaar/screens/home/home_screen.dart';
import 'package:sursaar/screens/learn/learn_screen.dart';
import 'package:sursaar/screens/library/library_screen.dart';
import 'package:sursaar/screens/progress/progress_screen.dart';
import 'package:sursaar/screens/shell/app_shell_screen.dart';
import 'package:sursaar/screens/teacher/teacher_screen.dart';
import 'package:sursaar/screens/tuner/tuner_screen.dart';
import 'package:sursaar/screens/tutor/journey_screen.dart';
import 'package:sursaar/teacher/models/audio_frame.dart';
import 'package:sursaar/teacher/models/hand_frame.dart';
import 'package:sursaar/teacher/services/audio_capture_service.dart';
import 'package:sursaar/teacher/services/vision_service.dart';
import 'package:sursaar/tutor/journey.dart';
import 'package:sursaar/tutor/skill_profile.dart';
import 'package:sursaar/tutor/tutor_brain.dart';

/// Play wants 1080 x 1920 portrait: a 360 x 640 dp phone at 3x.
const Size _physicalSize = Size(1080, 1920);
const double _pixelRatio = 3.0;

/// The folder the PNGs land in, relative to this file (test/).
const String _outDir = '../store/screenshots';

// ------------------------------------------------------------------- fonts

/// Poppins is not bundled: google_fonts fetches it at runtime, and the test
/// host must not touch the network. Runtime fetching is switched off and the
/// two weights kept in tools/branding/fonts are registered under the family
/// names google_fonts gives its text styles ("Poppins_regular", "Poppins_600"
/// and so on). Weights the folder lacks borrow the nearest one it has (500
/// borrows the lighter).
///
/// google_fonts also lists "Poppins" itself as the fallback behind every
/// style. That slot is where a handset borrows its emoji from the system, so
/// the host's colour emoji font fills it when there is one (macOS has it; the
/// Linux CI runner does not, and its screenshots are never compared).
Future<void> _loadFonts() async {
  GoogleFonts.config.allowRuntimeFetching = false;

  ByteData read(File file) => ByteData.sublistView(file.readAsBytesSync());
  final ByteData regular = read(
    File('tools/branding/fonts/Poppins-Regular.ttf'),
  );
  final ByteData semiBold = read(
    File('tools/branding/fonts/Poppins-SemiBold.ttf'),
  );

  Future<void> register(String family, ByteData font) async {
    final FontLoader loader = FontLoader(family)
      ..addFont(Future<ByteData>.value(font));
    await loader.load();
  }

  for (int weight = 100; weight <= 900; weight += 100) {
    final ByteData font = weight >= 600 ? semiBold : regular;
    final String upright = weight == 400 ? 'regular' : '$weight';
    final String italic = weight == 400 ? 'italic' : '${weight}italic';
    await register('Poppins_$upright', font);
    await register('Poppins_$italic', font);
  }
  final File emoji = File('/System/Library/Fonts/Apple Color Emoji.ttc');
  await register('Poppins', emoji.existsSync() ? read(emoji) : regular);
  // Whatever the theme leaves unstyled falls back to Roboto on Android, and
  // the chord diagrams name it for the finger numbers they paint themselves.
  await register('Roboto', regular);

  // The icon font ships with the Material package; register it so icons are
  // drawn, not boxes.
  final FontLoader icons = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await icons.load();
}

/// google_fonts reports every weight it cannot fetch with a long message, on
/// every theme build. Fetching is off on purpose, so those lines are noise.
DebugPrintCallback _withoutGoogleFontsNoise(DebugPrintCallback print) {
  return (String? message, {int? wrapWidth}) {
    if (message != null &&
        (message.contains('google_fonts') ||
            message.contains(
              'There is likely something wrong with your test',
            ) ||
            message.contains("If troubleshooting doesn't solve the problem"))) {
      return;
    }
    print(message, wrapWidth: wrapWidth);
  };
}

// ---------------------------------------------------------- the microphone

/// A phone with a guitar on the other side of the microphone: whatever is
/// played here reaches the app's real tuner and chord detectors.
class _Microphone implements AudioCaptureService {
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
  Future<void> dispose() async {
    _running = false;
    await _frames.close();
  }

  static const int _rate = 22050;
  static const int _chunk = 2048;

  /// Streams [samples] the way a phone delivers them, a chunk at a time, with
  /// real time passing between chunks because the screens pace themselves on
  /// the wall clock.
  Future<void> play(WidgetTester tester, Float32List samples) async {
    int at = DateTime.now().millisecondsSinceEpoch;
    for (int start = 0; start < samples.length; start += _chunk) {
      final int end = math.min(samples.length, start + _chunk);
      _frames.add(
        AudioFrame(
          samples: Float32List.sublistView(samples, start, end),
          sampleRate: _rate,
          timestampMs: at,
        ),
      );
      at += ((end - start) * 1000 / _rate).round();
      await _realTime(tester, 70);
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  /// A strummed chord: silence, so the strum has an onset, then every note
  /// with a few decaying harmonics.
  static Float32List chord(List<int> midi, {double seconds = 0.8}) {
    final List<double> hz = <double>[
      for (final int m in midi) 440 * math.pow(2, (m - 69) / 12).toDouble(),
    ];
    final int lead = (_rate * 0.3).round();
    final Float32List out = Float32List(lead + (_rate * seconds).round());
    for (int i = lead; i < out.length; i++) {
      final double t = (i - lead) / _rate;
      double s = 0;
      for (final double f in hz) {
        for (int h = 1; h <= 4; h++) {
          s += math.sin(2 * math.pi * f * h * t) / (h * h) * math.exp(-t * 0.8);
        }
      }
      out[i] = (s / (hz.length * 1.5)).clamp(-1.0, 1.0);
    }
    return out;
  }

  /// One plucked string: a fundamental with decaying overtones.
  static Float32List string(double hz, {double seconds = 1.0}) {
    final Float32List out = Float32List((_rate * seconds).round());
    for (int i = 0; i < out.length; i++) {
      final double t = i / _rate;
      double s = 0;
      for (int h = 1; h <= 3; h++) {
        s += math.sin(2 * math.pi * hz * h * t) / (h * h);
      }
      out[i] = (s * 0.5 * math.exp(-t * 0.5)).clamp(-1.0, 1.0);
    }
    return out;
  }
}

/// The notes of [name] as its diagram fingers them in standard tuning.
List<int> _notes(ChordLibrary library, String name) {
  final ChordVoicing voicing = library.voicingFor(name)!;
  return <int>[
    for (int s = 0; s < 6; s++)
      if (voicing.frets[s] >= 0) kStandardTuningMidi[s] + voicing.frets[s],
  ];
}

/// The camera is not part of what the test host can draw, and it must not be
/// faked: the stage shows its own backdrop where the preview would be.
class _NoCamera implements VisionService {
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
  Widget buildPreview(BuildContext context) => const SizedBox.expand();

  @override
  Future<void> dispose() async => _status.dispose();
}

// ------------------------------------------------------------------ seeding

/// What a learner who has practised every day for a week has behind them: the
/// progress screen's numbers, sessions and badges come from the app's own
/// repositories, so they cannot drift from what the app would really write.
Future<void> _practiceWeek(AppDatabase database) async {
  final PracticeRepository practice = PracticeRepository(database: database);
  final ProgressRepository progress = ProgressRepository(database: database);
  final DateTime today = DateTime.now();
  const List<(String, int, double, int, double?)> week =
      <(String, int, double, int, double?)>[
        // song, minutes, accuracy, chords, timing
        ('kabira', 14, 71, 32, null),
        ('brown_eyed_girl', 11, 76, 28, 68),
        ('woh_lamhe', 16, 81, 40, 72),
        ('kabira', 12, 84, 36, 77),
        ('brown_eyed_girl', 18, 88, 44, 81),
        ('woh_lamhe', 15, 91, 38, 84),
        ('kabira', 20, 94, 52, 88),
      ];
  for (int i = 0; i < week.length; i++) {
    final (
      String song,
      int minutes,
      double accuracy,
      int chords,
      double? timing,
    ) = week[i];
    final DateTime at = DateTime(
      today.year,
      today.month,
      today.day,
      19,
      10 + i * 4,
    ).subtract(Duration(days: week.length - 1 - i));
    await practice.saveSession(
      practice.createSession(
        songId: song,
        startTime: at,
        duration: minutes * 60,
        accuracy: accuracy,
        chordsPlayed: chords,
        mistakes: ((100 - accuracy) / 8).round(),
        timingAccuracy: timing,
        mode: timing == null ? 'song-learn' : 'song-playAlong',
      ),
    );
    await progress.recordPracticeSession(
      durationInSeconds: minutes * 60,
      accuracy: accuracy,
      now: at,
    );
  }
  for (int lesson = 0; lesson < 3; lesson++) {
    await progress.incrementLessonsCompleted();
  }
}

/// What the tutor has noticed over that week: nine chords known, and three
/// songs under way. Everything on the learn screen is derived from this by the
/// tutor's own rules.
SkillProfile _tutorMemory(ChordLibrary library, List<Song> catalogue) {
  final int hourAgo = DateTime.now().millisecondsSinceEpoch - 3600 * 1000;
  ChordSkill skill(String name, double mastery, int ms, int sessions) =>
      ChordSkill(
        name,
        attempts: sessions * 4,
        successes: (sessions * 4 * mastery).round(),
        mastery: mastery,
        averageMs: ms,
        sessions: sessions,
        lastPracticedMs: hourAgo,
      );
  final SkillProfile profile = SkillProfile(
    chords: <String, ChordSkill>{
      for (final ChordSkill c in <ChordSkill>[
        skill('G', 0.93, 1300, 7),
        skill('C', 0.9, 1400, 7),
        skill('D', 0.9, 1500, 7),
        skill('Em', 0.88, 1400, 6),
        skill('Am', 0.82, 1800, 5),
        skill('A', 0.8, 1900, 5),
        skill('Bm', 0.68, 2600, 4),
        skill('F', 0.64, 2900, 4),
        skill('Dm', 0.62, 2800, 3),
      ])
        c.name: c,
    },
    transitions: <String, TransitionSkill>{
      for (final TransitionSkill t in <TransitionSkill>[
        TransitionSkill('G', 'C', averageMs: 1500, count: 14),
        TransitionSkill('C', 'G', averageMs: 1600, count: 12),
        TransitionSkill('D', 'G', averageMs: 1700, count: 11),
        TransitionSkill('Em', 'D', averageMs: 1800, count: 9),
        TransitionSkill('A', 'Bm', averageMs: 3300, count: 6, fails: 2),
      ])
        t.key: t,
    },
    timing: TimingSkill(
      offsetMs: -35,
      spreadMs: 70,
      accuracy: 0.82,
      direction: 0.85,
      samples: 12,
      directionSamples: 8,
    ),
    sessions: 7,
    totalMs: 106 * 60 * 1000,
    lastSessionMs: hourAgo,
  );

  final TutorBrain brain = TutorBrain(voicingFor: library.voicingFor);
  void journey(String id, int passed, List<double> scores) {
    final Song song = catalogue.firstWhere((Song s) => s.id == id);
    final SongJourney path = JourneyBuilder.build(
      song,
      profile,
      isBarre: brain.isBarre,
    );
    for (int i = 0; i < passed; i++) {
      path.stages[i]
        ..status = StageStatus.passed
        ..bestScore = scores[i]
        ..attempts = 1 + i % 2;
    }
    path
      ..current = passed
      ..lastPlayedMs = hourAgo;
    profile.journeys[id] = path;
    final String? shelf = song.collection?.name;
    if (shelf != null) {
      profile.collections[shelf] = (profile.collections[shelf] ?? 0) + 1;
    }
  }

  journey('kabira', 3, <double>[84, 88, 91]);
  journey('brown_eyed_girl', 2, <double>[79, 86]);
  journey('woh_lamhe', 1, <double>[82]);
  return profile;
}

// ------------------------------------------------------------------- driving

/// Pumps fixed durations instead of settling: a practice session and the tuner
/// animate for ever, so pumpAndSettle would never return on them.
Future<void> _pump(WidgetTester tester, int millis) async {
  for (int elapsed = 0; elapsed < millis; elapsed += 50) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Waits for deferred work to replace every spinner with real content, then
/// lets the entrance animations finish.
Future<void> _untilLoaded(WidgetTester tester) async {
  for (int i = 0; i < 200; i++) {
    if (find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
    await tester.pump(const Duration(milliseconds: 50));
  }
  await _pump(tester, 1500);
}

/// Lets real time pass, which the fake-async test zone otherwise never does.
Future<void> _realTime(WidgetTester tester, int millis) async {
  await tester.runAsync(
    () => Future<void>.delayed(Duration(milliseconds: millis)),
  );
}

/// The catalogue as the app ships it (the same file the app loads at launch).
List<Song> _catalogue() => ContentRepository.parseBundle(
  File('assets/data/local_bundle.json').readAsStringSync(),
).songs;

/// The app's routes for the screens being shot, in the shell the app uses.
/// The tuner and the practice screen are given the test microphone and no
/// camera; everything else is the app's own screen.
GoRouter _router(_Microphone microphone) {
  Page<void> tab(Widget child) => NoTransitionPage<void>(child: child);
  return GoRouter(
    initialLocation: '/home',
    routes: <RouteBase>[
      ShellRoute(
        builder: (context, state, child) => AppShellScreen(child: child),
        routes: <RouteBase>[
          GoRoute(
            path: '/home',
            pageBuilder: (c, s) => tab(const HomeScreen()),
          ),
          GoRoute(
            path: '/learn',
            pageBuilder: (c, s) => tab(const LearnScreen()),
          ),
          GoRoute(
            path: '/progress',
            pageBuilder: (c, s) => tab(const ProgressScreen()),
          ),
        ],
      ),
      GoRoute(
        path: '/library',
        builder: (context, state) => const LibraryScreen(),
      ),
      GoRoute(
        path: '/tuner',
        builder: (context, state) => TunerScreen(audioService: microphone),
      ),
      GoRoute(
        path: '/tutor/song/:id',
        builder: (context, state) =>
            JourneyScreen(songId: state.pathParameters['id']!),
        routes: <RouteBase>[
          GoRoute(
            path: 'step/:index',
            builder: (context, state) => TeacherScreen(
              request: TeacherRequest.stage(
                state.pathParameters['id']!,
                int.parse(state.pathParameters['index']!),
              ),
              audioService: microphone,
              visionService: _NoCamera(),
            ),
          ),
        ],
      ),
    ],
  );
}

class _Phone {
  _Phone(this.router, this.microphone, this.chords);

  final GoRouter router;
  final _Microphone microphone;
  final ChordLibrary chords;
}

/// Pumps the whole app, in the dark theme it forces, on the Play phone, at
/// the Home tab.
Future<_Phone> _open(WidgetTester tester) async {
  tester.view.physicalSize = _physicalSize;
  tester.view.devicePixelRatio = _pixelRatio;
  addTearDown(tester.view.reset);
  // Asset futures cached by a previous test belong to its fake-async zone.
  rootBundle.clear();

  final ChordLibrary library = await ChordLibrary.loadFromAsset();
  final InMemoryLocalStore store = InMemoryLocalStore();
  final AppDatabase database = AppDatabase(store: store);
  await store.setString('settings', '{"onboarding_seen": true}');
  await _practiceWeek(database);
  await database.saveSkillProfile(_tutorMemory(library, _catalogue()).toJson());

  final _Microphone microphone = _Microphone();
  final GoRouter router = _router(microphone);
  await tester.pumpWidget(
    App(
      store: store,
      chordLibrary: library,
      // The catalogue is bundled; the fetch from GitHub is answered "offline"
      // so nothing leaves the test host.
      httpClient: MockClient((_) async => http.Response('offline', 503)),
      router: router,
    ),
  );
  await _untilLoaded(tester);
  return _Phone(router, microphone, library);
}

/// Plays the chord the teacher is waiting for, as if strummed.
Future<void> _strum(
  WidgetTester tester,
  _Phone phone, {
  double seconds = 0.8,
}) async {
  final TeacherBloc teacher = tester
      .element(find.byType(CustomScrollView))
      .read<TeacherBloc>();
  final String chord = teacher.state.snapshot!.currentChord!;
  await phone.microphone.play(
    tester,
    _Microphone.chord(_notes(phone.chords, chord), seconds: seconds),
  );
}

/// Closes the app and lets the microphone and the teacher's clock shut down,
/// which they do in real time after the widget tree is gone.
Future<void> _leave(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await _realTime(tester, 200);
  await tester.pump(const Duration(seconds: 1));
}

/// Scrolls the screen's main list to [offset] dp, as a thumb would.
Future<void> _scrollTo(WidgetTester tester, double offset) async {
  final ScrollableState list = tester.state(find.byType(Scrollable).first);
  list.position.jumpTo(offset);
  await _pump(tester, 600);
}

/// Checks the screen is real content, then writes (or checks) the PNG.
Future<void> _capture(WidgetTester tester, String name) async {
  expect(tester.takeException(), isNull, reason: '$name threw or overflowed');
  expect(
    find.byType(CircularProgressIndicator),
    findsNothing,
    reason: '$name is still showing a spinner',
  );
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('$_outDir/$name.png'),
  );
}

/// Re-encodes [png] as 8-bit RGB. The engine only writes RGBA, and Play wants
/// 24-bit PNGs with no alpha channel, as the other files in store/play are.
/// Every pixel of a screen is opaque, so nothing is lost.
Future<Uint8List> _withoutAlpha(Uint8List png) async {
  final ui.Codec codec = await ui.instantiateImageCodec(png);
  final ui.Image image = (await codec.getNextFrame()).image;
  final int width = image.width;
  final int height = image.height;
  final ByteData rgba = (await image.toByteData())!;
  image.dispose();
  codec.dispose();

  // Every scanline is a filter byte (0, none) and then its RGB triples.
  final Uint8List raw = Uint8List(height * (1 + width * 3));
  int out = 0;
  for (int y = 0; y < height; y++) {
    raw[out++] = 0;
    for (int x = 0; x < width; x++) {
      final int at = (y * width + x) * 4;
      raw[out++] = rgba.getUint8(at);
      raw[out++] = rgba.getUint8(at + 1);
      raw[out++] = rgba.getUint8(at + 2);
    }
  }

  final BytesBuilder file = BytesBuilder()
    ..add(const <int>[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
  void chunk(String type, List<int> data) {
    final Uint8List body = Uint8List.fromList(<int>[
      ...type.codeUnits,
      ...data,
    ]);
    file
      ..add((ByteData(4)..setUint32(0, data.length)).buffer.asUint8List())
      ..add(body)
      ..add((ByteData(4)..setUint32(0, _crc32(body))).buffer.asUint8List());
  }

  chunk(
    'IHDR',
    (ByteData(13)
          ..setUint32(0, width)
          ..setUint32(4, height)
          ..setUint8(8, 8) // bits per channel
          ..setUint8(9, 2)) // colour type 2: RGB
        .buffer
        .asUint8List(),
  );
  chunk('IDAT', ZLibCodec().encode(raw));
  chunk('IEND', const <int>[]);
  return file.takeBytes();
}

int _crc32(List<int> bytes) {
  int crc = 0xFFFFFFFF;
  for (final int byte in bytes) {
    crc ^= byte;
    for (int bit = 0; bit < 8; bit++) {
      crc = (crc & 1) != 0 ? (crc >> 1) ^ 0xEDB88320 : crc >> 1;
    }
  }
  return crc ^ 0xFFFFFFFF;
}

/// Writes the screenshots as 24-bit PNGs, and compares only what is stable
/// across days and operating systems: the stored PNG exists and is exactly the
/// size Play asks for, and the fresh render is the same size. See the note at
/// the top of the file.
class _StoreShotComparator extends LocalFileComparator {
  _StoreShotComparator(super.testFile);

  @override
  Future<void> update(Uri golden, Uint8List imageBytes) async =>
      super.update(golden, await _withoutAlpha(imageBytes));

  static (int, int) _size(Uint8List png) {
    final ByteData header = ByteData.sublistView(png);
    return (header.getUint32(16), header.getUint32(20));
  }

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final File stored = File.fromUri(basedir.resolveUri(golden));
    if (!stored.existsSync()) {
      throw TestFailure(
        'Missing ${stored.path}. Generate it with: '
        'flutter test --update-goldens test/screenshots_test.dart',
      );
    }
    const (int, int) wanted = (1080, 1920);
    return _size(imageBytes) == wanted &&
        _size(await stored.readAsBytes()) == wanted;
  }
}

/// One screenshot. Tests draw every shadow as a hard black copy of the shape;
/// a phone blurs it, so the shadows are switched back on for the length of the
/// test. The framework insists that this flag and debugPrint are restored
/// before the test ends, hence the finally.
void _screenshot(
  String description,
  Future<void> Function(WidgetTester tester) body,
) {
  testWidgets(description, (WidgetTester tester) async {
    final DebugPrintCallback printed = debugPrint;
    debugPrint = _withoutGoogleFontsNoise(printed);
    debugDisableShadows = false;
    try {
      await body(tester);
      // google_fonts' failed loads report after the screen was drawn, in real
      // time; let them finish while the filter is still in place.
      await tester.runAsync(() async {
        try {
          await GoogleFonts.pendingFonts();
        } on Object {
          // Expected: nothing is fetched.
        }
      });
    } finally {
      debugDisableShadows = true;
      debugPrint = printed;
    }
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // The debug banner is not in the release app the store shows.
  WidgetsApp.debugAllowBannerOverride = false;

  setUpAll(() async {
    await _loadFonts();
    final LocalFileComparator current =
        goldenFileComparator as LocalFileComparator;
    goldenFileComparator = _StoreShotComparator(
      current.basedir.resolve('screenshots_test.dart'),
    );
  });

  group('store screenshots, 1080 x 1920, dark theme', () {
    _screenshot('home: the teacher and the first chord', (tester) async {
      await _open(tester);
      await _scrollTo(tester, 96);
      await _capture(tester, '01-home');
    });

    _screenshot('practice: the teacher hears the chord', (tester) async {
      final _Phone phone = await _open(tester);
      phone.router.push('/tutor/song/kabira/step/3');
      await _untilLoaded(tester);
      final Finder start = find.text('Start Practice');
      await tester.ensureVisible(start);
      await tester.tap(start);
      await _pump(tester, 500);
      await _scrollTo(tester, 0);
      for (int chord = 0; chord < 3; chord++) {
        await _strum(tester, phone);
        // Let the celebration finish and the next chord come up.
        await _realTime(tester, 1000);
        await _pump(tester, 400);
      }
      await _strum(tester, phone, seconds: 0.9);
      await _pump(tester, 600);
      await _capture(tester, '02-practice');
      await _leave(tester);
    });

    _screenshot('learn: the tutor\'s plan', (tester) async {
      final _Phone phone = await _open(tester);
      phone.router.go('/learn');
      await _untilLoaded(tester);
      await _scrollTo(tester, 91);
      await _capture(tester, '03-learn');
    });

    _screenshot('tuner: a string is a little flat', (tester) async {
      final _Phone phone = await _open(tester);
      phone.router.push('/tuner');
      await _untilLoaded(tester);
      await tester.tap(find.text('Start listening'));
      await _pump(tester, 300);
      // Low E and A are in tune; the D string is a touch flat.
      await phone.microphone.play(tester, _Microphone.string(82.41));
      await phone.microphone.play(tester, _Microphone.string(110.0));
      await phone.microphone.play(tester, _Microphone.string(145.6));
      await _pump(tester, 200);
      await _capture(tester, '04-tuner');
    });

    _screenshot('library: the song catalogue', (tester) async {
      final _Phone phone = await _open(tester);
      phone.router.push('/library');
      await _untilLoaded(tester);
      await _capture(tester, '05-songs');
    });

    _screenshot('progress: a week of practice', (tester) async {
      final _Phone phone = await _open(tester);
      phone.router.go('/progress');
      await _untilLoaded(tester);
      await _scrollTo(tester, 96);
      await _capture(tester, '06-progress');
    });
  });
}
