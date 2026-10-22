import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/maintenance_task.dart';
import '../models/tree.dart';
import '../models/watering_record.dart';

/// Minimal key-value contract so the app can use SharedPreferences in
/// production and an in-memory map in tests.
abstract class KeyValueStore {
  String? read(String key);
  Future<void> write(String key, String value);
}

class SharedPreferencesStore implements KeyValueStore {
  SharedPreferencesStore(this._prefs);

  final SharedPreferences _prefs;

  @override
  String? read(String key) => _prefs.getString(key);

  @override
  Future<void> write(String key, String value) async {
    final ok = await _prefs.setString(key, value);
    if (!ok) throw StorageException('Could not save "$key" to the device.');
  }
}

class InMemoryStore implements KeyValueStore {
  InMemoryStore([Map<String, String>? initial]) : values = {...?initial};

  final Map<String, String> values;

  @override
  String? read(String key) => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

class StorageException implements Exception {
  StorageException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Result of reading a list: the valid items plus how many were unreadable.
class LoadResult<T> {
  const LoadResult(this.items, this.skipped);

  final List<T> items;
  final int skipped;
}

/// Converts model lists to JSON and back.
///
/// Each collection is stored as one JSON array under its own key. Corrupted
/// entries are skipped individually so one bad record never wipes the rest.
class LocalStorageService {
  LocalStorageService(this._store);

  final KeyValueStore _store;

  static const treesKey = 'verdant.trees.v1';
  static const tasksKey = 'verdant.tasks.v1';
  static const wateringsKey = 'verdant.waterings.v1';
  static const initializedKey = 'verdant.initialized.v1';

  /// False only the very first time the app runs on a device.
  bool get isInitialized => _store.read(initializedKey) == 'true';

  Future<void> markInitialized() => _store.write(initializedKey, 'true');

  LoadResult<Tree> loadTrees() => _loadList(treesKey, Tree.fromJson);

  LoadResult<MaintenanceTask> loadTasks() =>
      _loadList(tasksKey, MaintenanceTask.fromJson);

  LoadResult<WateringRecord> loadWaterings() =>
      _loadList(wateringsKey, WateringRecord.fromJson);

  Future<void> saveTrees(List<Tree> trees) =>
      _saveList(treesKey, trees.map((t) => t.toJson()));

  Future<void> saveTasks(List<MaintenanceTask> tasks) =>
      _saveList(tasksKey, tasks.map((t) => t.toJson()));

  Future<void> saveWaterings(List<WateringRecord> records) =>
      _saveList(wateringsKey, records.map((r) => r.toJson()));

  LoadResult<T> _loadList<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final raw = _store.read(key);
    if (raw == null || raw.isEmpty) return LoadResult<T>(const [], 0);

    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException catch (error) {
      debugPrint('Stored data for $key is not valid JSON: $error');
      return LoadResult<T>(const [], 1);
    }
    if (decoded is! List) return LoadResult<T>(const [], 1);

    final items = <T>[];
    var skipped = 0;
    for (final entry in decoded) {
      try {
        items.add(fromJson(Map<String, dynamic>.from(entry as Map)));
      } catch (error) {
        // TypeError or FormatException from a malformed record.
        skipped++;
        debugPrint('Skipping corrupted record in $key: $error');
      }
    }
    return LoadResult<T>(items, skipped);
  }

  Future<void> _saveList(String key, Iterable<Map<String, dynamic>> items) {
    return _store.write(key, jsonEncode(items.toList()));
  }
}
