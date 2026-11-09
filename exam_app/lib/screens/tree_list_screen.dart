// MODULE 8: Tree list page (ListView + search)
import 'package:flutter/material.dart';

import '../models/plantation_data.dart';
import 'add_tree_screen.dart';
import 'tree_detail_screen.dart';

class TreeListScreen extends StatefulWidget {
  const TreeListScreen({super.key});

  @override
  State<TreeListScreen> createState() => _TreeListScreenState();
}

class _TreeListScreenState extends State<TreeListScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final results = trees
        .where((t) =>
            t.name.toLowerCase().contains(_search.toLowerCase()) ||
            t.species.toLowerCase().contains(_search.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Trees')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search by name or species',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _search = value),
            ),
          ),
          Expanded(
            child: results.isEmpty
                ? const Center(child: Text('No trees found'))
                : ListView.builder(
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final tree = results[index];
                      return Card(
                        child: ListTile(
                          leading: Icon(Icons.park, color: healthColor(tree.health), size: 36),
                          title: Text(tree.name),
                          subtitle: Text('${tree.species} • ${tree.location}'),
                          trailing: Text(
                            tree.health,
                            style: TextStyle(color: healthColor(tree.health)),
                          ),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => TreeDetailScreen(tree: tree)),
                            );
                            setState(() {}); // refresh after edit/delete
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddTreeScreen()),
          );
          setState(() {}); // show the new tree
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
