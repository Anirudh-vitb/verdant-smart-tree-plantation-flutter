// MODULE 9: Add tree page (form, dropdown, date picker, validation)
import 'package:flutter/material.dart';

import '../models/plantation_data.dart';
import '../models/tree.dart';

class AddTreeScreen extends StatefulWidget {
  const AddTreeScreen({super.key});

  @override
  State<AddTreeScreen> createState() => _AddTreeScreenState();
}

class _AddTreeScreenState extends State<AddTreeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  String? _species;
  String _health = 'Healthy';
  DateTime _plantedOn = DateTime.now();

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _plantedOn,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _plantedOn = picked);
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      trees.add(Tree(
        name: _nameController.text,
        species: _species!,
        location: _locationController.text,
        health: _health,
        plantedOn: _plantedOn,
      ));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tree added successfully')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Tree')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Tree name', border: OutlineInputBorder()),
              validator: (value) => value!.isEmpty ? 'Enter tree name' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _species,
              decoration: const InputDecoration(labelText: 'Species', border: OutlineInputBorder()),
              items: speciesList
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (value) => setState(() => _species = value),
              validator: (value) => value == null ? 'Select a species' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: 'Location', border: OutlineInputBorder()),
              validator: (value) => value!.isEmpty ? 'Enter location' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _health,
              decoration: const InputDecoration(labelText: 'Health', border: OutlineInputBorder()),
              items: healthList
                  .map((h) => DropdownMenuItem(value: h, child: Text(h)))
                  .toList(),
              onChanged: (value) => setState(() => _health = value!),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text('Planted on: ${formatDate(_plantedOn)}'),
              trailing: TextButton(onPressed: _pickDate, child: const Text('Change')),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _save, child: const Text('Save Tree')),
          ],
        ),
      ),
    );
  }
}
