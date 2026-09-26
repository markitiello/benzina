import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/favorites/favorites_screen.dart';
import '../features/map/map_screen.dart';
import '../features/nearby/nearby_screen.dart';
import '../features/notifications/notifications_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/station/station_detail_screen.dart';
import '../features/trends/trends_screen.dart';

GoRouter buildRouter({
  String initialLocation = '/splash',
  Duration? splashDuration,
}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, _) => splashDuration == null
            ? const SplashScreen()
            : SplashScreen(minimumDuration: splashDuration),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => _HomeShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/', builder: (_, _) => const NearbyScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/mappa', builder: (_, _) => const MapScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/andamento',
                builder: (_, _) => const TrendsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/preferiti',
                builder: (_, _) => const FavoritesScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/distributore/:id',
        builder: (_, state) =>
            StationDetailScreen(stationId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/notifiche',
        builder: (_, _) => const NotificationsScreen(),
      ),
      GoRoute(path: '/impostazioni', builder: (_, _) => const SettingsScreen()),
    ],
  );
}

class _HomeShell extends StatelessWidget {
  const _HomeShell({required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.place_outlined),
            selectedIcon: Icon(Icons.place),
            label: 'Vicino',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Mappa',
          ),
          NavigationDestination(
            icon: Icon(Icons.show_chart_rounded),
            label: 'Andamento',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border_rounded),
            selectedIcon: Icon(Icons.favorite_rounded),
            label: 'Preferiti',
          ),
        ],
      ),
    );
  }
}
