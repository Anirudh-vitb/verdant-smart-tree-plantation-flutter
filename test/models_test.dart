import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:verdant_smart_tree_plantation_flutter/models/maintenance_task.dart';
import 'package:verdant_smart_tree_plantation_flutter/models/tree.dart';
import 'package:verdant_smart_tree_plantation_flutter/models/watering_record.dart';

import 'test_helpers.dart';

void main() {
  group('Tree serialization', () {
    test('round-trips through JSON without losing data', () {
      final tree = makeTree(health: HealthStatus.critical, isDemo: true);
      final decoded = Tree.fromJson(
        jsonDecode(jsonEncode(tree.toJson())) as Map<String, dynamic>,
      );

      expect(decoded.id, tree.id);
      expect(decoded.name, tree.name);
      expect(decoded.species, tree.species);
      expect(decoded.scientificName, tree.scientificName);
      expect(decoded.plantedOn, tree.plantedOn);
      expect(decoded.location, tree.location);
      expect(decoded.health, HealthStatus.critical);
      expect(decoded.notes, tree.notes);
      expect(decoded.createdAt, tree.createdAt);
      expect(decoded.updatedAt, tree.updatedAt);
      expect(decoded.isDemo, isTrue);
    });

    test('uses defaults for optional fields that are missing', () {
      final json = makeTree().toJson()
        ..remove('notes')
        ..remove('isDemo')
        ..remove('scientificName');
      final tree = Tree.fromJson(json);
      expect(tree.notes, '');
      expect(tree.isDemo, isFalse);
      expect(tree.scientificName, isNull);
    });

    test('rejects an unknown health status', () {
      final json = makeTree().toJson()..['health'] = 'dead';
      expect(() => Tree.fromJson(json), throwsFormatException);
    });

    test('rejects records missing required fields', () {
      final json = makeTree().toJson()..remove('species');
      expect(() => Tree.fromJson(json), throwsA(isA<TypeError>()));
    });

    test('copyWith keeps id and creation time', () {
      final tree = makeTree();
      final edited = tree.copyWith(
        name: 'New name',
        health: HealthStatus.needsAttention,
      );
      expect(edited.id, tree.id);
      expect(edited.createdAt, tree.createdAt);
      expect(edited.name, 'New name');
      expect(edited.health, HealthStatus.needsAttention);
      expect(edited.species, tree.species);
    });

    test('ageInDays is never negative', () {
      final tree = makeTree(plantedOn: DateTime(2026, 6, 1));
      expect(tree.ageInDays(DateTime(2026, 6, 11)), 10);
      expect(tree.ageInDays(DateTime(2026, 5, 1)), 0);
    });
  });

  group('MaintenanceTask', () {
    test('round-trips through JSON', () {
      final task = makeTask(
        treeId: 't1',
        isCompleted: true,
        type: TaskType.pruning,
      );
      final decoded = MaintenanceTask.fromJson(
        jsonDecode(jsonEncode(task.toJson())) as Map<String, dynamic>,
      );
      expect(decoded.id, task.id);
      expect(decoded.type, TaskType.pruning);
      expect(decoded.treeId, 't1');
      expect(decoded.isCompleted, isTrue);
      expect(decoded.completedAt, task.completedAt);
      expect(decoded.dueDate, task.dueDate);
    });

    test('is overdue only when pending and due before today', () {
      final now = DateTime(2026, 6, 15, 18);
      expect(makeTask(dueDate: DateTime(2026, 6, 14)).isOverdue(now), isTrue);
      expect(makeTask(dueDate: DateTime(2026, 6, 15)).isOverdue(now), isFalse);
      expect(
        makeTask(
          dueDate: DateTime(2026, 6, 1),
          isCompleted: true,
        ).isOverdue(now),
        isFalse,
      );
    });

    test('copyWith can clear the linked tree', () {
      final task = makeTask(treeId: 't1');
      expect(task.copyWith(clearTree: true).treeId, isNull);
    });
  });

  group('WateringRecord', () {
    test('round-trips through JSON with optional amounts', () {
      final record = WateringRecord(
        id: 'w1',
        treeId: 't1',
        wateredAt: fixedNow,
        quantityLitres: 7.5,
        durationMinutes: 10,
        notes: 'Morning',
      );
      final decoded = WateringRecord.fromJson(
        jsonDecode(jsonEncode(record.toJson())) as Map<String, dynamic>,
      );
      expect(decoded.treeId, 't1');
      expect(decoded.wateredAt, fixedNow);
      expect(decoded.quantityLitres, 7.5);
      expect(decoded.durationMinutes, 10);
      expect(decoded.amountSummary, '7.5 L · 10 min');
    });

    test('amount summary is empty when nothing was measured', () {
      final record = WateringRecord(id: 'w', treeId: 't', wateredAt: fixedNow);
      expect(record.amountSummary, isEmpty);
    });
  });
}
