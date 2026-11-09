// MODULE 3: Maintenance task model
class Task {
  String title;
  String type; // 'Watering', 'Fertilizing', 'Pruning' or 'Inspection'
  DateTime dueDate;
  bool isDone;

  Task({
    required this.title,
    required this.type,
    required this.dueDate,
    this.isDone = false,
  });
}
