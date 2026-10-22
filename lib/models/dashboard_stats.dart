import 'maintenance_task.dart';
import 'tree.dart';
import 'watering_record.dart';

/// Summary numbers shown on the dashboard.
///
/// Computed from the real data every time it changes, never hardcoded.
class DashboardStats {
  const DashboardStats({
    required this.totalTrees,
    required this.healthy,
    required this.needsAttention,
    required this.critical,
    required this.pendingTasks,
    required this.overdueTasks,
    required this.wateringsThisWeek,
  });

  factory DashboardStats.compute({
    required List<Tree> trees,
    required List<MaintenanceTask> tasks,
    required List<WateringRecord> waterings,
    required DateTime now,
  }) {
    int countHealth(HealthStatus status) =>
        trees.where((tree) => tree.health == status).length;

    final weekAgo = now.subtract(const Duration(days: 7));
    final pending = tasks.where((task) => !task.isCompleted);

    return DashboardStats(
      totalTrees: trees.length,
      healthy: countHealth(HealthStatus.healthy),
      needsAttention: countHealth(HealthStatus.needsAttention),
      critical: countHealth(HealthStatus.critical),
      pendingTasks: pending.length,
      overdueTasks: pending.where((task) => task.isOverdue(now)).length,
      wateringsThisWeek: waterings
          .where(
            (w) => w.wateredAt.isAfter(weekAgo) && !w.wateredAt.isAfter(now),
          )
          .length,
    );
  }

  final int totalTrees;
  final int healthy;
  final int needsAttention;
  final int critical;
  final int pendingTasks;
  final int overdueTasks;
  final int wateringsThisWeek;

  /// Trees that are either "Needs Attention" or "Critical".
  int get requiringAttention => needsAttention + critical;

  /// Percentage (0-100) of trees that are healthy.
  int get healthyPercent =>
      totalTrees == 0 ? 0 : (healthy * 100 / totalTrees).round();
}
