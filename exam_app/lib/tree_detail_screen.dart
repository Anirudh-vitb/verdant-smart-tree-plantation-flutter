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
  void deleteTree() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete this tree?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('No')),
          TextButton(
            onPressed: () {
              trees.remove(widget.tree);
              Navigator.pop(context); // close the dialog
              Navigator.pop(context); // go back to the list
            },
            child: Text('Yes'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Tree tree = widget.tree;

    return Scaffold(
      appBar: AppBar(
        title: Text(tree.name),
        actions: [IconButton(icon: Icon(Icons.delete), onPressed: deleteTree)],
      ),
      body: ListView(
        children: [
          ListTile(title: Text('Species'), subtitle: Text(tree.species)),
          ListTile(title: Text('Location'), subtitle: Text(tree.location)),
          ListTile(title: Text('Health'), subtitle: Text(tree.health)),
          ListTile(title: Text('Planted on'), subtitle: Text(tree.date)),
          ListTile(title: Text('Watering History', style: TextStyle(fontWeight: FontWeight.bold))),
          for (String w in tree.waterings)
            ListTile(leading: Icon(Icons.water_drop, color: Colors.blue), title: Text(w)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => WateringScreen(tree)))
              .then((value) => setState(() {}));
        },
        icon: Icon(Icons.water_drop),
        label: Text('Record Watering'),
      ),
    );
  }
}
