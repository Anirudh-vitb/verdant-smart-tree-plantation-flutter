import 'package:flutter_test/flutter_test.dart';
import 'package:verdant_smart_tree_plantation_flutter/models/maintenance_task.dart';
import 'package:verdant_smart_tree_plantation_flutter/models/tree.dart';
import 'package:verdant_smart_tree_plantation_flutter/providers/maintenance_provider.dart';
import 'package:verdant_smart_tree_plantation_flutter/providers/plantation_actions.dart';
import 'package:verdant_smart_tree_plantation_flutter/providers/tree_provider.dart';
import 'package:verdant_smart_tree_plantation_flutter/services/local_storage_service.dart';

import 'test_helpers.dart';

void main() {
  late LocalStorageService storage;
  late TreeProvider trees;
  late MaintenanceProvider maintenance;

  setUp(() {
    storage = LocalStorageService(InMemoryStore());
    trees = TreeProvider(storage, clock: clock)..load();
    maintenance = MaintenanceProvider(storage, clock: clock)..load();
  });

  Future<Tree> addMango() => trees.addTree(
    name: '  Library Mango ',
    species: 'Mango',
    scientificName: 'Mangifera indica',
    plantedOn: DateTime(2026, 1, 10, 15, 45),
    location: 'Library lawn',
    health: HealthStatus.healthy,
  );

  group('TreeProvider', () {
    test(
      'adds a tree with trimmed fields, timestamps and a unique id',
      () async {
        var notified = 0;
        trees.addListener(() => notified++);

        final tree = await addMango();
        final second = await addMango();

        expect(trees.trees, hasLength(2));
        expect(tree.id, isNot(second.id));
        expect(tree.name, 'Library Mango');
        expect(tree.plantedOn, DateTime(2026, 1, 10)); // Time stripped.
        expect(tree.createdAt, fixedNow);
        expect(notified, 2);
      },
    );

    test('added trees persist to storage', () async {
      final tree = await addMango();
      final reopened = TreeProvider(storage)..load();
      expect(reopened.treeById(tree.id)?.name, 'Library Mango');
    });

    test('edits an existing tree', () async {
      final tree = await addMango();
      await trees.updateTree(
        tree.copyWith(name: 'Old Mango', health: HealthStatus.critical),
      );
      final updated = trees.treeById(tree.id)!;
      expect(updated.name, 'Old Mango');
      expect(updated.health, HealthStatus.critical);
      expect(trees.trees, hasLength(1));
    });

    test('updating a deleted tree throws', () async {
      expect(() => trees.updateTree(makeTree(id: 'missing')), throwsStateError);
    });

    test('deletes a tree and its watering history', () async {
      final tree = await addMango();
      await trees.recordWatering(treeId: tree.id, wateredAt: fixedNow);
      await trees.deleteTree(tree.id);

      expect(trees.trees, isEmpty);
      expect(trees.waterings, isEmpty);
      expect(storage.loadWaterings().items, isEmpty);
    });

    test('records watering and reports last watered time', () async {
      final tree = await addMango();
      final earlier = fixedNow.subtract(const Duration(days: 2));
      await trees.recordWatering(
        treeId: tree.id,
        wateredAt: earlier,
        quantityLitres: 5,
      );
      await trees.recordWatering(
        treeId: tree.id,
        wateredAt: fixedNow,
        durationMinutes: 10,
      );

      final history = trees.wateringsFor(tree.id);
      expect(history, hasLength(2));
      expect(history.first.wateredAt, fixedNow); // Newest first.
      expect(trees.lastWatered(tree.id), fixedNow);
      expect(storage.loadWaterings().items, hasLength(2));
    });

    test('cannot record watering for an unknown tree', () {
      expect(
        () => trees.recordWatering(treeId: 'nope', wateredAt: fixedNow),
        throwsStateError,
      );
    });

    test('does not change state when saving fails', () async {
      final failing = TreeProvider(LocalStorageService(FailingStore()))..load();
      await expectLater(
        failing.addTree(
          name: 'X',
          species: 'Neem',
          plantedOn: fixedNow,
          location: 'Somewhere',
          health: HealthStatus.healthy,
        ),
        throwsA(isA<StorageException>()),
      );
      expect(failing.trees, isEmpty);
    });

    test('reports a warning when stored records are damaged', () {
      final store = InMemoryStore({LocalStorageService.treesKey: '[{"id":1}]'});
      final provider = TreeProvider(LocalStorageService(store))..load();
      expect(provider.trees, isEmpty);
      expect(provider.loadWarning, contains('1 saved record'));
    });
  });

  group('MaintenanceProvider', () {
    test('creates a pending task linked to a tree', () async {
      final tree = await addMango();
      final task = await maintenance.addTask(
        title: 'Fertilize',
        type: TaskType.fertilizing,
        dueDate: DateTime(2026, 6, 20, 9),
        treeId: tree.id,
        notes: ' compost ',
      );

      expect(task.isCompleted, isFalse);
      expect(task.dueDate, DateTime(2026, 6, 20));
      expect(task.notes, 'compost');
      expect(maintenance.pendingTasks.single.id, task.id);
      expect(maintenance.tasksForTree(tree.id).single.id, task.id);
      expect(storage.loadTasks().items, hasLength(1));
    });

    test('completes and re-opens a task', () async {
      final task = await maintenance.addTask(
        title: 'Prune',
        type: TaskType.pruning,
        dueDate: DateTime(2026, 6, 20),
      );

      await maintenance.setCompleted(task.id, true);
      final done = maintenance.taskById(task.id)!;
      expect(done.isCompleted, isTrue);
      expect(done.completedAt, fixedNow);
      expect(maintenance.pendingTasks, isEmpty);
      expect(maintenance.completedTasks, hasLength(1));

      await maintenance.setCompleted(task.id, false);
      expect(maintenance.taskById(task.id)!.completedAt, isNull);
      expect(maintenance.pendingTasks, hasLength(1));
    });

    test('edits and deletes a task', () async {
      final task = await maintenance.addTask(
        title: 'Inspect',
        type: TaskType.inspection,
        dueDate: DateTime(2026, 6, 20),
      );
      await maintenance.updateTask(task.copyWith(title: 'Inspect leaves'));
      expect(maintenance.taskById(task.id)!.title, 'Inspect leaves');

      await maintenance.deleteTask(task.id);
      expect(maintenance.tasks, isEmpty);
    });

    test('orders pending tasks by due date and filters watering', () async {
      await maintenance.addTask(
        title: 'Later',
        type: TaskType.watering,
        dueDate: DateTime(2026, 7, 1),
      );
      await maintenance.addTask(
        title: 'Prune',
        type: TaskType.pruning,
        dueDate: DateTime(2026, 6, 1),
      );
      await maintenance.addTask(
        title: 'Soon',
        type: TaskType.watering,
        dueDate: DateTime(2026, 6, 16),
      );

      expect(maintenance.pendingTasks.map((t) => t.title), [
        'Prune',
        'Soon',
        'Later',
      ]);
      expect(maintenance.upcomingWatering().map((t) => t.title), [
        'Soon',
        'Later',
      ]);
    });
  });

  group('PlantationActions', () {
    test(
      'removing sample data also removes user records linked to sample trees',
      () async {
        final actions = PlantationActions(trees, maintenance);
        await actions.restoreDemoData(fixedNow);
        final sampleTree = trees.trees.firstWhere((t) => t.isDemo);
        await trees.recordWatering(treeId: sampleTree.id, wateredAt: fixedNow);
        await maintenance.addTask(
          title: 'Mine, on a sample tree',
          type: TaskType.general,
          dueDate: fixedNow,
          treeId: sampleTree.id,
        );
        final standalone = await maintenance.addTask(
          title: 'Mine, plantation-wide',
          type: TaskType.general,
          dueDate: fixedNow,
        );

        await actions.removeDemoData();

        expect(trees.trees, isEmpty);
        expect(trees.waterings, isEmpty);
        expect(maintenance.tasks.single.id, standalone.id);
      },
    );

    test('deleting a tree also deletes its tasks', () async {
      final tree = await addMango();
      await maintenance.addTask(
        title: 'A',
        type: TaskType.general,
        dueDate: fixedNow,
        treeId: tree.id,
      );
      await maintenance.addTask(
        title: 'B',
        type: TaskType.general,
        dueDate: fixedNow,
      );

      await PlantationActions(trees, maintenance).deleteTree(tree.id);

      expect(trees.trees, isEmpty);
      expect(maintenance.tasks.map((t) => t.title), ['B']);
    });

    test('removes only sample data and can restore it', () async {
      final actions = PlantationActions(trees, maintenance);
      await actions.restoreDemoData(fixedNow);
      final mine = await addMango();
      expect(actions.hasDemoData, isTrue);

      await actions.removeDemoData();
      expect(actions.hasDemoData, isFalse);
      expect(trees.trees.single.id, mine.id);
      expect(maintenance.tasks, isEmpty);
      expect(trees.waterings, isEmpty);

      await actions.restoreDemoData(fixedNow);
      await actions.restoreDemoData(fixedNow); // Must not duplicate.
      expect(trees.trees.where((t) => t.isDemo), hasLength(5));
    });
  });
}
