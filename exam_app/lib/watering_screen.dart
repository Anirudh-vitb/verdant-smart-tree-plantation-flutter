// MODULE 8: Record Watering
import 'package:flutter/material.dart';
import 'data.dart';

class WateringScreen extends StatelessWidget {
  final Tree tree;
  final litresC = TextEditingController();
  WateringScreen(this.tree);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Record Watering')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Tree: ${tree.name}', style: TextStyle(fontSize: 18)),
            TextField(
              controller: litresC,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Water given (litres)'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (litresC.text.isEmpty) return;
                DateTime d = DateTime.now();
                tree.waterings.add('${litresC.text} litres on ${d.day}/${d.month}/${d.year}');
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
