import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sursaar/widgets/chord_sheet.dart';
import 'package:sursaar/widgets/teacher/chord_diagram.dart';
import 'package:sursaar/widgets/teacher/chord_ribbon.dart';
import 'package:sursaar/widgets/teacher/strumming_timeline.dart';

import '../data/chord_sheet_parser_test.dart' show gluedSheet;
import 'test_app.dart';

void main() {
  testWidgets('home shows the teacher hero, start-here card and songs', (
    tester,
  ) async {
    // Tall viewport so the song list below the new cards is laid out.
    await pumpTestApp(tester, size: const Size(1400, 2000));
    expect(find.text('AI Teacher'), findsOneWidget);
    expect(find.text('Quick practice'), findsOneWidget);
    expect(find.text('Start here'), findsOneWidget);
    expect(find.text('Channa Mereya'), findsWidgets);
  });

  testWidgets('first launch shows onboarding, then home', (tester) async {
    final (_, store) = await pumpTestApp(tester, onboardingSeen: false);
    expect(find.text('Pick a song or a chord'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await settle(tester);
    await tester.tap(find.text('Next'));
    await settle(tester);
    await tester.tap(find.text('Get started'));
    await settle(tester);
    expect(find.text('AI Teacher'), findsOneWidget);
    expect(
      await store.getString('settings'),
      contains('"onboarding_seen":true'),
    );
  });

  testWidgets('song detail: diagrams, strumming, sections, chord sheet', (
    tester,
  ) async {
    final (router, _) = await pumpTestApp(tester);
    router.go('/song/channa_mereya');
    await settle(tester);

    expect(find.text('Practise with the AI Teacher'), findsOneWidget);
    expect(find.byType(ChordDiagram), findsNWidgets(4));
    expect(find.byType(StrummingTimeline), findsOneWidget);
    expect(find.text('Verse'), findsOneWidget);
    expect(find.text('Tap a chord to see and hear it'), findsOneWidget);

    await tester.tap(find.byType(ChordDiagram).first);
    await settle(tester);
    expect(find.byType(ChordSheet), findsOneWidget);
    expect(find.text('Practise this chord'), findsOneWidget);
  });

  testWidgets('practice screen starts in learn mode with a setup card', (
    tester,
  ) async {
    final (router, _) = await pumpTestApp(tester);
    router.go('/practice/song/channa_mereya');
    await settle(tester);

    expect(find.text('Learn'), findsWidgets);
    expect(find.text('Play along'), findsOneWidget);
    expect(find.text("Let's get set up"), findsOneWidget);
    expect(find.text('Start Practice'), findsOneWidget);
    expect(find.textContaining('How to play'), findsOneWidget);
    expect(find.byType(ChordRibbon), findsNothing);

    await tester.tap(find.text('Play along'));
    await settle(tester);
    expect(find.byType(ChordRibbon), findsOneWidget);

    await tester.tap(find.text('More options'));
    await settle(tester);
    expect(find.text('Tempo: 75 BPM'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ad-hoc practice route honours chords, tempo and mode', (
    tester,
  ) async {
    final (router, _) = await pumpTestApp(tester);
    router.go(
      '/practice/adhoc?chords=Em,C&pattern=D%20DU%20UDU&bpm=90&mode=learn',
    );
    await settle(tester);

    expect(find.text('Quick practice'), findsWidgets);
    expect(find.text('Em'), findsWidgets);
    await tester.tap(find.text('More options'));
    await settle(tester);
    expect(find.text('Tempo: 90 BPM'), findsOneWidget);
  });

  testWidgets('tuner screen offers to listen', (tester) async {
    final (router, _) = await pumpTestApp(tester);
    router.go('/tuner');
    await settle(tester);
    expect(find.text('Tune your guitar'), findsOneWidget);
    expect(find.text('Start listening'), findsOneWidget);
    expect(find.text('Low E'), findsOneWidget);
  });

  testWidgets('learn tab shows courses and lessons', (tester) async {
    final (router, _) = await pumpTestApp(tester);
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
    final (router, _) = await pumpTestApp(tester);
    router.go('/search?q=Bm');
    await settle(tester);
    expect(find.text('Kabira'), findsOneWidget);
    expect(find.text('Request this song'), findsOneWidget);
  });

  testWidgets('search offers online chords and pasting when nothing matches', (
    tester,
  ) async {
    final (router, _) = await pumpTestApp(tester);
    router.go('/search?q=zzzz');
    await settle(tester);
    expect(find.textContaining('No songs found for'), findsOneWidget);
    expect(find.text('Find chords online'), findsOneWidget);
    expect(find.text('Paste a chord sheet'), findsWidgets);
  });

  testWidgets('pasting a chord sheet adds your own song', (tester) async {
    // Tall viewport so the whole import form is laid out.
    final (router, _) = await pumpTestApp(tester, size: const Size(1400, 2200));
    router.go('/import?q=Tere Paas Main');
    await settle(tester);
    expect(find.text('Add a song'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, gluedSheet);
    await settle(tester);
    expect(find.text('Chords found'), findsOneWidget);
    expect(find.text('Am'), findsWidgets);
    expect(find.textContaining('Verse 1'), findsWidgets);

    await tester.tap(find.text('Add to my songs'));
    await settle(tester);

    // lands on the new song, marked as the learner's own
    expect(find.text('Added by you'), findsOneWidget);
    expect(find.text('Practise with the AI Teacher'), findsOneWidget);
  });
}
