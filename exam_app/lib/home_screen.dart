// MODULE 3: Home (bottom navigation with 3 tabs)
import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'trees_screen.dart';
import 'maintenance_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int index = 0;
  List<Widget> pages = [DashboardScreen(), TreesScreen(), MaintenanceScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) => setState(() => index = i),
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.park), label: 'Trees'),
          BottomNavigationBarItem(icon: Icon(Icons.build), label: 'Maintenance'),
        ],
      ),
    );
  }
}
