# Exam Guide — Smart Tree Plantation (exam version)

This folder is a **small, hand-writable version** of the project for the Flutter lab exam.
It has 11 modules and 660 lines in total. It uses only built-in Flutter widgets and `setState`,
with no extra packages, so every file can be written from memory.

> The full project (Provider, local storage, 63 tests) is in the main `lib/` folder.
> Use **this** folder for writing in the exam.

## How to run

```
cd exam_app
flutter pub get
flutter run
```

Login with any email that contains `@` and a password of 6 or more characters.

## Modules

| No. | File | Lines | What it shows | Key widgets / concepts |
|---|---|---|---|---|
| 1 | `lib/main.dart` | 25 | App entry point | `runApp`, `MaterialApp`, `ThemeData` |
| 2 | `lib/models/tree.dart` | 17 | Tree data class | class, constructor, `required` |
| 3 | `lib/models/task.dart` | 14 | Task data class | default value `isDone = false` |
| 4 | `lib/models/plantation_data.dart` | 46 | Shared data + helpers | `List`, sample data, `formatDate`, `healthColor` |
| 5 | `lib/screens/login_screen.dart` | 89 | **Login page** | `Form`, `GlobalKey<FormState>`, `TextFormField`, `validator`, `obscureText`, `Navigator.pushReplacement` |
| 6 | `lib/screens/home_screen.dart` | 40 | **Bottom navigation** | `BottomNavigationBar`, `currentIndex`, `setState` |
| 7 | `lib/screens/dashboard_screen.dart` | 62 | **Dashboard** | `GridView.count`, `Card`, `where(...).length` |
| 8 | `lib/screens/tree_list_screen.dart` | 83 | **List + search** | `ListView.builder`, `TextField` `onChanged`, `ListTile`, `FloatingActionButton` |
| 9 | `lib/screens/add_tree_screen.dart` | 100 | **Add form** | `DropdownButtonFormField`, `showDatePicker`, `SnackBar`, `Navigator.pop` |
| 10 | `lib/screens/tree_detail_screen.dart` | 88 | **Details + delete** | passing data to a screen, `AlertDialog`, `showDialog`, `FloatingActionButton.extended` |
| 11 | `lib/screens/maintenance_screen.dart` | 96 | **Task list (CRUD)** | `CheckboxListTile`, add-task dialog, delete, `TextDecoration.lineThrough` |

## External exam: writing the full code

Write the files in this order. Each step only uses files written before it.

1. `main.dart`. It points to `LoginScreen`.
2. The models: `tree.dart`, `task.dart`, `plantation_data.dart`.
3. `login_screen.dart`, which opens `HomeScreen`.
4. `home_screen.dart`, with the 3 tabs.
5. `dashboard_screen.dart`, `tree_list_screen.dart`, `maintenance_screen.dart`, the three tab pages.
6. `add_tree_screen.dart` and `tree_detail_screen.dart`, which open from the tree list.

If time is short, write modules 1–8 plus 11. That is a complete working app: login, navigation,
dashboard, list with search, and tasks. Then add modules 9 and 10.

## Internal exam: "write module X"

When asked for one page, write that file plus the model it uses. For example, "Write the
add tree page" means module 9 plus module 2, `tree.dart`. Say that `trees` and `speciesList` come
from `plantation_data.dart`.

| If asked… | Write module(s) |
|---|---|
| Login page / form validation | 5 |
| Navigation / bottom navigation bar | 6 |
| Dashboard / GridView / cards | 7 (+ 4) |
| ListView / search | 8 (+ 2, 4) |
| Form with dropdown and date picker | 9 (+ 2) |
| Passing data between screens / dialog | 10 (+ 2) |
| CRUD / checkbox list / to-do style page | 11 (+ 3) |
| Model class | 2 or 3 |

## Patterns to memorise

Almost every page is one of two patterns.

**Stateful page (anything that changes):**

```dart
class XScreen extends StatefulWidget {
  const XScreen({super.key});

  @override
  State<XScreen> createState() => _XScreenState();
}

class _XScreenState extends State<XScreen> {
  // variables here

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('X')),
      body: ...,
    );
  }
}
```

**Form with validation (login, add tree):**

```dart
final _formKey = GlobalKey<FormState>();

Form(
  key: _formKey,
  child: TextFormField(
    validator: (value) => value!.isEmpty ? 'Enter name' : null,
  ),
);

if (_formKey.currentState!.validate()) { /* save */ }
```

**Navigation:**

```dart
Navigator.push(context, MaterialPageRoute(builder: (context) => const AddTreeScreen()));
Navigator.pop(context);                       // go back
Navigator.pushReplacement(context, ...);     // login -> home (no back button)
```

**Refresh a list after coming back:** `await Navigator.push(...); setState(() {});`

## Viva answers (short)

- **StatelessWidget vs StatefulWidget.** Stateless never changes after it is built (Dashboard).
  Stateful has data that changes and calls `setState` to redraw (Login, Trees, Maintenance).
- **What does `setState` do?** It tells Flutter the data changed, so `build` runs again.
- **How is data shared between screens?** Through the lists `trees` and `tasks` in
  `plantation_data.dart`. Every screen reads the same lists.
- **How is the form validated?** Each `TextFormField` has a `validator` that returns an error text,
  or `null` when the value is valid. `_formKey.currentState!.validate()` runs all of them.
- **Why `pushReplacement` after login?** It removes the login page, so Back does not return to it.
- **Limitation of this version.** Data is kept in memory only and resets when the app restarts.
  The full project saves it with `shared_preferences`.

## Tests

```
flutter test     # 5 widget tests: login validation, dashboard, add tree, watering + delete, tasks
flutter analyze  # No issues found
```
