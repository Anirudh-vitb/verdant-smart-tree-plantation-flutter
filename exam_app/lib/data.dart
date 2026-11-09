// MODULE 2: Data (models + lists shared by all screens)

class Tree {
  String name, species, location, health, date;
  List<String> waterings = [];

  Tree(this.name, this.species, this.location, this.health, this.date);
}

class Task {
  String title, type;
  bool done = false;

  Task(this.title, this.type);
}

List<Tree> trees = [
  Tree('Gate Neem', 'Neem', 'Main gate', 'Healthy', '5/6/2026'),
  Tree('Library Mango', 'Mango', 'Library lawn', 'Needs Attention', '10/7/2026'),
  Tree('Parking Peepal', 'Peepal', 'Staff parking', 'Critical', '20/8/2026'),
];

List<Task> tasks = [
  Task('Water new saplings', 'Watering'),
  Task('Add compost to mango', 'Fertilizing'),
];
