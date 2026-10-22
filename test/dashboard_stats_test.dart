import 'package:flutter_test/flutter_test.dart';
import 'package:verdant_smart_tree_plantation_flutter/models/dashboard_stats.dart';
import 'package:verdant_smart_tree_plantation_flutter/models/tree.dart';
import 'package:verdant_smart_tree_plantation_flutter/models/watering_record.dart';

import 'test_helpers.dart';

void main() {
  test('all counts are zero with no data', () {
    final stats = DashboardStats.compute(
      trees: [],
      tasks: [],
      waterings: [],
      now: fixedNow,
    );
    expect(stats.totalTrees, 0);
    expect(stats.requiringAttention, 0);
    expect(stats.pendingTasks, 0);
    expect(stats.healthyPercent, 0);
  });

  test('counts trees by health and tasks by status', () {
    final stats = DashboardStats.compute(
      trees: [
        makeTree(id: '1'),
        makeTree(id: '2'),
        makeTree(id: '3', health: HealthStatus.needsAttention),
        makeTree(id: '4', health: HealthStatus.critical),
      ],
      tasks: [
        makeTask(id: 'a', dueDate: DateTime(2026, 6, 20)),
        makeTask(id: 'b', dueDate: DateTime(2026, 6, 10)), // Overdue.
        makeTask(id: 'c', isCompleted: true, dueDate: DateTime(2026, 6, 1)),
      ],
      waterings: [
        WateringRecord(
          id: 'w1',
          treeId: '1',
          wateredAt: fixedNow.subtract(const Duration(days: 1)),
        ),
        WateringRecord(
          id: 'w2',
          treeId: '1',
          wateredAt: fixedNow.subtract(const Duration(days: 6)),
        ),
        WateringRecord(
          id: 'w3',
          treeId: '1',
          wateredAt: fixedNow.subtract(const Duration(days: 20)),
        ),
      ],
      now: fixedNow,
    );

    expect(stats.totalTrees, 4);
    expect(stats.healthy, 2);
    expect(stats.needsAttention, 1);
    expect(stats.critical, 1);
    expect(stats.requiringAttention, 2);
    expect(stats.healthyPercent, 50);
    expect(stats.pendingTasks, 2);
    expect(stats.overdueTasks, 1);
    expect(stats.wateringsThisWeek, 2);
  });
}
