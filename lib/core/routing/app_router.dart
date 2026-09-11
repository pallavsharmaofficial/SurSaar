import 'package:go_router/go_router.dart';

import '../../models/lesson.dart';
import '../../models/song.dart';
import '../../screens/courses/course_detail_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/learn/learn_screen.dart';
import '../../screens/lessons/lesson_detail_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/progress/progress_screen.dart';
import '../../screens/shell/app_shell_screen.dart';
import '../../screens/songs/song_detail_screen.dart';
import '../../screens/songs/song_search_screen.dart';
import '../../screens/teacher/teacher_screen.dart';

/// Routes are plain URLs so every screen deep-links on the web
/// (e.g. `#/song/kabira`, `#/practice/adhoc?chords=G,C,D&pattern=D%20DU%20UDU`).
class AppRouter {
  const AppRouter._();

  /// Creates a router. Each [App] owns its own instance (a shared static
  /// router breaks when the app is rebuilt, e.g. in tests or hot restart).
  static GoRouter createRouter({String initialLocation = '/home'}) => GoRouter(
    initialLocation: initialLocation,
    routes: <RouteBase>[
      ShellRoute(
        builder: (context, state, child) => AppShellScreen(child: child),
        routes: <RouteBase>[
          GoRoute(
            path: '/home',
            name: 'home',
            pageBuilder: (context, state) =>
                const NoTransitionPage<void>(child: HomeScreen()),
          ),
          GoRoute(
            path: '/learn',
            name: 'learn',
            pageBuilder: (context, state) =>
                const NoTransitionPage<void>(child: LearnScreen()),
          ),
          GoRoute(path: '/lessons', redirect: (context, state) => '/learn'),
          GoRoute(
            path: '/progress',
            name: 'progress',
            pageBuilder: (context, state) =>
                const NoTransitionPage<void>(child: ProgressScreen()),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            pageBuilder: (context, state) =>
                const NoTransitionPage<void>(child: ProfileScreen()),
          ),
        ],
      ),
      GoRoute(
        path: '/search',
        name: 'search',
        builder: (context, state) => SongSearchScreen(
          initialQuery: state.uri.queryParameters['q'] ?? '',
        ),
      ),
      GoRoute(
        path: '/song/:id',
        name: 'songDetail',
        builder: (context, state) {
          final extra = state.extra;
          return SongDetailScreen(
            songId: state.pathParameters['id']!,
            initialSong: extra is Song ? extra : null,
          );
        },
      ),
      GoRoute(
        path: '/course/:id',
        name: 'courseDetail',
        builder: (context, state) =>
            CourseDetailScreen(courseId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/lesson/:id',
        name: 'lessonDetail',
        builder: (context, state) {
          final extra = state.extra;
          return LessonDetailScreen(
            lessonId: state.pathParameters['id']!,
            initialLesson: extra is Lesson ? extra : null,
          );
        },
      ),
      GoRoute(
        path: '/practice/adhoc',
        name: 'practiceAdhoc',
        builder: (context, state) {
          final query = state.uri.queryParameters;
          final chords = (query['chords'] ?? 'G,C,D')
              .split(',')
              .map((c) => c.trim())
              .where((c) => c.isNotEmpty)
              .toList(growable: false);
          return TeacherScreen(
            request: TeacherRequest.adhoc(
              chords: chords,
              pattern: query['pattern'],
              bpm: int.tryParse(query['bpm'] ?? ''),
            ),
          );
        },
      ),
      GoRoute(
        path: '/practice/song/:id',
        name: 'practiceSong',
        builder: (context, state) => TeacherScreen(
          request: TeacherRequest.song(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/practice/lesson/:id',
        name: 'practiceLesson',
        builder: (context, state) => TeacherScreen(
          request: TeacherRequest.lesson(state.pathParameters['id']!),
        ),
      ),
      // legacy v1 link
      GoRoute(
        path: '/practice/:songId',
        redirect: (context, state) =>
            '/practice/song/${state.pathParameters['songId']}',
      ),
    ],
  );
}
