# Architecture

This document explains how the app is put together, so you can describe it
confidently in a viva.

## 1. Layers at a glance

```
┌──────────────────────────────────────────────────────────────┐
│ UI layer      lib/screens/**, lib/widgets/**                 │
│               Stateless/Stateful widgets, forms, navigation  │
└───────────────▲───────────────────────────┬──────────────────┘
                │ context.watch / select     │ method calls
                │ (rebuild on change)        ▼ (addTree, setCompleted…)
┌───────────────┴──────────────────────────────────────────────┐
│ State layer   lib/providers/**                               │
│               TreeProvider, MaintenanceProvider              │
│               (ChangeNotifier = single source of truth)      │
│               PlantationActions (cross-provider operations)  │
└───────────────▲───────────────────────────┬──────────────────┘
                │ LoadResult<T>              │ save lists
                │                            ▼
┌───────────────┴──────────────────────────────────────────────┐
│ Service layer lib/services/**                                │
│               LocalStorageService → KeyValueStore            │
│               SpeciesService (offline + optional GBIF)       │
└───────────────▲───────────────────────────┬──────────────────┘
                │                            ▼
┌───────────────┴──────────────────────────────────────────────┐
│ Model layer   lib/models/**  (plain Dart, no Flutter UI)     │
│               Tree, WateringRecord, MaintenanceTask,         │
│               Species, TreeQuery, DashboardStats             │
└──────────────────────────────────────────────────────────────┘
```

Each layer only depends on the layers below it. Models know nothing about storage.
Services know nothing about widgets. Widgets never touch `SharedPreferences` or
HTTP directly.

## 2. Start-up sequence (`lib/main.dart`)

1. `WidgetsFlutterBinding.ensureInitialized()` — required before using plugins.
2. Open `SharedPreferences`. If that fails, fall back to an `InMemoryStore` and
   remember a warning (shown as a banner on the dashboard), so the app still opens.
3. `PlantationActions.seedIfFirstRun` — on the very first launch, writes the sample
   trees/tasks/waterings and sets an `initialized` flag so it never re-seeds.
4. `runApp(VerdantApp(...))` — `VerdantApp` creates the providers inside a
   `MultiProvider` and immediately calls `load()` on each.

Dependencies (storage, species service) are passed **into** `VerdantApp`. Tests use
this to inject in-memory storage and an offline species service.

## 3. State management (Provider + ChangeNotifier)

| Provider | Owns | Key methods |
|---|---|---|
| `TreeProvider` | `List<Tree>`, `List<WateringRecord>` | `addTree`, `updateTree`, `deleteTree`, `recordWatering`, `wateringsFor`, `lastWatered`, `query(TreeQuery)` |
| `MaintenanceProvider` | `List<MaintenanceTask>` | `addTask`, `updateTask`, `setCompleted`, `deleteTask`, `deleteTasksForTree`, `pendingTasks`, `completedTasks`, `upcomingWatering` |

Rules followed:

- **One source of truth.** Every list lives in exactly one provider. Screens never
  keep their own copy. Derived values (dashboard numbers, filtered lists) are
  computed on every build from that single list.
- **Save first, then update.** Each mutation builds the new list, awaits
  `storage.saveX(newList)`, then assigns it and calls `notifyListeners()`. If saving
  throws, the old state is kept and the screen shows an error snackbar. The test
  `does not change state when saving fails` checks this.
- **Immutable models.** Models are `const` classes with `copyWith`. Edits create a
  new object instead of mutating the old one, which keeps change detection simple.
- **Business logic outside widgets.** Searching and filtering live in
  `TreeQuery.apply`, statistics in `DashboardStats.compute`, cascade deletes in
  `PlantationActions`. All are plain Dart, so they are easy to unit test.

### Why two providers plus `PlantationActions`?

Trees and tasks change for different reasons, so they are separate. Some operations
touch both. For example, deleting a tree must also delete its tasks. Instead of
having the providers depend on each other, `PlantationActions` performs these steps
in the correct order. Screens call `PlantationActions(...).deleteTree(id)` and don't
need to remember the rule.

## 4. Data flow example — "Record watering"

```
User taps "Save watering record"
  → RecordWateringSheet validates the form
  → TreeProvider.recordWatering(treeId, wateredAt, litres, minutes, notes)
      → creates WateringRecord with a new id
      → LocalStorageService.saveWaterings([...old, record])  (JSON → SharedPreferences)
      → _waterings = updated; notifyListeners()
  → Every widget that watches TreeProvider rebuilds:
      • TreeDetailsScreen: "Watering history (n)" list and "Last watered"
      • TreeCard: "Watered today"
      • DashboardScreen: "N waterings this week" caption
  → Sheet closes and a snackbar confirms "Watering recorded for <tree>"
```

## 5. Persistence (`lib/services/local_storage_service.dart`)

- `KeyValueStore` is a two-method interface (`read`, `write`).
  `SharedPreferencesStore` is used on devices and `InMemoryStore` in tests.
- Each collection is stored as one JSON array under a versioned key:

  | Key | Content |
  |---|---|
  | `verdant.trees.v1` | `[Tree.toJson(), …]` |
  | `verdant.tasks.v1` | `[MaintenanceTask.toJson(), …]` |
  | `verdant.waterings.v1` | `[WateringRecord.toJson(), …]` |
  | `verdant.initialized.v1` | `"true"` after first-run seeding |

- **Corruption handling.** When loading, each record is parsed separately inside
  `try/catch`. Bad records are skipped and counted (`LoadResult.skipped`), and the
  dashboard shows "N saved record(s) were damaged…". Invalid JSON or a non-list
  value gives an empty list instead of a crash.
- **Why `shared_preferences`?** The dataset is small (hundreds of records at most),
  it needs no schema or migrations, and it works on Android and web. A database such
  as SQLite would add complexity this project does not need.
- Dates are stored as ISO-8601 strings (`DateTime.toIso8601String()`).

## 6. Model relationships

```
Tree ─┬─< WateringRecord   (treeId, required)
      └─< MaintenanceTask  (treeId, optional; null = whole plantation)
```

- IDs are created on the device by `IdGenerator.next(prefix)` (time-based plus a
  counter) and never change after creation.
- `isDemo` marks first-run sample records so "Remove sample data" can delete exactly
  those, and nothing the user created.

## 7. Navigation

- `HomeShell` holds the selected tab index and an `IndexedStack` of the three tab
  screens. `IndexedStack` keeps every tab alive, so the Trees search text and filter
  survive a tab switch.
- Under 840 px wide → `NavigationBar` at the bottom. Wider → `NavigationRail` on the
  side (responsive layout).
- Forms and details are pushed with `Navigator.push(MaterialPageRoute(...))`.
- Forms wrap their body in `PopScope`. If there are unsaved changes, the system back
  gesture or the close button shows a "Discard changes?" dialog instead of closing.
- The dashboard receives an `onOpenTab` callback, so its quick actions and "View all"
  links can switch tabs.

## 8. Theming and reusable widgets

- `AppColors` defines the palette (forest green, leaf green, warm off-white, status
  colours). `AppTheme.light()` builds the Material 3 `ThemeData` from it, including
  card, input, button and navigation styles. Screens rarely set colours themselves.
- Reusable widgets in `lib/widgets/`: `StatisticCard`, `TreeCard`, `TaskTile`,
  `HealthStatusBadge`, `EmptyState`, `SectionHeader`, `FormSection`,
  `DatePickerField`, `TreeIllustration` (a `CustomPainter`, so no image assets are
  needed) and `AppFeedback` (snackbars and confirmation dialogs).

## 9. Error handling summary

| Situation | Behaviour |
|---|---|
| Storage cannot be opened | In-memory fallback + dashboard warning banner |
| A save fails | State unchanged, red snackbar with the reason |
| Stored data corrupted | Bad records skipped, warning banner, rest of the data loads |
| Online species search fails | Message under the search box + offline results |
| Tree deleted while its details are open | "Tree not found" screen instead of a crash |
| Invalid form input | Inline error message; Save does nothing until fixed |
