import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verdant_exam/main.dart';
import 'package:verdant_exam/models/plantation_data.dart';

Future<void> login(WidgetTester tester) async {
  await tester.pumpWidget(const PlantationApp());
  await tester.enterText(find.byType(TextFormField).at(0), 'student@college.edu');
  await tester.enterText(find.byType(TextFormField).at(1), 'secret123');
  await tester.tap(find.text('Login'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('login shows errors for empty fields', (tester) async {
    await tester.pumpWidget(const PlantationApp());
    await tester.tap(find.text('Login'));
    await tester.pump();
    expect(find.text('Enter your email'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
  });

  testWidgets('login opens the dashboard with live counts', (tester) async {
    await login(tester);
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('${trees.length}'), findsWidgets);
  });

  testWidgets('add a tree and see it in the list', (tester) async {
    await login(tester);
    await tester.tap(find.text('Trees'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save Tree'));
    await tester.pump();
    expect(find.text('Enter tree name'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'Pond Jamun');
    await tester.enterText(find.byType(TextFormField).at(1), 'Near the pond');
    await tester.tap(find.text('Species'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Jamun').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save Tree'));
    await tester.pumpAndSettle();

    expect(find.text('Pond Jamun'), findsOneWidget);
  });

  testWidgets('record watering and delete a tree', (tester) async {
    await login(tester);
    await tester.tap(find.text('Trees'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gate Neem'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Record Watering'));
    await tester.pumpAndSettle();
    expect(find.text('Watering history (1)'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Gate Neem'), findsNothing);
  });

  testWidgets('add and complete a maintenance task', (tester) async {
    await login(tester);
    await tester.tap(find.text('Maintenance'));
    await tester.pumpAndSettle();
    final before = tasks.where((t) => !t.isDone).length;

    await tester.tap(find.byIcon(Icons.add_task));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Prune the neem');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(find.text('Prune the neem'), findsOneWidget);
    expect(find.text('Maintenance (${before + 1} pending)'), findsOneWidget);

    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    expect(find.text('Maintenance ($before pending)'), findsOneWidget);
  });
}
