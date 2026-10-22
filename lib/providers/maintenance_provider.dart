import 'package:flutter/foundation.dart';

import '../core/utils/formatters.dart';
import '../data/sample_data.dart';
import '../models/maintenance_task.dart';
import '../services/local_storage_service.dart';

/// Owns the list of maintenance tasks.
class MaintenanceProvider extends ChangeNotifier {
  MaintenanceProvider(this._storage, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final LocalStorageService _storage;
  final DateTime Function() _clock;

  List<MaintenanceTask> _tasks = const [];
  int _skippedOnLoad = 0;

  List<MaintenanceTask> get tasks => List.unmodifiable(_tasks);

  int get skippedOnLoad => _skippedOnLoad;

  bool get hasDemoData => _tasks.any((t) => t.isDemo);

  void load() {
    final result = _storage.loadTasks();
    _tasks = result.items;
    _skippedOnLoad = result.skipped;
    notifyListeners();
  }

  /// Pending tasks, soonest due first.
  List<MaintenanceTask> get pendingTasks =>
      _tasks.where((t) => !t.isCompleted).toList()
        ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

  /// Completed tasks, most recently completed first.
  List<MaintenanceTask> get completedTasks =>
      _tasks.where((t) => t.isCompleted).toList()..sort(
        (a, b) => (b.completedAt ?? b.updatedAt).compareTo(
          a.completedAt ?? a.updatedAt,
        ),
      );

  /// Pending watering tasks for the dashboard, soonest first.
  List<MaintenanceTask> upcomingWatering({int limit = 3}) => pendingTasks
      .where((t) => t.type == TaskType.watering)
      .take(limit)
      .toList();

  List<MaintenanceTask> tasksForTree(String treeId) {
    return _tasks.where((t) => t.treeId == treeId).toList()..sort((a, b) {
      if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
      return a.dueDate.compareTo(b.dueDate);
    });
  }

  MaintenanceTask? taskById(String id) {
    for (final task in _tasks) {
      if (task.id == id) return task;
    }
    return null;
  }

  Future<MaintenanceTask> addTask({
    required String title,
    required TaskType type,
    required DateTime dueDate,
    String? treeId,
    String notes = '',
  }) async {
    final now = _clock();
    final task = MaintenanceTask(
      id: IdGenerator.next('task'),
      title: title.trim(),
      type: type,
      treeId: treeId,
      dueDate: Formatters.dateOnly(dueDate),
      notes: notes.trim(),
      createdAt: now,
      updatedAt: now,
    );
    await _save([..._tasks, task]);
    return task;
  }

  Future<void> updateTask(MaintenanceTask updated) async {
    if (taskById(updated.id) == null) {
      throw StateError('Task ${updated.id} no longer exists.');
    }
    final stamped = updated.copyWith(updatedAt: _clock());
    await _save([
      for (final task in _tasks) task.id == updated.id ? stamped : task,
    ]);
  }

  /// Marks a task completed (or re-opens it when [completed] is false).
  Future<void> setCompleted(String id, bool completed) async {
    final task = taskById(id);
    if (task == null) throw StateError('Task $id no longer exists.');
    final now = _clock();
    await updateTask(
      completed
          ? task.copyWith(isCompleted: true, completedAt: now)
          : task.copyWith(isCompleted: false, clearCompletedAt: true),
    );
  }

  Future<void> deleteTask(String id) =>
      _save(_tasks.where((t) => t.id != id).toList());

  /// Called when a tree is deleted so no task points at a missing tree.
  Future<void> deleteTasksForTree(String treeId) async {
    final remaining = _tasks.where((t) => t.treeId != treeId).toList();
    if (remaining.length != _tasks.length) await _save(remaining);
  }

  /// Removes sample tasks and any task linked to a sample tree in
  /// [demoTreeIds], so no task is left pointing at a deleted tree.
  Future<void> removeDemoData({Set<String> demoTreeIds = const {}}) => _save(
    _tasks.where((t) => !t.isDemo && !demoTreeIds.contains(t.treeId)).toList(),
  );

  Future<void> addDemoData(SampleData sample) {
    final ids = _tasks.map((t) => t.id).toSet();
    return _save([
      ..._tasks,
      ...sample.tasks.where((t) => !ids.contains(t.id)),
    ]);
  }

  Future<void> _save(List<MaintenanceTask> tasks) async {
    await _storage.saveTasks(tasks);
    _tasks = tasks;
    notifyListeners();
  }
}
