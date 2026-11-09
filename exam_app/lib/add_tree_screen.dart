// MODULE 6: Add Tree (form with text fields, dropdowns and date picker)
import 'package:flutter/material.dart';
import 'data.dart';

class AddTreeScreen extends StatefulWidget {
  @override
  State<AddTreeScreen> createState() => _AddTreeScreenState();
}

class _AddTreeScreenState extends State<AddTreeScreen> {
  var nameC = TextEditingController();
  var locationC = TextEditingController();
  String species = 'Neem';
  String health = 'Healthy';
  String date = '';

  void pickDate() async {
    DateTime? d = await showDatePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime.now());
    if (d != null) {
      setState(() => date = '${d.day}/${d.month}/${d.year}');
    }
  }

  void save() {
    if (nameC.text.isEmpty || locationC.text.isEmpty || date.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please fill all fields')));
      return;
    }
    trees.add(Tree(nameC.text, species, locationC.text, health, date));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Tree')),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          TextField(controller: nameC, decoration: InputDecoration(labelText: 'Tree name')),
          TextField(controller: locationC, decoration: InputDecoration(labelText: 'Location')),
          SizedBox(height: 16),
          Text('Species'),
          DropdownButton<String>(
            value: species,
            isExpanded: true,
            items: ['Neem', 'Mango', 'Peepal', 'Banyan', 'Teak']
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (value) => setState(() => species = value!),
          ),
          Text('Health'),
          DropdownButton<String>(
            value: health,
            isExpanded: true,
            items: ['Healthy', 'Needs Attention', 'Critical']
                .map((h) => DropdownMenuItem(value: h, child: Text(h)))
                .toList(),
            onChanged: (value) => setState(() => health = value!),
          ),
          ListTile(
            title: Text(date.isEmpty ? 'Select planting date' : 'Planted on: $date'),
            trailing: Icon(Icons.calendar_today),
            onTap: pickDate,
          ),
          ElevatedButton(onPressed: save, child: Text('Save Tree')),
        ],
      ),
    );
  }
}
