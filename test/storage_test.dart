import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:verdant_smart_tree_plantation_flutter/providers/plantation_actions.dart';
import 'package:verdant_smart_tree_plantation_flutter/services/local_storage_service.dart';

import 'test_helpers.dart';

void main() {
  group('LocalStorageService', () {
    test('returns empty lists when nothing is stored', () {
      final storage = LocalStorageService(InMemoryStore());
      expect(storage.loadTrees().items, isEmpty);
      expect(storage.loadTasks().items, isEmpty);
      expect(storage.loadWaterings().items, isEmpty);
      expect(storage.isInitialized, isFalse);
    });

    test('saves and loads trees and tasks', () async {
      final storage = LocalStorageService(InMemoryStore());
      await storage.saveTrees([makeTree(id: 'a'), makeTree(id: 'b')]);
      await storage.saveTasks([makeTask(treeId: 'a')]);

      expect(storage.loadTrees().items.map((t) => t.id), ['a', 'b']);
      expect(storage.loadTasks().items.single.treeId, 'a');
    });

    test('skips corrupted records but keeps valid ones', () {
      final store = InMemoryStore({
        LocalStorageService.treesKey: jsonEncode([
          makeTree(id: 'good').toJson(),
          {'id': 'broken'},
          'not even a map',
          makeTree(id: 'good2').toJson()..['health'] = 'unknown',
        ]),
      });
      final result = LocalStorageService(store).loadTrees();
      expect(result.items.map((t) => t.id), ['good']);
      expect(result.skipped, 3);
    });

    test('handles stored text that is not valid JSON', () {
      final store = InMemoryStore({LocalStorageService.tasksKey: '{oops'});
      final result = LocalStorageService(store).loadTasks();
      expect(result.items, isEmpty);
      expect(result.skipped, 1);
    });

    test('handles JSON that is not a list', () {
      final store = InMemoryStore({
        LocalStorageService.wateringsKey: '{"a":1}',
      });
      expect(LocalStorageService(store).loadWaterings().items, isEmpty);
    });
  });

  group('SharedPreferences persistence', () {
    test('data written by one instance is read by the next', () async {
      SharedPreferences.setMockInitialValues({});
      final first = LocalStorageService(
        SharedPreferencesStore(await SharedPreferences.getInstance()),
      );
      await first.saveTrees([makeTree(id: 'persisted')]);

      // Simulates reopening the app: a new service over the same preferences.
      final second = LocalStorageService(
        SharedPreferencesStore(await SharedPreferences.getInstance()),
      );
      expect(second.loadTrees().items.single.id, 'persisted');
    });
  });

  group('First-run sample data', () {
    test('is written once and marked as demo data', () async {
      final storage = LocalStorageService(InMemoryStore());
      await PlantationActions.seedIfFirstRun(storage, fixedNow);

      final trees = storage.loadTrees().items;
      expect(trees, isNotEmpty);
      expect(trees.every((t) => t.isDemo), isTrue);
      expect(storage.loadTasks().items.every((t) => t.isDemo), isTrue);
      expect(storage.isInitialized, isTrue);

      // Deleting everything and restarting must not re-seed.
      await storage.saveTrees([]);
      await PlantationActions.seedIfFirstRun(storage, fixedNow);
      expect(storage.loadTrees().items, isEmpty);
    });
  });
}
