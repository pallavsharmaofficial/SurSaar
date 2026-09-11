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

/// Pumps the whole app at [route] with an offline content client.
Future<(GoRouter, InMemoryLocalStore)> pumpTestApp(
  WidgetTester tester, {
  String route = '/home',
  Size size = const Size(1400, 900),
  bool onboardingSeen = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  // Asset futures cached by a previous test belong to its fake-async zone.
  rootBundle.clear();
  final store = InMemoryLocalStore();
  if (onboardingSeen) {
    await store.setString('settings', '{"onboarding_seen": true}');
  }
  final router = AppRouter.createRouter(initialLocation: route);
  await tester.pumpWidget(
    App(
      store: store,
      chordLibrary: await ChordLibrary.loadFromAsset(),
      httpClient: MockClient((_) async => http.Response('offline', 503)),
      router: router,
    ),
  );
  await settle(tester);
  return (router, store);
}

Future<void> settle(WidgetTester tester) => tester.pumpAndSettle(
  const Duration(milliseconds: 100),
  EnginePhase.sendSemanticsUpdate,
  const Duration(seconds: 20),
);
