// MODULE 4: App data (shared lists used by every screen)
import 'package:flutter/material.dart';

import 'task.dart';
import 'tree.dart';

List<Tree> trees = [
  Tree(
    name: 'Gate Neem',
    species: 'Neem',
    location: 'Main gate',
    health: 'Healthy',
    plantedOn: DateTime(2026, 6, 5),
  ),
  Tree(
    name: 'Library Mango',
    species: 'Mango',
    location: 'Library lawn',
    health: 'Needs Attention',
    plantedOn: DateTime(2026, 7, 10),
  ),
  Tree(
    name: 'Parking Peepal',
    species: 'Peepal',
    location: 'Staff parking',
    health: 'Critical',
    plantedOn: DateTime(2026, 8, 20),
  ),
];

List<Task> tasks = [
  Task(title: 'Water new saplings', type: 'Watering', dueDate: DateTime(2026, 11, 12)),
  Task(title: 'Add compost to mango', type: 'Fertilizing', dueDate: DateTime(2026, 11, 15)),
];

const List<String> speciesList = ['Neem', 'Mango', 'Peepal', 'Banyan', 'Teak', 'Jamun'];
const List<String> healthList = ['Healthy', 'Needs Attention', 'Critical'];
const List<String> taskTypes = ['Watering', 'Fertilizing', 'Pruning', 'Inspection'];

String formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

Color healthColor(String health) {
  if (health == 'Healthy') return Colors.green;
  if (health == 'Needs Attention') return Colors.orange;
  return Colors.red;
}
