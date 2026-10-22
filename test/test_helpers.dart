import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verdant_smart_tree_plantation_flutter/app.dart';
import 'package:verdant_smart_tree_plantation_flutter/models/maintenance_task.dart';
import 'package:verdant_smart_tree_plantation_flutter/models/tree.dart';
import 'package:verdant_smart_tree_plantation_flutter/services/local_storage_service.dart';
import 'package:verdant_smart_tree_plantation_flutter/services/species_service.dart';

final DateTime fixedNow = DateTime(2026, 6, 15, 10, 30);

DateTime clock() => fixedNow;

Tree makeTree({
  String id = 't1',
  String name = 'Library Mango',
  String species = 'Mango',
  String? scientificName = 'Mangifera indica',
  DateTime? plantedOn,
  HealthStatus health = HealthStatus.healthy,
  DateTime? createdAt,
  bool isDemo = false,
}) {
  final created = createdAt ?? fixedNow;
  return Tree(
    id: id,
    name: name,
    species: species,
    scientificName: scientificName,
    plantedOn: plantedOn ?? DateTime(2026, 1, 10),
    location: 'Library lawn',
    health: health,
    notes: 'Some notes',
    createdAt: created,
    updatedAt: created,
    isDemo: isDemo,
  );
}

MaintenanceTask makeTask({
  String id = 'k1',
  String title = 'Water saplings',
  TaskType type = TaskType.watering,
  String? treeId,
  DateTime? dueDate,
  bool isCompleted = false,
  bool isDemo = false,
}) {
  return MaintenanceTask(
    id: id,
    title: title,
    type: type,
    treeId: treeId,
    dueDate: dueDate ?? DateTime(2026, 6, 16),
    isCompleted: isCompleted,
    completedAt: isCompleted ? fixedNow : null,
    createdAt: fixedNow,
    updatedAt: fixedNow,
    isDemo: isDemo,
  );
}

/// Store whose writes always fail, to test error handling.
class FailingStore extends InMemoryStore {
  @override
  Future<void> write(String key, String value) async {
    throw StorageException('Disk full');
  }
}

/// Pumps the full app on a phone-sized screen with in-memory storage.
Future<LocalStorageService> pumpApp(
  WidgetTester tester, {
  LocalStorageService? storage,
  Size size = const Size(420, 900),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final store = storage ?? LocalStorageService(InMemoryStore());
  await tester.pumpWidget(
    VerdantApp(storage: store, speciesService: const LocalSpeciesService()),
  );
  await tester.pumpAndSettle();
  return store;
}

/// The main vertical list on the current screen (not a text field).
final Finder mainScrollable = find
    .byWidgetPredicate(
      (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
    )
    .first;

/// Scrolls the main list until [finder] is built and visible.
Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 200, scrollable: mainScrollable);
  await tester.pumpAndSettle();
}

/// Scrolls until [finder] is visible, then taps it.
Future<void> scrollAndTap(WidgetTester tester, Finder finder) async {
  await scrollTo(tester, finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
