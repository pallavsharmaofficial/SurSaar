import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:sursaar/l10n/app_localizations.dart';

import '../data/content/chord_library.dart';
import '../data/local/app_database.dart';
import '../data/local/local_store.dart';
import '../repositories/achievement_repository.dart';
import '../repositories/content_repository.dart';
import '../repositories/course_repository.dart';
import '../repositories/lesson_repository.dart';
import '../repositories/practice_repository.dart';
import '../repositories/profile_repository.dart';
import '../repositories/progress_repository.dart';
import '../repositories/settings_repository.dart';
import '../repositories/song_repository.dart';
import 'routing/app_router.dart';
import 'theme/app_theme.dart';

/// Root widget. Dependencies are injected so tests can swap the store and
/// the HTTP client.
class App extends StatefulWidget {
  const App({
    super.key,
    required this.store,
    required this.chordLibrary,
    this.httpClient,
    this.contentUrl,
    this.router,
  });

  final LocalStore store;
  final ChordLibrary chordLibrary;
  final http.Client? httpClient;
  final String? contentUrl;

  /// Inject a router (tests); otherwise the app creates its own.
  final GoRouter? router;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final AppDatabase _database = AppDatabase(store: widget.store);
  late final ContentRepository _content = ContentRepository(
    store: widget.store,
    client: widget.httpClient,
    contentUrl: widget.contentUrl,
  );
  late final GoRouter _router = widget.router ?? AppRouter.createRouter();

  @override
  void initState() {
    super.initState();
    _content.bundle.addListener(_onBundleChanged);
    _content.fetchContent();
  }

  void _onBundleChanged() {
    final bundle = _content.bundle.value;
    if (bundle != null) widget.chordLibrary.addAll(bundle.chords);
  }

  @override
  void dispose() {
    _content.bundle.removeListener(_onBundleChanged);
    _content.dispose();
    if (widget.router == null) _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: <RepositoryProvider<dynamic>>[
        RepositoryProvider<AppDatabase>.value(value: _database),
        RepositoryProvider<ContentRepository>.value(value: _content),
        RepositoryProvider<ChordLibrary>.value(value: widget.chordLibrary),
        RepositoryProvider<SongRepository>(
          create: (context) =>
              SongRepository(database: _database, content: _content),
        ),
        RepositoryProvider<LessonRepository>(
          create: (context) =>
              LessonRepository(database: _database, content: _content),
        ),
        RepositoryProvider<CourseRepository>(
          create: (context) =>
              CourseRepository(database: _database, content: _content),
        ),
        RepositoryProvider<ProgressRepository>(
          create: (context) => ProgressRepository(database: _database),
        ),
        RepositoryProvider<PracticeRepository>(
          create: (context) => PracticeRepository(database: _database),
        ),
        RepositoryProvider<AchievementRepository>(
          create: (context) => AchievementRepository(database: _database),
        ),
        RepositoryProvider<ProfileRepository>(
          create: (context) => ProfileRepository(database: _database),
        ),
        RepositoryProvider<SettingsRepository>(
          create: (context) => SettingsRepository(database: _database),
        ),
      ],
      child: MaterialApp.router(
        title: 'SurSaar',
        routerConfig: _router,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
  }
}
