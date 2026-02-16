import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sursaar/l10n/app_localizations.dart';
import '../blocs/lesson/lesson_bloc.dart';
import '../blocs/lesson/lesson_event.dart';
import '../data/local/app_database.dart';
import '../repositories/achievement_repository.dart';
import '../repositories/content_repository.dart';
import '../repositories/lesson_repository.dart';
import '../repositories/practice_repository.dart';
import '../repositories/profile_repository.dart';
import '../repositories/progress_repository.dart';
import '../repositories/song_repository.dart';
import 'routing/app_router.dart';
import 'theme/app_theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: <RepositoryProvider<dynamic>>[
        RepositoryProvider<AppDatabase>(
          create: (_) => AppDatabase.instance,
        ),
        RepositoryProvider<ContentRepository>(
          create: (_) => ContentRepository(),
        ),
        RepositoryProvider<SongRepository>(
          create: (context) => SongRepository(
            database: context.read<AppDatabase>(),
          ),
        ),
        RepositoryProvider<LessonRepository>(
          create: (context) => LessonRepository(
            database: context.read<AppDatabase>(),
          ),
        ),
        RepositoryProvider<ProgressRepository>(
          create: (context) => ProgressRepository(
            database: context.read<AppDatabase>(),
          ),
        ),
        RepositoryProvider<PracticeRepository>(
          create: (context) => PracticeRepository(
            database: context.read<AppDatabase>(),
          ),
        ),
        RepositoryProvider<AchievementRepository>(
          create: (context) => AchievementRepository(
            database: context.read<AppDatabase>(),
          ),
        ),
        RepositoryProvider<ProfileRepository>(
          create: (context) => ProfileRepository(
            database: context.read<AppDatabase>(),
          ),
        ),
      ],
      child: MultiBlocProvider(
        providers: <BlocProvider<dynamic>>[
          BlocProvider<LessonBloc>(
            create: (context) => LessonBloc(
              repository: context.read<LessonRepository>(),
              contentRepository: context.read<ContentRepository>(),
            )..add(const FetchContentEvent()),
          ),
        ],
        child: MaterialApp.router(
          title: 'SurSaar',
          routerConfig: AppRouter.router,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.dark,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
        ),
      ),
    );
  }
}
