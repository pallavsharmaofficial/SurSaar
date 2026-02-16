import 'package:go_router/go_router.dart';
import '../../models/lesson.dart';
import '../../models/song.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/lessons/lesson_detail_screen.dart';
import '../../screens/lessons/lessons_screen.dart';
import '../../screens/practice/practice_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/progress/progress_screen.dart';
import '../../screens/shell/app_shell_screen.dart';
import '../../screens/songs/song_detail_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/home',
    routes: <RouteBase>[
      ShellRoute(
        builder: (context, state, child) {
          return AppShellScreen(child: child);
        },
        routes: <RouteBase>[
          GoRoute(
            path: '/home',
            name: 'home',
            pageBuilder: (context, state) {
              return const NoTransitionPage(child: HomeScreen());
            },
          ),
          GoRoute(
            path: '/lessons',
            name: 'lessons',
            pageBuilder: (context, state) {
              return const NoTransitionPage(child: LessonsScreen());
            },
          ),
          GoRoute(
            path: '/progress',
            name: 'progress',
            pageBuilder: (context, state) {
              return const NoTransitionPage(child: ProgressScreen());
            },
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            pageBuilder: (context, state) {
              return const NoTransitionPage(child: ProfileScreen());
            },
          ),
        ],
      ),
      GoRoute(
        path: '/song/:id',
        name: 'songDetail',
        builder: (context, state) {
          final song = state.extra! as Song;
          return SongDetailScreen(song: song);
        },
      ),
      GoRoute(
        path: '/practice/:songId',
        name: 'practice',
        builder: (context, state) {
          final songId = state.pathParameters['songId']!;
          return PracticeScreen(songId: songId);
        },
      ),
      GoRoute(
        path: '/lesson/:id',
        name: 'lessonDetail',
        builder: (context, state) {
          final lesson = state.extra! as Lesson;
          return LessonDetailScreen(lesson: lesson);
        },
      ),
    ],
  );
}
