# Exam Guide: Smart Tree Plantation (exam version)

This folder is the **easy, hand-writable version** of the project for the Flutter lab exam.
It has the **same modules as the main project**, written as simply as possible:

- 10 short files, 369 lines in total, all directly in `lib/` (no file is longer than 59 lines)
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
| 6 | `add_tree_screen.dart` | 36 | Add tree form | 5 text boxes (name, species, location, health, date) + save |
| 7 | `tree_detail_screen.dart` | 47 | Tree details | Details, watering history, Record Watering and Delete buttons |
| 8 | `watering_screen.dart` | 39 | Record watering | Litres box, saves "10 litres on 9/11/2026" |
| 9 | `maintenance_screen.dart` | 39 | Maintenance | Task list, tap a task to mark it Done, delete |
| 10 | `add_task_screen.dart` | 44 | Task form | Task title + type dropdown, save |

The main project has extra features (sort, health filter, edit, date picker, delete confirmation,
saving to the phone). The exam version keeps only the core of each screen so it is easy to write.

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
| Form / add page | 6 (+ 2) |
| Dropdown | 10 |
| Details page / passing data to a page | 7 (+ 2) |
| Record watering | 8 (+ 2) |
| Maintenance / to-do list / delete | 9 (+ 2) |
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

**6. Save button:**

```dart
ElevatedButton(
  onPressed: () {
    if (nameC.text.isEmpty) return;          // do nothing if the name is empty
    trees.add(Tree(nameC.text, speciesC.text, locationC.text, healthC.text, dateC.text));
    Navigator.pop(context);
  },
  child: Text('Save Tree'),
)
```

## Memory tricks

- Every file starts with `import 'package:flutter/material.dart';` and `import 'data.dart';`.
- Every page returns a `Scaffold` with an `AppBar(title: Text('...'))`.
- Add pages are always: text boxes → save button → `trees.add(...)` or `tasks.add(...)` → `Navigator.pop`.
- Add Tree has 5 text boxes that are the same line with a different name: `nameC`, `speciesC`, `locationC`, `healthC`, `dateC`.
- List pages are always: `ListView.builder` + a `FloatingActionButton` that opens the add page.
- `Tree(name, species, location, health, date)`: remember "**N**ame **S**pecies **L**ocation **H**ealth **D**ate".

## Viva answers (short)

- **StatelessWidget vs StatefulWidget.** Stateless never changes (Dashboard). Stateful has data that
  changes and calls `setState` to redraw (Trees, Add Tree, Maintenance).
- **What does `setState` do?** It tells Flutter the data changed, so `build` runs again.
- **How do screens share data?** They all use the lists `trees` and `tasks` from `data.dart`.
- **What does `.then((value) => setState(() {}))` do?** It refreshes the list after you come back
  from the add or details page.
- **How is data passed to the details page?** `TreeDetailScreen(list[i])` sends the tapped tree;
  the page reads it as `widget.tree`.
- **What is `TextEditingController`?** It holds what the user typed; `.text` reads it.
- **Limitation.** Data is kept in memory, so it resets when the app restarts. The main project saves
  it on the phone with `shared_preferences`.

## Tests

```
flutter analyze  # No issues found
flutter test     # 5 tests: dashboard, add tree, search, watering + delete, tasks
```
