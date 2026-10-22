import 'package:flutter/material.dart';

import '../dashboard/dashboard_screen.dart';
import '../maintenance/maintenance_screen.dart';
import '../trees/trees_screen.dart';

/// Main navigation: bottom bar on phones, side rail on wide screens.
///
/// An [IndexedStack] keeps each tab alive, so search text and filters are
/// preserved when switching tabs.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _destinations = [
    (
      icon: Icons.dashboard_outlined,
      selected: Icons.dashboard,
      label: 'Dashboard',
    ),
    (icon: Icons.park_outlined, selected: Icons.park, label: 'Trees'),
    (
      icon: Icons.handyman_outlined,
      selected: Icons.handyman,
      label: 'Maintenance',
    ),
  ];

  void _select(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final pages = IndexedStack(
      index: _index,
      children: [
        DashboardScreen(onOpenTab: _select),
        const TreesScreen(),
        const MaintenanceScreen(),
      ],
    );
    final wide = MediaQuery.sizeOf(context).width >= 840;

    // Back on another tab returns to the dashboard instead of closing the app.
    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _select(0);
      },
      child: wide
          ? Scaffold(
              body: Row(
                children: [
                  NavigationRail(
                    selectedIndex: _index,
                    onDestinationSelected: _select,
                    labelType: NavigationRailLabelType.all,
                    destinations: [
                      for (final d in _destinations)
                        NavigationRailDestination(
                          icon: Icon(d.icon),
                          selectedIcon: Icon(d.selected),
                          label: Text(d.label),
                        ),
                    ],
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: pages),
                ],
              ),
            )
          : Scaffold(
              body: pages,
              bottomNavigationBar: NavigationBar(
                selectedIndex: _index,
                onDestinationSelected: _select,
                destinations: [
                  for (final d in _destinations)
                    NavigationDestination(
                      icon: Icon(d.icon),
                      selectedIcon: Icon(d.selected),
                      label: d.label,
                    ),
                ],
              ),
            ),
    );
  }
}
