import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sursaar/core/app.dart';
import 'package:sursaar/core/routing/app_router.dart';
import 'package:sursaar/data/content/chord_library.dart';
import 'package:sursaar/data/local/local_store.dart';
import 'package:sursaar/widgets/app_back_button.dart';

Future<void> _pumpAt(WidgetTester tester, Size size, String route) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  // Asset futures cached by a previous test belong to its fake-async zone.
  rootBundle.clear();
  await tester.pumpWidget(
    App(
      store: InMemoryLocalStore(),
      chordLibrary: await ChordLibrary.loadFromAsset(),
      httpClient: MockClient((_) async => http.Response('offline', 503)),
      router: AppRouter.createRouter(initialLocation: route),
    ),
  );
  await _settle(tester);
}

Future<void> _settle(WidgetTester tester) => tester.pumpAndSettle(
  const Duration(milliseconds: 100),
  EnginePhase.sendSemanticsUpdate,
  const Duration(seconds: 20),
);

void main() {
  const routes = <String>[
    '/home',
    '/learn',
    '/progress',
    '/profile',
    '/search?q=G',
    '/song/kabira',
    '/course/course_guitar_foundations',
    '/lesson/basic_chords',
    '/practice/song/channa_mereya',
    '/practice/lesson/strumming_patterns',
    '/practice/adhoc?chords=G,C,D,Em&pattern=D%20-%20D%20-%20UU%20-%20D%20-%20DU&bpm=80',
  ];
  const sizes = <String, Size>{
    'phone': Size(360, 740),
    'tablet': Size(768, 1024),
  };

  for (final size in sizes.entries) {
    for (final route in routes) {
      testWidgets('$route lays out without overflow on ${size.key}', (
        tester,
      ) async {
        // Any layout error (e.g. a RenderFlex overflow) fails the test and is
        // reported with the widget that caused it.
        await _pumpAt(tester, size.value, route);
        expect(find.byType(Scaffold), findsWidgets);
      });
    }
  }

  testWidgets('a deep-linked screen offers a way home', (tester) async {
    await _pumpAt(tester, const Size(360, 740), '/song/kabira');
    expect(find.byType(AppBackButton), findsOneWidget);
    expect(find.byIcon(Icons.home_outlined), findsOneWidget);
    await tester.tap(find.byType(AppBackButton));
    await _settle(tester);
    expect(find.text('AI Teacher'), findsOneWidget);
  });
}
