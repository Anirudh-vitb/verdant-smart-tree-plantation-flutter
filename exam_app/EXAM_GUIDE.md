# Exam Guide: Smart Tree Plantation (exam version)

This folder is the **easy, hand-writable version** of the project for the Flutter lab exam.
It has the **same modules as the main project**, written as simply as possible:

- 10 short files, 425 lines in total, all directly in `lib/`
- only built-in Flutter widgets and `setState`; no packages, no `const`, no `key`
- every page follows the same pattern, so once you know one page you know them all

## How to run

```
cd exam_app
flutter pub get
flutter run
```

## Modules (same as the main project)

| No. | File | Lines | Main project screen | What it does |
|---|---|---|---|---|
| 1 | `main.dart` | 14 | `main.dart` / `app.dart` | Starts the app, green theme |
| 2 | `data.dart` | 26 | `models/` | `Tree` and `Task` classes + sample lists |
| 3 | `home_screen.dart` | 31 | Navigation (home shell) | Bottom bar: Dashboard, Trees, Maintenance |
| 4 | `dashboard_screen.dart` | 34 | Dashboard | Total trees, healthy, need attention, pending tasks |
| 5 | `trees_screen.dart` | 59 | Trees list | Search box + list of trees + add button |
| 6 | `add_tree_screen.dart` | 71 | Add tree form | Name, location, species, health, date picker, save |
| 7 | `tree_detail_screen.dart` | 65 | Tree details | Details, watering history, delete with confirmation |
| 8 | `watering_screen.dart` | 39 | Record watering | Litres box, saves "10 litres on 9/11/2026" |
| 9 | `maintenance_screen.dart` | 42 | Maintenance | Task list, tick when done, delete |
| 10 | `add_task_screen.dart` | 44 | Task form | Task title + type dropdown, save |

The main project has extra features (sort, health filter, edit, saving to the phone). The exam
version keeps only the core of each screen so it is easy to write.

## External exam: write the full app

Write the files in this order:

1. `data.dart`: the data comes first.
2. `main.dart`
3. `home_screen.dart`
4. `dashboard_screen.dart`
5. `trees_screen.dart`, then `add_tree_screen.dart`, `tree_detail_screen.dart` and `watering_screen.dart`
6. `maintenance_screen.dart`, then `add_task_screen.dart`

## Internal exam: "write module X"

Write that one file. If it uses `Tree` or `Task`, also write `data.dart` (module 2, 26 lines).

| If ma'am asks for… | Write |
|---|---|
| Dashboard | 4 (+ 2) |
| Navigation / bottom navigation bar | 3 |
| List page / ListView / search | 5 (+ 2) |
| Form / add page / dropdown / date picker | 6 (+ 2) |
| Details page / passing data / alert dialog | 7 (+ 2) |
| Record watering | 8 (+ 2) |
| Maintenance / checkbox list / delete | 9 (+ 2) |
| Add task | 10 (+ 2) |
| Model class | 2 |

## The 6 things to remember

Every page is built from these six pieces. Learn them and you can write any module.

**1. A page that changes (StatefulWidget):**

```dart
class TreesScreen extends StatefulWidget {
  @override
  State<TreesScreen> createState() => _TreesScreenState();
}

class _TreesScreenState extends State<TreesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Trees')),
      body: ...,
    );
  }
}
```

A page that never changes (Dashboard, Watering) is simpler: `class X extends StatelessWidget` with only `build`.

**2. Text box:**

```dart
var nameC = TextEditingController();
TextField(controller: nameC, decoration: InputDecoration(labelText: 'Tree name'))
// read it with: nameC.text
```

**3. Dropdown:**

```dart
String species = 'Neem';
DropdownButton<String>(
  value: species,
  items: ['Neem', 'Mango', 'Peepal'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
  onChanged: (value) => setState(() => species = value!),
)
```

**4. List:**

```dart
ListView.builder(
  itemCount: trees.length,
  itemBuilder: (context, i) {
    return ListTile(title: Text(trees[i].name));
  },
)
```

**5. Go to another page, and refresh when you come back:**

```dart
Navigator.push(context, MaterialPageRoute(builder: (context) => AddTreeScreen()))
    .then((value) => setState(() {}));

Navigator.pop(context); // go back
```

**6. Save button that checks for empty fields:**

```dart
if (nameC.text.isEmpty) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please fill all fields')));
  return;
}
trees.add(Tree(nameC.text, species, locationC.text, health, date));
Navigator.pop(context);
```

## Memory tricks

- Every file starts with `import 'package:flutter/material.dart';` and `import 'data.dart';`.
- Every page returns a `Scaffold` with an `AppBar(title: Text('...'))`.
- Add pages are always: text fields → dropdown → save button → `trees.add(...)` or `tasks.add(...)` → `Navigator.pop`.
- List pages are always: `ListView.builder` + a `FloatingActionButton` that opens the add page.
- `Tree(name, species, location, health, date)`: remember "**N**ame **S**pecies **L**ocation **H**ealth **D**ate".

## Viva answers (short)

- **StatelessWidget vs StatefulWidget.** Stateless never changes (Dashboard). Stateful has data that
  changes and calls `setState` to redraw (Trees, Add Tree, Maintenance).
- **What does `setState` do?** It tells Flutter the data changed, so `build` runs again.
- **How do screens share data?** They all use the lists `trees` and `tasks` from `data.dart`.
- **What does `.then((value) => setState(() {}))` do?** It refreshes the list after you come back
  from the add or details page.
- **What is `TextEditingController`?** It holds what the user typed; `.text` reads it.
- **Limitation.** Data is kept in memory, so it resets when the app restarts. The main project saves
  it on the phone with `shared_preferences`.

## Tests

```
flutter analyze  # No issues found
flutter test     # 5 tests: dashboard, add tree, search, watering + delete, tasks
```
