import '../models/maintenance_task.dart';
import '../models/tree.dart';
import '../models/watering_record.dart';

/// Demonstration records shown on first launch.
///
/// Every record has `isDemo: true` so the user can remove them all from the
/// dashboard menu without touching their own data.
class SampleData {
  SampleData._(this.trees, this.tasks, this.waterings);

  final List<Tree> trees;
  final List<MaintenanceTask> tasks;
  final List<WateringRecord> waterings;

  factory SampleData.build(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    DateTime daysAgo(int days) => today.subtract(Duration(days: days));
    DateTime daysAhead(int days) => today.add(Duration(days: days));

    Tree tree(
      String id,
      String name,
      String species,
      String scientific,
      int plantedDaysAgo,
      String location,
      HealthStatus health,
      String notes,
    ) {
      final planted = daysAgo(plantedDaysAgo);
      return Tree(
        id: id,
        name: name,
        species: species,
        scientificName: scientific,
        plantedOn: planted,
        location: location,
        health: health,
        notes: notes,
        createdAt: planted,
        updatedAt: planted,
        isDemo: true,
      );
    }

    final trees = [
      tree(
        'demo-tree-1',
        'Campus Gate Neem',
        'Neem',
        'Azadirachta indica',
        210,
        'Main gate, Block A',
        HealthStatus.healthy,
        'Planted during the Van Mahotsav drive. Growing well.',
      ),
      tree(
        'demo-tree-2',
        'Library Mango',
        'Mango',
        'Mangifera indica',
        150,
        'Library lawn, north side',
        HealthStatus.needsAttention,
        'Leaves yellowing at the edges. Check soil nutrients.',
      ),
      tree(
        'demo-tree-3',
        'Hostel Gulmohar',
        'Gulmohar',
        'Delonix regia',
        95,
        'Boys hostel courtyard',
        HealthStatus.healthy,
        '',
      ),
      tree(
        'demo-tree-4',
        'Parking Peepal',
        'Peepal',
        'Ficus religiosa',
        60,
        'Staff parking, row 3',
        HealthStatus.critical,
        'Bark damage from vehicle contact. Tree guard required.',
      ),
      tree(
        'demo-tree-5',
        'Pond-side Jamun',
        'Jamun',
        'Syzygium cumini',
        30,
        'Near the rainwater pond',
        HealthStatus.healthy,
        'Young sapling, water every 2 days.',
      ),
    ];

    MaintenanceTask task(
      String id,
      String title,
      TaskType type,
      String? treeId,
      DateTime due, {
      bool done = false,
      String notes = '',
    }) {
      return MaintenanceTask(
        id: id,
        title: title,
        type: type,
        treeId: treeId,
        dueDate: due,
        notes: notes,
        isCompleted: done,
        completedAt: done ? due : null,
        createdAt: daysAgo(10),
        updatedAt: daysAgo(10),
        isDemo: true,
      );
    }

    final tasks = [
      task(
        'demo-task-1',
        'Water the Jamun sapling',
        TaskType.watering,
        'demo-tree-5',
        today,
      ),
      task(
        'demo-task-2',
        'Install tree guard',
        TaskType.general,
        'demo-tree-4',
        daysAhead(2),
        notes: 'Use the metal guards from the store room.',
      ),
      task(
        'demo-task-3',
        'Apply organic compost',
        TaskType.fertilizing,
        'demo-tree-2',
        daysAhead(4),
      ),
      task(
        'demo-task-4',
        'Weekly watering round',
        TaskType.watering,
        null,
        daysAhead(6),
        notes: 'All saplings planted in the last 3 months.',
      ),
      task(
        'demo-task-5',
        'Inspect leaves for pests',
        TaskType.inspection,
        'demo-tree-2',
        daysAgo(1),
      ),
      task(
        'demo-task-6',
        'Prune lower branches',
        TaskType.pruning,
        'demo-tree-1',
        daysAgo(5),
        done: true,
      ),
    ];

    WateringRecord watering(String id, String treeId, int ago, double litres) {
      return WateringRecord(
        id: id,
        treeId: treeId,
        wateredAt: daysAgo(ago).add(const Duration(hours: 8)),
        quantityLitres: litres,
        isDemo: true,
      );
    }

    final waterings = [
      watering('demo-water-1', 'demo-tree-5', 1, 5),
      watering('demo-water-2', 'demo-tree-5', 3, 5),
      watering('demo-water-3', 'demo-tree-1', 2, 15),
      watering('demo-water-4', 'demo-tree-3', 4, 10),
      watering('demo-water-5', 'demo-tree-2', 9, 12),
    ];

    return SampleData._(trees, tasks, waterings);
  }
}
