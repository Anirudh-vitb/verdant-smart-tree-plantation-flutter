import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verdant_exam/data.dart';
import 'package:verdant_exam/home_screen.dart';

Future<void> openApp(WidgetTester tester) async {
  await tester.pumpWidget(MaterialApp(home: HomeScreen()));
}

Future<void> openTab(WidgetTester tester, String label) async {
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('dashboard shows counts from the data', (tester) async {
    await openApp(tester);
    expect(find.text('Total Trees'), findsOneWidget);
    expect(find.text('${trees.length}'), findsWidgets);
  });

  testWidgets('add tree needs all fields, then appears in the list', (tester) async {
    await openApp(tester);
    await openTab(tester, 'Trees');
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save Tree'));
    await tester.pump();
    expect(find.text('Please fill all fields'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), 'Pond Jamun');
    await tester.enterText(find.byType(TextField).at(1), 'Near the pond');
    await tester.tap(find.text('Select planting date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save Tree'));
    await tester.pumpAndSettle();

    expect(find.text('Pond Jamun'), findsOneWidget);
  });

  testWidgets('search filters the tree list', (tester) async {
    await openApp(tester);
    await openTab(tester, 'Trees');
    await tester.enterText(find.byType(TextField), 'mango');
    await tester.pump();
    expect(find.text('Library Mango'), findsOneWidget);
    expect(find.text('Gate Neem'), findsNothing);
  });

  testWidgets('record watering, then delete the tree', (tester) async {
    await openApp(tester);
    await openTab(tester, 'Trees');
    await tester.tap(find.text('Gate Neem'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Record Watering'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '10');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.textContaining('10 litres on'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();
    expect(find.text('Gate Neem'), findsNothing);
  });

  testWidgets('add a task and mark it done', (tester) async {
    await openApp(tester);
    await openTab(tester, 'Maintenance');
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Prune the neem');
    await tester.tap(find.text('Save Task'));
    await tester.pumpAndSettle();
    expect(find.text('Prune the neem'), findsOneWidget);

    await tester.tap(find.byType(Checkbox).last);
    await tester.pumpAndSettle();
    expect(tasks.last.done, isTrue);
  });
}
