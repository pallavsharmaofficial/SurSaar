import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/coaching_mode.dart';
import '../../models/lesson.dart';
import '../../models/song.dart';
import '../../screens/courses/course_detail_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/learn/learn_screen.dart';
import '../../screens/lessons/lesson_detail_screen.dart';
import '../../screens/onboarding/onboarding_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/progress/progress_screen.dart';
import '../../screens/shell/app_shell_screen.dart';
import '../../screens/songs/import_song_screen.dart';
import '../../screens/songs/song_detail_screen.dart';
import '../../screens/songs/song_search_screen.dart';
import '../../screens/teacher/teacher_screen.dart';
import '../../screens/tuner/tuner_screen.dart';

/// Routes are plain URLs so every screen deep-links on the web
/// (e.g. `#/song/kabira`, `#/practice/adhoc?chords=Em&mode=learn`).
class AppRouter {
  const AppRouter._();

  /// Each [App] owns its own router.
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
        path: '/onboarding',
        name: 'onboarding',
        pageBuilder: (context, state) => _page(state, const OnboardingScreen()),
      ),
      GoRoute(
        path: '/tuner',
        name: 'tuner',
        pageBuilder: (context, state) => _page(state, const TunerScreen()),
      ),
      GoRoute(
        path: '/search',
        name: 'search',
        pageBuilder: (context, state) => _page(
          state,
          SongSearchScreen(initialQuery: state.uri.queryParameters['q'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/import',
        name: 'importSong',
        pageBuilder: (context, state) => _page(
          state,
          ImportSongScreen(initialQuery: state.uri.queryParameters['q'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/song/:id',
        name: 'songDetail',
        pageBuilder: (context, state) {
          final extra = state.extra;
          return _page(
            state,
            SongDetailScreen(
              songId: state.pathParameters['id']!,
              initialSong: extra is Song ? extra : null,
            ),
          );
        },
      ),
      GoRoute(
        path: '/course/:id',
        name: 'courseDetail',
        pageBuilder: (context, state) => _page(
          state,
          CourseDetailScreen(courseId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/lesson/:id',
        name: 'lessonDetail',
        pageBuilder: (context, state) {
          final extra = state.extra;
          return _page(
            state,
            LessonDetailScreen(
              lessonId: state.pathParameters['id']!,
              initialLesson: extra is Lesson ? extra : null,
            ),
          );
        },
      ),
      GoRoute(
        path: '/practice/adhoc',
        name: 'practiceAdhoc',
        pageBuilder: (context, state) {
          final query = state.uri.queryParameters;
          final chords = (query['chords'] ?? 'G,C,D')
              .split(',')
              .map((c) => c.trim())
              .where((c) => c.isNotEmpty)
              .toList(growable: false);
          return _page(
            state,
            TeacherScreen(
              request: TeacherRequest.adhoc(
                chords: chords,
                pattern: query['pattern'],
                bpm: int.tryParse(query['bpm'] ?? ''),
                mode: _mode(state),
              ),
            ),
          );
        },
      ),
      GoRoute(
        path: '/practice/song/:id',
        name: 'practiceSong',
        pageBuilder: (context, state) => _page(
          state,
          TeacherScreen(
            request: TeacherRequest.song(
              state.pathParameters['id']!,
              mode: _mode(state),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/practice/lesson/:id',
        name: 'practiceLesson',
        pageBuilder: (context, state) => _page(
          state,
          TeacherScreen(
            request: TeacherRequest.lesson(
              state.pathParameters['id']!,
              mode: _mode(state),
            ),
          ),
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

  static CoachingMode? _mode(GoRouterState state) {
    final value = state.uri.queryParameters['mode'];
    return value == null || value.isEmpty ? null : CoachingMode.parse(value);
  }

  static Page<void> _page(GoRouterState state, Widget child) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}
