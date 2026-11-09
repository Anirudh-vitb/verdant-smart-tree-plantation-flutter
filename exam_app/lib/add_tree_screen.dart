// MODULE 6: Add Tree (form with 5 text boxes and a save button)
import 'package:flutter/material.dart';
import 'data.dart';

class AddTreeScreen extends StatelessWidget {
  final nameC = TextEditingController();
  final speciesC = TextEditingController();
  final locationC = TextEditingController();
  final healthC = TextEditingController();
  final dateC = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Tree')),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          TextField(controller: nameC, decoration: InputDecoration(labelText: 'Tree name')),
          TextField(controller: speciesC, decoration: InputDecoration(labelText: 'Species')),
          TextField(controller: locationC, decoration: InputDecoration(labelText: 'Location')),
          TextField(controller: healthC, decoration: InputDecoration(labelText: 'Health')),
          TextField(controller: dateC, decoration: InputDecoration(labelText: 'Planting date')),
          ElevatedButton(
            onPressed: () {
              if (nameC.text.isEmpty) return;
              trees.add(Tree(nameC.text, speciesC.text, locationC.text, healthC.text, dateC.text));
              Navigator.pop(context);
            },
            child: Text('Save Tree'),
          ),
        ],
      ),
    );
  }
}
