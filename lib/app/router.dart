import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/home/home_screen.dart';
import '../features/search/search_screen.dart';
import '../features/library/library_screen.dart';
import '../features/player/now_playing_screen.dart';
import '../features/playlist/playlist_screen.dart';
import 'shell_screen.dart';

/// App router configuration using go_router
final router = GoRouter(
  initialLocation: '/home',
  routes: [
    // Shell route for bottom navigation
    ShellRoute(
      builder: (context, state, child) => ShellScreen(child: child),
      routes: [
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: HomeScreen()),
        ),
        GoRoute(
          path: '/search',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: SearchScreen()),
        ),
        GoRoute(
          path: '/library',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: LibraryScreen()),
        ),
      ],
    ),
    // Full screen routes (outside shell)
    GoRoute(
      path: '/now-playing',
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const NowPlayingScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                .animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: '/playlist/:id',
      builder: (context, state) {
        final playlistId = int.parse(state.pathParameters['id']!);
        return PlaylistScreen(playlistId: playlistId);
      },
    ),
  ],
);
