import 'package:flutter/foundation.dart';

import '../core/utils/formatters.dart';
import '../data/sample_data.dart';
import '../models/tree.dart';
import '../models/tree_query.dart';
import '../models/watering_record.dart';
import '../services/local_storage_service.dart';

/// Owns the list of trees and their watering history.
///
/// Every change is saved to storage *before* the in-memory state is updated,
/// so if saving fails the UI never shows data that was not persisted.
class TreeProvider extends ChangeNotifier {
  TreeProvider(this._storage, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final LocalStorageService _storage;
  final DateTime Function() _clock;

  List<Tree> _trees = const [];
  List<WateringRecord> _waterings = const [];
  String? _loadWarning;

  List<Tree> get trees => List.unmodifiable(_trees);
  List<WateringRecord> get waterings => List.unmodifiable(_waterings);

  /// Set when some stored records could not be read.
  String? get loadWarning => _loadWarning;

  bool get hasDemoData =>
      _trees.any((t) => t.isDemo) || _waterings.any((w) => w.isDemo);

  void load() {
    final trees = _storage.loadTrees();
    final waterings = _storage.loadWaterings();
    _trees = trees.items;
    _waterings = waterings.items;
    final skipped = trees.skipped + waterings.skipped;
    _loadWarning = skipped == 0
        ? null
        : '$skipped saved record(s) were damaged and could not be loaded.';
    notifyListeners();
  }

  Tree? treeById(String id) {
    for (final tree in _trees) {
      if (tree.id == id) return tree;
    }
    return null;
  }

  List<Tree> query(TreeQuery query) => query.apply(_trees);

  /// Most recently added trees first.
  List<Tree> recentTrees({int limit = 3}) =>
      const TreeQuery().apply(_trees).take(limit).toList();

  Future<Tree> addTree({
    required String name,
    required String species,
    String? scientificName,
    required DateTime plantedOn,
    required String location,
    required HealthStatus health,
    String notes = '',
  }) async {
    final now = _clock();
    final tree = Tree(
      id: IdGenerator.next('tree'),
      name: name.trim(),
      species: species.trim(),
      scientificName: scientificName?.trim(),
      plantedOn: Formatters.dateOnly(plantedOn),
      location: location.trim(),
      health: health,
      notes: notes.trim(),
      createdAt: now,
      updatedAt: now,
    );
    await _saveTrees([..._trees, tree]);
    return tree;
  }

  Future<void> updateTree(Tree updated) async {
    if (treeById(updated.id) == null) {
      throw StateError('Tree ${updated.id} no longer exists.');
    }
    final stamped = updated.copyWith(updatedAt: _clock());
    await _saveTrees([
      for (final tree in _trees) tree.id == updated.id ? stamped : tree,
    ]);
  }

  /// Deletes the tree and its watering history.
  Future<void> deleteTree(String id) async {
    final remainingWaterings = _waterings.where((w) => w.treeId != id).toList();
    if (remainingWaterings.length != _waterings.length) {
      await _storage.saveWaterings(remainingWaterings);
      _waterings = remainingWaterings;
    }
    await _saveTrees(_trees.where((t) => t.id != id).toList());
  }

  Future<WateringRecord> recordWatering({
    required String treeId,
    required DateTime wateredAt,
    double? quantityLitres,
    int? durationMinutes,
    String notes = '',
  }) async {
    if (treeById(treeId) == null) {
      throw StateError('Cannot record watering for an unknown tree.');
    }
    final record = WateringRecord(
      id: IdGenerator.next('water'),
      treeId: treeId,
      wateredAt: wateredAt,
      quantityLitres: quantityLitres,
      durationMinutes: durationMinutes,
      notes: notes.trim(),
    );
    final updated = [..._waterings, record];
    await _storage.saveWaterings(updated);
    _waterings = updated;
    notifyListeners();
    return record;
  }

  /// Newest first.
  List<WateringRecord> wateringsFor(String treeId) {
    return _waterings.where((w) => w.treeId == treeId).toList()
      ..sort((a, b) => b.wateredAt.compareTo(a.wateredAt));
  }

  DateTime? lastWatered(String treeId) {
    final history = wateringsFor(treeId);
    return history.isEmpty ? null : history.first.wateredAt;
  }

  /// Ids of the sample trees currently stored.
  Set<String> get demoTreeIds =>
      _trees.where((t) => t.isDemo).map((t) => t.id).toSet();

  /// Removes sample trees and sample waterings, plus any watering the user
  /// recorded for a sample tree.
  Future<void> removeDemoData() async {
    final demoIds = demoTreeIds;
    final waterings = _waterings
        .where((w) => !w.isDemo && !demoIds.contains(w.treeId))
        .toList();
    await _storage.saveWaterings(waterings);
    _waterings = waterings;
    await _saveTrees(_trees.where((t) => !t.isDemo).toList());
  }

  /// Adds back any sample records that are not already present.
  Future<void> addDemoData(SampleData sample) async {
    final treeIds = _trees.map((t) => t.id).toSet();
    final waterIds = _waterings.map((w) => w.id).toSet();
    final waterings = [
      ..._waterings,
      ...sample.waterings.where((w) => !waterIds.contains(w.id)),
    ];
    await _storage.saveWaterings(waterings);
    _waterings = waterings;
    await _saveTrees([
      ..._trees,
      ...sample.trees.where((t) => !treeIds.contains(t.id)),
    ]);
  }

  Future<void> _saveTrees(List<Tree> trees) async {
    await _storage.saveTrees(trees);
    _trees = trees;
    notifyListeners();
  }
}
