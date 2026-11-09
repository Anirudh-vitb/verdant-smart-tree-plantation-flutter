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
    return Scaffold(
      appBar: AppBar(title: Text('Trees')),
      body: ListView(
        children: [
          TextField(
            decoration: InputDecoration(labelText: 'Search tree'),
            onChanged: (value) => setState(() => search = value),
          ),
          for (Tree t in trees)
            if (t.name.contains(search))
              ListTile(
                title: Text(t.name),
                subtitle: Text(t.species),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => TreeDetailScreen(t)))
                      .then((value) => setState(() {}));
                },
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
