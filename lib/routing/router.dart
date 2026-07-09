import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../ui/core/scaffold_with_nav_bar.dart';
import '../ui/features/auth/views/login_screen.dart';
import '../ui/features/editor/views/editor_screen.dart';
import '../ui/features/feed/views/feed_screen.dart';
import '../ui/features/post_detail/views/post_detail_screen.dart';
import '../ui/features/profile/views/profile_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

/// The app's route tree.
///
/// A [StatefulShellRoute] hosts the bottom-nav tabs (Feed, Write, Profile),
/// while `/login` and the deep-linkable `/post/:id` live outside the shell so
/// they render full-screen without the navigation bar.
final GoRouter router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          ScaffoldWithNavBar(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const FeedScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/write',
              builder: (context, state) => const EditorScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/post/:id',
      builder: (context, state) =>
          PostDetailScreen(postId: state.pathParameters['id']!),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(),
    body: Center(child: Text('Page not found: ${state.uri}')),
  ),
);
