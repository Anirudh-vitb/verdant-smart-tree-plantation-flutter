// MODULE 4: Dashboard (counts from the data)
import 'package:flutter/material.dart';
import 'data.dart';

class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    int healthy = trees.where((t) => t.health == 'Healthy').length;
    int pending = tasks.where((t) => t.done == false).length;

    return Scaffold(
      appBar: AppBar(title: Text('Dashboard')),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          box('Total Trees', trees.length, Colors.green),
          box('Healthy Trees', healthy, Colors.teal),
          box('Need Attention', trees.length - healthy, Colors.orange),
          box('Pending Tasks', pending, Colors.blue),
        ],
      ),
    );
  }

  Widget box(String title, int count, Color color) {
    return Card(
      color: color,
      child: ListTile(
        title: Text(title, style: TextStyle(color: Colors.white, fontSize: 18)),
        trailing: Text('$count', style: TextStyle(color: Colors.white, fontSize: 28)),
      ),
    );
  }
}
