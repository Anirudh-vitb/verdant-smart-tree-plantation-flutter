// MODULE 6: Home page with bottom navigation (3 tabs)
import 'package:flutter/material.dart';

import 'dashboard_screen.dart';
import 'maintenance_screen.dart';
import 'tree_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    DashboardScreen(),
    TreeListScreen(),
    MaintenanceScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.green,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.park), label: 'Trees'),
          BottomNavigationBarItem(icon: Icon(Icons.build), label: 'Maintenance'),
        ],
      ),
    );
  }
}
