# Syllabus Mapping

This maps common topics from a third-year B.Tech **Full Stack / UI Design with
Flutter** course to the code that demonstrates them. The exact syllabus was not
provided, so check this table against your own syllabus. The last section lists
topics this project does **not** demonstrate, so you don't over-claim during
evaluation.

## 1. UI design principles

| Concept | Where it is demonstrated |
|---|---|
| Consistent visual language (colour palette, typography, spacing, corner radius) | `lib/core/theme/app_colors.dart`, `lib/core/theme/app_theme.dart` (`AppSpacing` tokens, Material 3 `ThemeData`) |
| Visual hierarchy | Dashboard: hero welcome card → key numbers → chart → actions → lists (`lib/screens/dashboard/dashboard_screen.dart`) |
| Colour as meaning (status colours with icon + text, not colour alone) | `lib/widgets/health_status_badge.dart` (`HealthStatusStyle` extension) |
| Accessible contrast and touch targets | Status colour pairs chosen for contrast (`app_colors.dart`); 48 px minimum button height (`app_theme.dart`) |
| Screen-reader support | `Semantics` labels on statistic cards, badges, health chart and section headers; `semanticLabel` on task checkboxes; tap-to-open fields marked as buttons (`lib/widgets/form_fields.dart`) |
| Feedback states: loading, empty, success, error | `EmptyState` widget, snackbars and dialogs in `lib/widgets/feedback.dart`, loading spinner on Save, warning banners on the dashboard |
| Purposeful animation | Animated counters (`TweenAnimationBuilder`) in `statistic_card.dart`; `AnimatedContainer` in the health bar; `Hero` transition of the tree avatar from list to details |
| Custom graphics without image assets | `lib/widgets/tree_illustration.dart` (`CustomPainter`) |

## 2. Flutter widgets

| Concept | Examples in this project |
|---|---|
| Stateless vs Stateful widgets | `TreeCard`, `StatisticCard` (stateless); `TreesScreen`, `TreeFormScreen`, `HomeShell` (stateful) |
| Reusable custom widgets | `lib/widgets/` (badge, cards, task tile, empty state, section header, form section, date field) |
| Material components | `Scaffold`, `AppBar`, `Card`, `ListTile`, `FloatingActionButton.extended`, `ChoiceChip`, `FilterChip`, `SegmentedButton`, `PopupMenuButton`, `NavigationBar`, `NavigationRail`, `AlertDialog`, `SnackBar`, `showModalBottomSheet`, `showDatePicker`, `showTimePicker` |
| `const` constructors and immutability | All model classes and most widgets |

## 3. Layouts and responsive design

| Concept | Where |
|---|---|
| Row / Column / Expanded / Wrap / Stack | Throughout; e.g. `TreeCard`, quick actions row, health legend `Wrap` |
| Scrollable lists (`ListView`, `ListView.separated`, horizontal lists) | Trees list, maintenance list, horizontal filter chips |
| `LayoutBuilder` responsive grid | Dashboard statistic grid switches 2 ↔ 4 columns (`_StatsGrid`) |
| Adaptive navigation by screen width | `lib/screens/shell/home_shell.dart` (`MediaQuery` ≥ 840 px → `NavigationRail`) |
| Overflow safety | `maxLines` + `TextOverflow.ellipsis` on all list text; `SafeArea`; keyboard-aware bottom sheets (`viewInsets`) |

## 4. Forms and validation

| Concept | Where |
|---|---|
| `Form` + `GlobalKey<FormState>` + `TextFormField` validators | `lib/screens/trees/tree_form_screen.dart`, `lib/screens/maintenance/task_form_screen.dart`, `lib/screens/trees/record_watering_sheet.dart` |
| Custom `FormField` (non-text input that still validates) | `DatePickerField` in `lib/widgets/form_fields.dart`; species field in `tree_form_screen.dart` |
| Dropdown selection | `DropdownButtonFormField` for task type, linked tree, and tree in watering sheet |
| Searchable selector | `lib/screens/trees/species_picker_sheet.dart` |
| Date and time pickers with valid ranges | Planting date (not in future), due date (not in past for new tasks), watering date + time |
| Numeric validation | Watering quantity (decimal, 0–1000) and duration (whole minutes, 0–600) |
| Add vs edit mode with one form | `TreeFormScreen(existing: …)`, `TaskFormScreen(existing: …)` |
| Unsaved-changes protection | `PopScope` + "Discard changes?" dialog in both forms |

## 5. Navigation and routing

| Concept | Where |
|---|---|
| Tab navigation preserving state | `IndexedStack` in `HomeShell` |
| Imperative navigation (`Navigator.push` / `pop` with result) | `lib/screens/trees/tree_actions.dart`, `lib/screens/maintenance/task_actions.dart` |
| Passing data between screens | `TreeDetailsScreen(treeId: …)`, `TaskFormScreen(initialTreeId: …)` |
| Modal routes | Bottom sheets (species picker, record watering) and dialogs |
| Back-button handling | `PopScope` in `HomeShell` (back returns to Dashboard) and in forms |

## 6. State management

| Concept | Where |
|---|---|
| `ChangeNotifier` + `notifyListeners()` | `lib/providers/tree_provider.dart`, `lib/providers/maintenance_provider.dart` |
| `MultiProvider` / dependency injection | `lib/app.dart` |
| `context.watch`, `context.read`, `context.select` | Screens (`watch` to rebuild), action handlers (`read`), dashboard menu (`select`) |
| Single source of truth and derived state | Dashboard numbers derived by `DashboardStats.compute`; list filtering by `TreeQuery` |
| Local (ephemeral) widget state | Search text and filters in `TreesScreen`, segmented filter in `MaintenanceScreen` |

## 7. Application architecture

| Concept | Where |
|---|---|
| Layered architecture (UI → state → services → models) | See `docs/ARCHITECTURE.md` |
| Separation of concerns | No storage or HTTP code in widgets; models are plain Dart |
| Abstraction via interfaces | `KeyValueStore` (SharedPreferences vs in-memory), `SpeciesService` (offline vs GBIF) |
| Model serialization (JSON) | `toJson` / `fromJson` in `lib/models/*.dart` |
| Defensive programming / error handling | Corrupted-data skipping, save-before-update, storage fallback, network fallback |

## 8. Data persistence

| Concept | Where |
|---|---|
| Local key-value storage | `shared_preferences` via `lib/services/local_storage_service.dart` |
| Versioned storage keys and first-run initialisation | `verdant.*.v1` keys; `PlantationActions.seedIfFirstRun` |
| Referential integrity (cascade delete) | `PlantationActions.deleteTree`, `removeDemoData` |

## 9. API integration (client side)

| Concept | Where |
|---|---|
| HTTP GET with query parameters | `GbifSpeciesService.searchOnline` (`package:http`) |
| JSON parsing of an external response | `GbifSpeciesService.parseSuggestResponse` |
| Timeouts, error handling, offline fallback | Same file; documented in `docs/API_CONTRACT.md` |
| Testing HTTP with a mock client | `test/species_service_test.dart` (`MockClient`) |

> The live GBIF endpoint could not be reached from the development environment.
> The integration is tested with mocked responses only. See `docs/API_CONTRACT.md`.

## 10. Testing

| Concept | Where |
|---|---|
| Unit tests for models, logic and services | `test/models_test.dart`, `test/tree_query_test.dart`, `test/dashboard_stats_test.dart`, `test/storage_test.dart`, `test/providers_test.dart`, `test/species_service_test.dart` |
| Widget / UI tests | `test/widgets_test.dart` (forms, navigation, dialogs, lists) |
| Test doubles (in-memory store, failing store, mock HTTP, fixed clock) | `test/test_helpers.dart`, `test/species_service_test.dart` |
| Static analysis | `flutter analyze` with `flutter_lints` (`analysis_options.yaml`) |

## 11. Not demonstrated by this project

Be careful **not** to claim these during evaluation:

- **Server-side development.** There is no backend server, REST API of our own, or
  server-side language (Node.js, Express, Django, etc.).
- **Remote database** (Firebase, MongoDB, MySQL). Persistence is on-device only.
- **Authentication / authorization.** There are no user accounts or login.
- **Cloud deployment / hosting.**
- **Named routes / `go_router` / deep links.** Navigation uses `Navigator.push` with `MaterialPageRoute`.
- **Other state-management libraries** (BLoC, Riverpod, GetX).
- **Platform-specific native code** (Kotlin/Swift method channels), camera, GPS or notifications.
- **Integration tests on a real device** (`integration_test` package). Only unit and widget tests are included.
- **Internationalisation.** The UI is English only.
