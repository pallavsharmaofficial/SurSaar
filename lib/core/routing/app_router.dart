import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import '../../models/song.dart';
import '../../screens/home_screen.dart';
import '../../screens/song_detail_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        name: 'home',
        builder: (BuildContext context, GoRouterState state) {
          return const HomeScreen();
        },
      ),
      GoRoute(
        path: '/song',
        name: 'song',
        builder: (BuildContext context, GoRouterState state) {
          final song = state.extra! as Song;
          return SongDetailScreen(song: song);
        },
      ),
    ],
  );
}
