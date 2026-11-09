// MODULE 11: Maintenance page (task list, checkbox, add-task dialog)
import 'package:flutter/material.dart';

import '../models/plantation_data.dart';
import '../models/task.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  void _addTask() {
    final titleController = TextEditingController();
    String type = taskTypes[0];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Task title'),
            ),
            DropdownButtonFormField<String>(
              initialValue: type,
              items: taskTypes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (value) => type = value!,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isEmpty) return;
              setState(() {
                tasks.add(Task(
                  title: titleController.text,
                  type: type,
                  dueDate: DateTime.now().add(const Duration(days: 1)),
                ));
              });
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending = tasks.where((t) => !t.isDone).length;
    return Scaffold(
      appBar: AppBar(title: Text('Maintenance ($pending pending)')),
      body: tasks.isEmpty
          ? const Center(child: Text('No tasks yet'))
          : ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return Card(
                  child: CheckboxListTile(
                    value: task.isDone,
                    onChanged: (value) => setState(() => task.isDone = value!),
                    title: Text(
                      task.title,
                      style: TextStyle(
                        decoration: task.isDone ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    subtitle: Text('${task.type} • Due ${formatDate(task.dueDate)}'),
                    secondary: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => setState(() => tasks.removeAt(index)),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTask,
        child: const Icon(Icons.add_task),
      ),
    );
  }
}
