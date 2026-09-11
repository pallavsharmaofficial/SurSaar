import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sursaar/widgets/app_back_button.dart';

import 'test_app.dart';

void main() {
  const routes = <String>[
    '/home',
    '/learn',
    '/progress',
    '/profile',
    '/search?q=G',
    '/tuner',
    '/onboarding',
    '/song/kabira',
    '/course/course_guitar_foundations',
    '/lesson/basic_chords',
    '/practice/song/channa_mereya',
    '/practice/song/channa_mereya?mode=playAlong',
    '/practice/lesson/strumming_patterns',
    '/practice/adhoc?chords=Em&mode=learn',
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
        await pumpTestApp(tester, route: route, size: size.value);
        expect(find.byType(Scaffold), findsWidgets);
      });
    }
  }

  testWidgets('a deep-linked screen offers a way home', (tester) async {
    await pumpTestApp(
      tester,
      route: '/song/kabira',
      size: const Size(360, 740),
    );
    expect(find.byType(AppBackButton), findsOneWidget);
    expect(find.byIcon(Icons.home_outlined), findsOneWidget);
    await tester.tap(find.byType(AppBackButton));
    await settle(tester);
    expect(find.text('AI Teacher'), findsOneWidget);
  });
}
