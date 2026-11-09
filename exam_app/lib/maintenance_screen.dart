// MODULE 9: Maintenance (task list: complete with checkbox, delete)
import 'package:flutter/material.dart';
import 'data.dart';
import 'add_task_screen.dart';

class MaintenanceScreen extends StatefulWidget {
  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Maintenance')),
      body: ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, i) {
          return Card(
            child: CheckboxListTile(
              title: Text(tasks[i].title),
              subtitle: Text(tasks[i].type),
              value: tasks[i].done,
              onChanged: (value) => setState(() => tasks[i].done = value!),
              secondary: IconButton(
                icon: Icon(Icons.delete),
                onPressed: () => setState(() => tasks.removeAt(i)),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => AddTaskScreen()))
              .then((value) => setState(() {}));
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
