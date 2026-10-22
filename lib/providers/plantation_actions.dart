import '../data/sample_data.dart';
import '../services/local_storage_service.dart';
import 'maintenance_provider.dart';
import 'tree_provider.dart';

/// Operations that touch both providers, kept in one place so the screens
/// don't have to remember the correct order of steps.
class PlantationActions {
  const PlantationActions(this.trees, this.maintenance);

  final TreeProvider trees;
  final MaintenanceProvider maintenance;

  /// Deletes a tree together with its tasks and watering history.
  Future<void> deleteTree(String treeId) async {
    await maintenance.deleteTasksForTree(treeId);
    await trees.deleteTree(treeId);
  }

  bool get hasDemoData => trees.hasDemoData || maintenance.hasDemoData;

  /// Removes sample records and everything linked to sample trees.
  Future<void> removeDemoData() async {
    await maintenance.removeDemoData(demoTreeIds: trees.demoTreeIds);
    await trees.removeDemoData();
  }

  Future<void> restoreDemoData(DateTime now) async {
    final sample = SampleData.build(now);
    await trees.addDemoData(sample);
    await maintenance.addDemoData(sample);
  }

  /// Writes the sample records the very first time the app is opened.
  static Future<void> seedIfFirstRun(
    LocalStorageService storage,
    DateTime now,
  ) async {
    if (storage.isInitialized) return;
    final sample = SampleData.build(now);
    await storage.saveTrees(sample.trees);
    await storage.saveTasks(sample.tasks);
    await storage.saveWaterings(sample.waterings);
    await storage.markInitialized();
  }
}
