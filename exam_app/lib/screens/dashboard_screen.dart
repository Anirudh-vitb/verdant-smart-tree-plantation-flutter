// MODULE 7: Dashboard page (statistics calculated from the data)
import 'package:flutter/material.dart';

import '../models/plantation_data.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final total = trees.length;
    final healthy = trees.where((t) => t.health == 'Healthy').length;
    final attention = total - healthy;
    final pending = tasks.where((t) => !t.isDone).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Colors.green.shade800,
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Welcome! Track your trees, watering and maintenance.',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              statCard('Total Trees', total, Icons.park, Colors.green),
              statCard('Healthy', healthy, Icons.check_circle, Colors.teal),
              statCard('Need Attention', attention, Icons.warning, Colors.orange),
              statCard('Pending Tasks', pending, Icons.pending_actions, Colors.blue),
            ],
          ),
        ],
      ),
    );
  }

  Widget statCard(String title, int value, IconData icon, Color color) {
    return Card(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: color),
          Text('$value', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          Text(title),
        ],
      ),
    );
  }
}
