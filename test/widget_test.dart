import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'screens/test_app.dart';

void main() {
  testWidgets('App builds and shows navigation', (tester) async {
    await pumpTestApp(tester, size: const Size(400, 800));
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Learn'), findsOneWidget);
    expect(find.text('Progress'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });
}
