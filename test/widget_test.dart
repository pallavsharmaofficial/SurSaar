import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sursaar/core/app.dart';
import 'package:sursaar/data/content/chord_library.dart';
import 'package:sursaar/data/local/local_store.dart';

void main() {
  testWidgets('App builds and shows navigation', (WidgetTester tester) async {
    await tester.pumpWidget(
      App(
        store: InMemoryLocalStore(),
        chordLibrary: ChordLibrary(const []),
        httpClient: MockClient((_) async => http.Response('offline', 503)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Learn'), findsOneWidget);
    expect(find.text('Progress'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });
}
