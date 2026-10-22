import 'package:flutter_test/flutter_test.dart';
import 'package:verdant_smart_tree_plantation_flutter/models/tree.dart';
import 'package:verdant_smart_tree_plantation_flutter/models/tree_query.dart';

import 'test_helpers.dart';

void main() {
  final trees = [
    makeTree(
      id: 'a',
      name: 'Gate Neem',
      species: 'Neem',
      scientificName: 'Azadirachta indica',
      plantedOn: DateTime(2025, 3, 1),
      createdAt: DateTime(2026, 1, 1),
    ),
    makeTree(
      id: 'b',
      name: 'library mango',
      species: 'Mango',
      scientificName: 'Mangifera indica',
      health: HealthStatus.needsAttention,
      plantedOn: DateTime(2026, 2, 1),
      createdAt: DateTime(2026, 3, 1),
    ),
    makeTree(
      id: 'c',
      name: 'Banyan Corner',
      species: 'Banyan',
      scientificName: 'Ficus benghalensis',
      health: HealthStatus.critical,
      plantedOn: DateTime(2024, 7, 1),
      createdAt: DateTime(2026, 2, 1),
    ),
  ];

  List<String> ids(List<Tree> list) => list.map((t) => t.id).toList();

  test('empty query returns every tree, most recently added first', () {
    expect(ids(const TreeQuery().apply(trees)), ['b', 'c', 'a']);
  });

  test('search matches tree name case-insensitively', () {
    expect(ids(const TreeQuery(search: 'MANGO').apply(trees)), ['b']);
  });

  test('search matches species and scientific name', () {
    expect(ids(const TreeQuery(search: 'banyan').apply(trees)), ['c']);
    expect(ids(const TreeQuery(search: 'indica').apply(trees)), ['b', 'a']);
  });

  test('search with no matches returns an empty list', () {
    expect(const TreeQuery(search: 'oak').apply(trees), isEmpty);
  });

  test('filters by health status', () {
    expect(ids(const TreeQuery(health: HealthStatus.critical).apply(trees)), [
      'c',
    ]);
    expect(ids(const TreeQuery(health: HealthStatus.healthy).apply(trees)), [
      'a',
    ]);
  });

  test('combines search and health filter', () {
    const query = TreeQuery(
      search: 'indica',
      health: HealthStatus.needsAttention,
    );
    expect(ids(query.apply(trees)), ['b']);
  });

  test('sorts by name and planting date', () {
    expect(ids(const TreeQuery(sort: TreeSort.nameAsc).apply(trees)), [
      'c',
      'a',
      'b',
    ]);
    expect(ids(const TreeQuery(sort: TreeSort.plantedNewest).apply(trees)), [
      'b',
      'a',
      'c',
    ]);
    expect(ids(const TreeQuery(sort: TreeSort.plantedOldest).apply(trees)), [
      'c',
      'a',
      'b',
    ]);
  });
}
