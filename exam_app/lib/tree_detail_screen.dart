// MODULE 7: Tree Details (details, watering history, delete)
import 'package:flutter/material.dart';
import 'data.dart';
import 'watering_screen.dart';

class TreeDetailScreen extends StatefulWidget {
  final Tree tree;
  TreeDetailScreen(this.tree);

  @override
  State<TreeDetailScreen> createState() => _TreeDetailScreenState();
}

class _TreeDetailScreenState extends State<TreeDetailScreen> {
  @override
  Widget build(BuildContext context) {
    Tree tree = widget.tree;

    return Scaffold(
      appBar: AppBar(title: Text(tree.name)),
      body: ListView(
        children: [
          ListTile(title: Text('Species'), subtitle: Text(tree.species)),
          ListTile(title: Text('Location'), subtitle: Text(tree.location)),
          ListTile(title: Text('Health'), subtitle: Text(tree.health)),
          ListTile(title: Text('Planted on'), subtitle: Text(tree.date)),
          ListTile(title: Text('Watering History')),
          for (String w in tree.waterings) ListTile(title: Text(w)),
          ElevatedButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => WateringScreen(tree)))
                  .then((value) => setState(() {}));
            },
            child: Text('Record Watering'),
          ),
          ElevatedButton(
            onPressed: () {
              trees.remove(tree);
              Navigator.pop(context);
            },
            child: Text('Delete Tree'),
          ),
        ],
      ),
    );
  }
}
