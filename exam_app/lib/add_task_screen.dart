// MODULE 10: Add Task (text field + dropdown)
import 'package:flutter/material.dart';
import 'data.dart';

class AddTaskScreen extends StatefulWidget {
  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  var titleC = TextEditingController();
  String type = 'Watering';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Task')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: titleC, decoration: InputDecoration(labelText: 'Task title')),
            DropdownButton<String>(
              value: type,
              isExpanded: true,
              items: ['Watering', 'Fertilizing', 'Pruning', 'Inspection']
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (value) => setState(() => type = value!),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleC.text.isEmpty) return;
                tasks.add(Task(titleC.text, type));
                Navigator.pop(context);
              },
              child: Text('Save Task'),
            ),
          ],
        ),
      ),
    );
  }
}
