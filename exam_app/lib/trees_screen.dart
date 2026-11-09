// MODULE 5: Trees (list + search)
import 'package:flutter/material.dart';
import 'data.dart';
import 'add_tree_screen.dart';
import 'tree_detail_screen.dart';

class TreesScreen extends StatefulWidget {
  @override
  State<TreesScreen> createState() => _TreesScreenState();
}

class _TreesScreenState extends State<TreesScreen> {
  String search = '';

  @override
  Widget build(BuildContext context) {
    List<Tree> list = trees.where((t) => t.name.toLowerCase().contains(search.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(title: Text('Trees')),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8),
            child: TextField(
              decoration: InputDecoration(labelText: 'Search tree', prefixIcon: Icon(Icons.search)),
              onChanged: (value) => setState(() => search = value),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: list.length,
              itemBuilder: (context, i) {
                return Card(
                  child: ListTile(
                    leading: Icon(Icons.park, color: Colors.green),
                    title: Text(list[i].name),
                    subtitle: Text('${list[i].species} - ${list[i].health}'),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => TreeDetailScreen(list[i])))
                          .then((value) => setState(() {}));
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => AddTreeScreen()))
              .then((value) => setState(() {}));
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
