import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../navigation/app_screens.dart';

class SidebarNavigation extends StatelessWidget {
  final GoRouter router;

  const SidebarNavigation({super.key, required this.router});

  @override
  Widget build(BuildContext context) {
    final String currentRoute = GoRouterState.of(context).uri.toString();

    return NavigationRail(
      selectedIndex: _getSelectedIndex(currentRoute),
      onDestinationSelected: (int index) {
        final AppScreen screen = AppScreen.values[index];
        router.go(screen.route);
      },
      labelType: NavigationRailLabelType.all,
      destinations: AppScreen.values
          .where((screen) => screen.showInSidebar)
          .map(
            (screen) => NavigationRailDestination(
              icon: Icon(screen.icon),
              label: Text(screen.title),
            ),
          )
          .toList(),
    );
  }

  int _getSelectedIndex(String currentRoute) {
    for (int i = 0; i < AppScreen.values.length; i++) {
      if (AppScreen.values[i].route == currentRoute.split('?').first) {
        return i;
      }
    }
    return 0;
  }
}
