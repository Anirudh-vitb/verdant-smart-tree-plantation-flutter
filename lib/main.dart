import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'app_environment.dart';
import 'providers/plantation_actions.dart';
import 'services/local_storage_service.dart';
import 'services/species_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  LocalStorageService storage;
  String? storageWarning;
  try {
    final prefs = await SharedPreferences.getInstance();
    storage = LocalStorageService(SharedPreferencesStore(prefs));
  } catch (error) {
    // Keep the app usable even if device storage cannot be opened.
    debugPrint('Falling back to in-memory storage: $error');
    storage = LocalStorageService(InMemoryStore());
    storageWarning = 'Device storage is unavailable. Changes will be lost when the app closes.';
  }

  try {
    await PlantationActions.seedIfFirstRun(storage, DateTime.now());
  } catch (error) {
    debugPrint('Could not write sample data: $error');
  }

  runApp(
    VerdantApp(
      storage: storage,
      speciesService: GbifSpeciesService(),
      environment: AppEnvironment(storageWarning: storageWarning),
    ),
  );
}
