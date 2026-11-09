// MODULE 10: Tree details page (record watering + delete with confirmation)
import 'package:flutter/material.dart';

import '../models/plantation_data.dart';
import '../models/tree.dart';

class TreeDetailScreen extends StatefulWidget {
  final Tree tree;

  const TreeDetailScreen({super.key, required this.tree});

  @override
  State<TreeDetailScreen> createState() => _TreeDetailScreenState();
}

class _TreeDetailScreenState extends State<TreeDetailScreen> {
  void _recordWatering() {
    setState(() => widget.tree.wateredOn.add(DateTime.now()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Watering recorded')),
    );
  }

  void _deleteTree() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete tree?'),
        content: Text('Are you sure you want to delete ${widget.tree.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              trees.remove(widget.tree);
              Navigator.pop(context); // close dialog
              Navigator.pop(this.context); // back to list
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tree = widget.tree;
    return Scaffold(
      appBar: AppBar(
        title: Text(tree.name),
        actions: [IconButton(icon: const Icon(Icons.delete), onPressed: _deleteTree)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Icon(Icons.park, size: 100, color: healthColor(tree.health)),
          Card(
            child: Column(
              children: [
                ListTile(leading: const Icon(Icons.eco), title: const Text('Species'), subtitle: Text(tree.species)),
                ListTile(leading: const Icon(Icons.place), title: const Text('Location'), subtitle: Text(tree.location)),
                ListTile(leading: const Icon(Icons.favorite), title: const Text('Health'), subtitle: Text(tree.health)),
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Planted on'),
                  subtitle: Text(formatDate(tree.plantedOn)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Watering history (${tree.wateredOn.length})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          if (tree.wateredOn.isEmpty) const Text('Not watered yet'),
          ...tree.wateredOn.map((date) => ListTile(
                leading: const Icon(Icons.water_drop, color: Colors.blue),
                title: Text('Watered on ${formatDate(date)}'),
              )),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _recordWatering,
        icon: const Icon(Icons.water_drop),
        label: const Text('Record Watering'),
      ),
    );
  }
}
