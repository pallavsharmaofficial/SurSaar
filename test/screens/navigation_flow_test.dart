import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sursaar/core/app.dart';
import 'package:sursaar/core/routing/app_router.dart';
import 'package:sursaar/data/content/chord_library.dart';
import 'package:sursaar/data/local/local_store.dart';
import 'package:sursaar/widgets/teacher/chord_diagram.dart';
import 'package:sursaar/widgets/teacher/chord_ribbon.dart';
import 'package:sursaar/widgets/teacher/strumming_timeline.dart';

void main() {
  late GoRouter router;

  Future<void> settle(WidgetTester tester) => tester.pumpAndSettle(
    const Duration(milliseconds: 100),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 20),
  );

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    // Asset futures cached by a previous test belong to that test's
    // fake-async zone and would never complete here.
    rootBundle.clear();
    router = AppRouter.createRouter();
    await tester.pumpWidget(
      App(
        store: InMemoryLocalStore(),
        chordLibrary: await ChordLibrary.loadFromAsset(),
        httpClient: MockClient((_) async => http.Response('offline', 503)),
        router: router,
      ),
    );
    await settle(tester);
  }

  testWidgets('home lists bundled songs and opens the AI teacher hero', (
    tester,
  ) async {
    await pumpApp(tester);
    expect(find.text('AI Teacher'), findsOneWidget);
    expect(find.text('Quick practice'), findsOneWidget);
    expect(find.text('Channa Mereya'), findsWidgets);
  });

  testWidgets('song detail shows diagrams, strumming grid and sections', (
    tester,
  ) async {
    await pumpApp(tester);
    router.go('/song/channa_mereya');
    await settle(tester);

    expect(find.text('Channa Mereya'), findsWidgets);
    expect(find.text('Practise with the AI Teacher'), findsOneWidget);
    // C Am F G shapes at the sheet capo
    expect(find.byType(ChordDiagram), findsNWidgets(4));
    expect(find.text('C'), findsWidgets);
    expect(find.byType(StrummingTimeline), findsOneWidget);
    expect(find.text('Verse'), findsOneWidget);
    expect(find.text('Chorus'), findsOneWidget);
  });

  testWidgets('teacher screen initialises a song plan without crashing', (
    tester,
  ) async {
    await pumpApp(tester);
    router.go('/practice/song/channa_mereya');
    await settle(tester);

    expect(find.text('Play now'), findsOneWidget);
    expect(find.byType(ChordRibbon), findsOneWidget);
    expect(find.text('Start Practice'), findsOneWidget);
    expect(find.textContaining('How to play'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ad-hoc practice route builds from query parameters', (
    tester,
  ) async {
    await pumpApp(tester);
    router.go('/practice/adhoc?chords=Em,C&pattern=D%20DU%20UDU&bpm=90');
    await settle(tester);

    expect(find.text('Quick practice'), findsWidgets);
    expect(find.textContaining('90 BPM'), findsOneWidget);
    expect(find.text('Em'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('learn tab shows courses and lessons', (tester) async {
    await pumpApp(tester);
    router.go('/learn');
    await settle(tester);

    expect(find.text('Guitar Foundations'), findsOneWidget);
    expect(find.text('Basic Guitar Chords'), findsOneWidget);
    router.go('/course/course_guitar_foundations');
    await settle(tester);
    expect(
      find.textContaining('Start: The Open Chord Foundation'),
      findsOneWidget,
    );
  });

  testWidgets('search finds songs by chord and offers requests', (
    tester,
  ) async {
    await pumpApp(tester);
    router.go('/search?q=Bm');
    await settle(tester);
    expect(find.text('Kabira'), findsOneWidget);
    expect(find.text('Request this song'), findsOneWidget);
  });
}
