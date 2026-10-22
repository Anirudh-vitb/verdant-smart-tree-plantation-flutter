import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verdant_smart_tree_plantation_flutter/models/tree.dart';
import 'package:verdant_smart_tree_plantation_flutter/services/local_storage_service.dart';
import 'package:verdant_smart_tree_plantation_flutter/widgets/statistic_card.dart';

import 'test_helpers.dart';

/// Storage pre-filled with a known set of trees and tasks.
Future<LocalStorageService> seededStorage() async {
  final today = DateTime.now();
  final storage = LocalStorageService(InMemoryStore());
  await storage.saveTrees([
    makeTree(
      id: 't1',
      name: 'Gate Neem',
      species: 'Neem',
      scientificName: 'Azadirachta indica',
    ),
    makeTree(id: 't2', name: 'Library Mango', species: 'Mango'),
    makeTree(
      id: 't3',
      name: 'Parking Peepal',
      species: 'Peepal',
      scientificName: 'Ficus religiosa',
      health: HealthStatus.critical,
    ),
  ]);
  await storage.saveTasks([
    makeTask(
      id: 'k1',
      title: 'Water the neem',
      treeId: 't1',
      dueDate: today.add(const Duration(days: 1)),
    ),
  ]);
  await storage.markInitialized();
  return storage;
}

/// Value displayed by the dashboard card with the given label.
int statValue(WidgetTester tester, String label) => tester
    .widget<StatisticCard>(find.widgetWithText(StatisticCard, label))
    .value;

Future<void> openTab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('dashboard shows statistics calculated from stored data', (
    tester,
  ) async {
    await pumpApp(tester, storage: await seededStorage());

    expect(statValue(tester, 'Trees planted'), 3);
    expect(statValue(tester, 'Healthy trees'), 2);
    expect(statValue(tester, 'Need attention'), 1);
    expect(statValue(tester, 'Pending tasks'), 1);
    expect(find.text('67% healthy'), findsOneWidget);
    expect(find.text('1 tree needs attention.'), findsOneWidget);

    await scrollTo(tester, find.text('Water the neem'));
    expect(find.text('Water the neem'), findsOneWidget);
  });

  testWidgets('dashboard shows empty states when there is no data', (
    tester,
  ) async {
    final storage = LocalStorageService(InMemoryStore());
    await storage.markInitialized();
    await pumpApp(tester, storage: storage);

    expect(
      find.text('Your plantation is empty. Add your first tree to begin.'),
      findsOneWidget,
    );
    expect(statValue(tester, 'Trees planted'), 0);
    await scrollTo(tester, find.text('No watering scheduled'));
    expect(find.text('No watering scheduled'), findsOneWidget);
    await scrollTo(tester, find.text('No trees yet'));
    expect(find.text('No trees yet'), findsOneWidget);
  });

  testWidgets('tree form blocks saving when required fields are empty', (
    tester,
  ) async {
    final storage = LocalStorageService(InMemoryStore());
    await storage.markInitialized();
    await pumpApp(tester, storage: storage);
    await openTab(tester, 'Trees');

    await tester.tap(find.text('Add tree'));
    await tester.pumpAndSettle();
    await scrollAndTap(tester, find.text('Save tree'));

    expect(find.text('Please enter a name for the tree'), findsOneWidget);
    expect(find.text('Please select a species'), findsOneWidget);
    expect(find.text('Please enter where the tree is planted'), findsOneWidget);
    expect(storage.loadTrees().items, isEmpty);
  });

  testWidgets('adding a tree saves it and updates the list and dashboard', (
    tester,
  ) async {
    final storage = LocalStorageService(InMemoryStore());
    await storage.markInitialized();
    await pumpApp(tester, storage: storage);
    await openTab(tester, 'Trees');
    expect(find.text('No trees yet'), findsOneWidget);

    await tester.tap(find.text('Add tree'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Tree name *'),
      'Pond Jamun',
    );
    await tester.tap(find.text('Species *'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'jamun');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Jamun'));
    await tester.pumpAndSettle();
    expect(find.text('Jamun (Syzygium cumini)'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Plantation location *'),
      'Near the pond',
    );
    await scrollAndTap(tester, find.text('Needs Attention'));
    await scrollAndTap(tester, find.text('Save tree'));

    expect(find.text('"Pond Jamun" added to your plantation'), findsOneWidget);
    expect(find.text('Pond Jamun'), findsOneWidget);
    final saved = storage.loadTrees().items.single;
    expect(saved.species, 'Jamun');
    expect(saved.health, HealthStatus.needsAttention);

    await openTab(tester, 'Dashboard');
    expect(statValue(tester, 'Trees planted'), 1);
    expect(statValue(tester, 'Need attention'), 1);
  });

  testWidgets('leaving a form with unsaved changes asks for confirmation', (
    tester,
  ) async {
    await pumpApp(tester, storage: await seededStorage());
    await openTab(tester, 'Trees');
    await tester.tap(find.text('Add tree'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Tree name *'),
      'Draft',
    );
    await tester.tap(find.byTooltip('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Discard changes?'), findsOneWidget);
    await tester.tap(find.text('Cancel').last);
    await tester.pumpAndSettle();
    expect(find.text('Add a tree'), findsOneWidget); // Still on the form.

    await tester.tap(find.byTooltip('Cancel'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(find.text('Add a tree'), findsNothing);
  });

  testWidgets('trees can be searched and filtered by health', (tester) async {
    await pumpApp(tester, storage: await seededStorage());
    await openTab(tester, 'Trees');
    expect(find.text('3 of 3 trees · Recently added'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Search by name or species'),
      'ficus',
    );
    await tester.pumpAndSettle();
    expect(find.text('Parking Peepal'), findsOneWidget);
    expect(find.text('Gate Neem'), findsNothing);

    await tester.enterText(
      find.widgetWithText(TextField, 'Search by name or species'),
      '',
    );
    await tester.tap(find.text('Healthy (2)'));
    await tester.pumpAndSettle();
    expect(find.text('2 of 3 trees · Recently added'), findsOneWidget);
    expect(find.text('Parking Peepal'), findsNothing);

    final chips = find.descendant(
      of: find.byWidgetPredicate(
        (w) => w is ListView && w.scrollDirection == Axis.horizontal,
      ),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.text('Critical (1)'),
      150,
      scrollable: chips,
    );
    await tester.ensureVisible(find.text('Critical (1)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Critical (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Parking Peepal'), findsOneWidget);
  });

  testWidgets('deleting a tree requires confirmation and removes its tasks', (
    tester,
  ) async {
    final storage = await seededStorage();
    await pumpApp(tester, storage: storage);
    await openTab(tester, 'Trees');
    await tester.tap(find.text('Gate Neem'));
    await tester.pumpAndSettle();
    expect(find.text('Maintenance (1)'), findsOneWidget);

    await tester.tap(find.byTooltip('Delete tree'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(storage.loadTrees().items, hasLength(3));

    await tester.tap(find.byTooltip('Delete tree'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete tree'));
    await tester.pumpAndSettle();

    expect(find.text('Gate Neem'), findsNothing);
    expect(storage.loadTrees().items, hasLength(2));
    expect(storage.loadTasks().items, isEmpty);
  });

  testWidgets('editing a tree updates its details', (tester) async {
    final storage = await seededStorage();
    await pumpApp(tester, storage: storage);
    await openTab(tester, 'Trees');
    await tester.tap(find.text('Library Mango'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit tree'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Tree name *'),
      'Old Mango',
    );
    await scrollAndTap(tester, find.text('Critical'));
    await scrollAndTap(tester, find.text('Save changes'));

    expect(find.text('Old Mango'), findsWidgets);
    final updated = storage.loadTrees().items.firstWhere((t) => t.id == 't2');
    expect(updated.name, 'Old Mango');
    expect(updated.health, HealthStatus.critical);
  });

  testWidgets('recording watering adds it to the tree history', (tester) async {
    final storage = await seededStorage();
    await pumpApp(tester, storage: storage);
    await openTab(tester, 'Trees');
    await tester.tap(find.text('Library Mango'));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Not watered yet'));
    expect(find.text('Not watered yet'), findsOneWidget);

    await tester.tap(find.text('Record watering'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Quantity'),
      'abc',
    );
    await tester.tap(find.text('Save watering record'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a number'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Quantity'),
      '12',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Duration'),
      '15',
    );
    await tester.tap(find.text('Save watering record'));
    await tester.pumpAndSettle();

    await scrollTo(tester, find.text('12 L · 15 min'));
    expect(find.text('Watering history (1)'), findsOneWidget);
    expect(find.text('12 L · 15 min'), findsOneWidget);
    final record = storage.loadWaterings().items.single;
    expect(record.treeId, 't2');
    expect(record.quantityLitres, 12);
  });

  testWidgets('maintenance tasks can be created and completed', (tester) async {
    final storage = await seededStorage();
    await pumpApp(tester, storage: storage);
    await openTab(tester, 'Maintenance');
    expect(find.text('Pending (1)'), findsOneWidget);

    await tester.tap(find.text('New task'));
    await tester.pumpAndSettle();
    await scrollAndTap(tester, find.text('Schedule task'));
    expect(find.text('Please enter a task title'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Title *'),
      'Prune the mango',
    );
    await tester.tap(find.text('Watering').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pruning').last);
    await tester.pumpAndSettle();
    await scrollAndTap(tester, find.text('Schedule task'));

    expect(find.text('Pending (2)'), findsOneWidget);
    expect(find.text('Prune the mango'), findsOneWidget);

    await tester.tap(
      find.bySemanticsLabel('Mark Prune the mango as completed'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Pending (1)'), findsOneWidget);
    expect(find.text('Completed (1)'), findsOneWidget);

    await tester.tap(find.text('Completed (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Prune the mango'), findsOneWidget);
    final saved = storage.loadTasks().items.firstWhere(
      (t) => t.title == 'Prune the mango',
    );
    expect(saved.isCompleted, isTrue);
    expect(saved.completedAt, isNotNull);
  });

  testWidgets('uses a navigation rail on wide screens', (tester) async {
    await pumpApp(
      tester,
      storage: await seededStorage(),
      size: const Size(1200, 900),
    );
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });
}
