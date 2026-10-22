import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_environment.dart';
import 'core/theme/app_theme.dart';
import 'providers/maintenance_provider.dart';
import 'providers/tree_provider.dart';
import 'screens/shell/home_shell.dart';
import 'services/local_storage_service.dart';
import 'services/species_service.dart';

/// Root widget. Dependencies are passed in so tests can supply fakes.
class VerdantApp extends StatelessWidget {
  const VerdantApp({
    super.key,
    required this.storage,
    required this.speciesService,
    this.environment = const AppEnvironment(),
  });

  final LocalStorageService storage;
  final SpeciesService speciesService;
  final AppEnvironment environment;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppEnvironment>.value(value: environment),
        Provider<SpeciesService>.value(value: speciesService),
        ChangeNotifierProvider(create: (_) => TreeProvider(storage)..load()),
        ChangeNotifierProvider(
          create: (_) => MaintenanceProvider(storage)..load(),
        ),
      ],
      child: MaterialApp(
        title: 'Verdant – Smart Tree Plantation',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const HomeShell(),
      ),
    );
  }
}
