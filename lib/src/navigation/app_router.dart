import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../screens/movies_screen.dart';
import '../screens/series_screen.dart';
import '../screens/search_screen.dart';
import '../screens/favorites_screen.dart';
import '../screens/settings_screen.dart';
import '../widgets/app_shell.dart';

final GoRouter appRouter = GoRouter(
  routes: <RouteBase>[
    GoRoute(path: '/', redirect: (_, __) => '/movies'),
    GoRoute(
      path: '/movies',
      builder: (BuildContext context, GoRouterState state) {
        return AppShell(child: const MoviesScreen());
      },
    ),
    GoRoute(
      path: '/series',
      builder: (BuildContext context, GoRouterState state) {
        return AppShell(child: const SeriesScreen());
      },
    ),
    GoRoute(
      path: '/search',
      builder: (BuildContext context, GoRouterState state) {
        return AppShell(child: const SearchScreen());
      },
    ),
    GoRoute(
      path: '/favorites',
      builder: (BuildContext context, GoRouterState state) {
        return AppShell(child: const FavoritesScreen());
      },
    ),
    GoRoute(
      path: '/settings',
      builder: (BuildContext context, GoRouterState state) {
        return AppShell(child: const SettingsScreen());
      },
    ),
  ],
);
