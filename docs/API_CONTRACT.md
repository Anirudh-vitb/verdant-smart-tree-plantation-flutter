# API Contract

This app has **no backend of its own**. It has two kinds of "API":

1. **Local service APIs**: Dart classes the UI calls for storage and species lookup.
   These are fully implemented and tested.
2. **One optional external HTTP API**: the public GBIF Species API, used only by the
   "Search online" button in the species picker.

Every core feature works without internet.

---

## 1. Local storage service

`lib/services/local_storage_service.dart`

| Method | Returns | Notes |
|---|---|---|
| `loadTrees()` | `LoadResult<Tree>` | `items` = valid records, `skipped` = unreadable records |
| `loadTasks()` | `LoadResult<MaintenanceTask>` | same |
| `loadWaterings()` | `LoadResult<WateringRecord>` | same |
| `saveTrees(List<Tree>)` | `Future<void>` | Replaces the whole list. Throws `StorageException` on failure |
| `saveTasks(List<MaintenanceTask>)` | `Future<void>` | same |
| `saveWaterings(List<WateringRecord>)` | `Future<void>` | same |
| `isInitialized` | `bool` | `false` only before first-run seeding |
| `markInitialized()` | `Future<void>` | |

Storage keys and formats are listed in [ARCHITECTURE.md §5](ARCHITECTURE.md#5-persistence-libserviceslocal_storage_servicedart).

### Stored JSON shapes

```json
// Tree
{
  "id": "tree-mf3k2p1a-1",
  "name": "Library Mango",
  "species": "Mango",
  "scientificName": "Mangifera indica",
  "plantedOn": "2026-05-25T00:00:00.000",
  "location": "Library lawn, north side",
  "health": "needsAttention",
  "notes": "Leaves yellowing at the edges.",
  "createdAt": "2026-05-25T00:00:00.000",
  "updatedAt": "2026-05-25T00:00:00.000",
  "isDemo": false
}

// WateringRecord
{
  "id": "water-mf3k9q2b-2",
  "treeId": "tree-mf3k2p1a-1",
  "wateredAt": "2026-10-22T08:00:00.000",
  "quantityLitres": 12.0,
  "durationMinutes": null,
  "notes": "",
  "isDemo": false
}

// MaintenanceTask
{
  "id": "task-mf3kab7c-3",
  "title": "Apply organic compost",
  "type": "fertilizing",
  "treeId": "tree-mf3k2p1a-1",
  "dueDate": "2026-10-26T00:00:00.000",
  "notes": "",
  "isCompleted": false,
  "completedAt": null,
  "createdAt": "2026-10-16T00:00:00.000",
  "updatedAt": "2026-10-16T00:00:00.000",
  "isDemo": false
}
```

Allowed enum values:
- `health`: `healthy`, `needsAttention`, `critical`
- `type`: `watering`, `fertilizing`, `pruning`, `inspection`, `general`

An unknown enum value, a missing required field or a wrong type makes `fromJson`
throw. The storage service then skips that record (see the corruption tests in
`test/storage_test.dart`).

---

## 2. Species service

`lib/services/species_service.dart`

```dart
abstract class SpeciesService {
  List<Species> searchLocal(String query);              // offline, synchronous
  Future<SpeciesSearchResult> searchOnline(String query); // may use the network
}

class SpeciesSearchResult {
  final List<Species> species;
  final SpeciesSource source;   // local | gbif
  final String? message;        // explanation when a fallback happened
}
```

| Implementation | Behaviour |
|---|---|
| `LocalSpeciesService` | Searches the 30-entry offline catalogue (`lib/data/species_catalogue.dart`) by common, scientific or family name. `searchOnline` just returns local results with a "disabled" message. Used in tests. |
| `GbifSpeciesService` | Same offline search; `searchOnline` calls GBIF (below) and falls back to the offline list on any problem. Used by the app (`main.dart`). |

---

## 3. External API: GBIF Species "suggest"

- **Provider:** Global Biodiversity Information Facility (GBIF), a free and open
  biodiversity data service.
- **Documentation:** <https://techdocs.gbif.org/en/openapi/v1/species>
- **Authentication:** none (no API key). **Cost:** free.

### Request

```
GET https://api.gbif.org/v1/species/suggest?q=<search text>&rank=SPECIES&limit=20
```

| Parameter | Value | Meaning |
|---|---|---|
| `q` | user's text (≥ 3 characters) | name to search for |
| `rank` | `SPECIES` | only species-level names |
| `limit` | `20` | maximum results |

Queries shorter than 3 characters are **not** sent; the app searches offline instead.

### Expected response (fields the app reads)

A JSON **array** of name-usage objects, for example:

```json
[
  {
    "key": 2878688,
    "scientificName": "Quercus robur L.",
    "canonicalName": "Quercus robur",
    "rank": "SPECIES",
    "kingdom": "Plantae",
    "family": "Fagaceae"
  }
]
```

Parsing rules (`GbifSpeciesService.parseSuggestResponse`):
- Results whose `kingdom` is present and not `Plantae` are ignored (GBIF also contains animals and fungi).
- The name is `canonicalName`, falling back to `scientificName`; entries without either are ignored.
- Duplicate names are removed.
- A body that is not a JSON array is treated as an error.

### Error handling and offline fallback

| Situation | What the user sees |
|---|---|
| No internet / DNS failure / connection refused | "Could not reach the online service. Showing the offline catalogue instead." |
| No response within **8 seconds** | "Online search timed out. …" |
| HTTP status other than 200 | "Online service returned <code>. …" |
| Body is not the expected JSON | "Online service sent an unexpected response. …" |
| Zero plant matches | "No online matches found. …" |

In every case the offline matches are shown and the user can still choose a species,
or type a custom name with **Use "…"**.

### Limitations and verification status

- GBIF returns **scientific names**, not local common names. An online result is
  stored with the scientific name in both name fields.
- GBIF is a public service. Its availability, rate limits and response format are
  outside this project's control.
- **Not verified against the live service.** The development environment's
  network policy blocked `api.gbif.org`, so the client was tested only with mocked
  HTTP responses that follow GBIF's documented format
  (`test/species_service_test.dart`). Test **Search online** on a device with
  internet before presenting it as a working online feature. If it does not
  respond, the offline catalogue still works.
- Android: the `INTERNET` permission is declared in
  `android/app/src/main/AndroidManifest.xml` so the lookup also works in release builds.
