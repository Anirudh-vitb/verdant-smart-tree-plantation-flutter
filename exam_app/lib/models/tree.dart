// MODULE 2: Tree model
class Tree {
  String name;
  String species;
  String location;
  String health; // 'Healthy', 'Needs Attention' or 'Critical'
  DateTime plantedOn;
  List<DateTime> wateredOn = [];

  Tree({
    required this.name,
    required this.species,
    required this.location,
    required this.health,
    required this.plantedOn,
  });
}
