# Faculty Demo Guide

A 10–12 minute walkthrough that shows every feature in a logical order. Each step
lists what to do and what the examiner should see.

## Before the demo

1. Run `flutter test`. All tests should pass, and you can mention this.
2. Do a **fresh install** so the sample data appears. Either uninstall the app first,
   or run `flutter run` after clearing app data in Android settings.
3. Keep the phone or emulator in portrait mode. Optionally open the app in Chrome
   with `flutter run -d chrome` as a backup.

---

## Step 1 — Dashboard overview (1 min)

**Do:** open the app.

**Expected:**
- A green welcome card with today's date, a greeting and a summary sentence, e.g.
  *"2 trees need attention and 1 task is overdue."*
- Four statistic cards: **Trees planted 5**, **Healthy trees 3**, **Need attention 2
  (1 critical)**, **Pending tasks 5 (1 overdue)**.
- The **Tree health** bar split into green / amber / red, with "60% healthy".
- Scroll down: Quick actions, Upcoming watering, and Recently added trees.

**Say:** "None of these numbers are hardcoded. They are computed from stored data by
`DashboardStats.compute`, and they update instantly when data changes."

## Step 2 — Add a tree with validation (2 min)

1. Tap **Add tree** (quick action or the Trees tab button).
2. Tap **Save tree** immediately. **Expected:** red errors under *Tree name*,
   *Species* and *Plantation location*. Nothing is saved.
3. Fill in:
   - Tree name: `Canteen Arjuna`
   - Species: tap the field, type `arj`, choose **Arjuna** (*Terminalia arjuna*)
   - Planting date: keep today (future dates are blocked in the date picker)
   - Location: `Behind the canteen`
   - Health: **Needs Attention**
4. Tap **Save tree**.

**Expected:** you return to the list, a green snackbar says *"Canteen Arjuna" added
to your plantation*, and the new tree is at the top. On the Dashboard, *Trees
planted* is now 6 and *Need attention* is 3.

## Step 3 — Unsaved-changes protection (30 s)

Open **Add tree**, type a name, then press back or ✕.
**Expected:** a *"Discard changes?"* dialog. *Cancel* keeps you on the form;
*Discard* leaves.

## Step 4 — Search, filter and sort (1 min)

On the **Trees** tab:
1. Type `ficus` in search. **Expected:** only *Parking Peepal* (search also matches
   scientific names). Clear the search.
2. Tap the **Critical (1)** chip. **Expected:** only critical trees. Tap **All**.
3. Tap the sort icon (top right) → **Name (A–Z)**. **Expected:** the list is reordered.
4. Switch to Dashboard and back. **Expected:** the filter and sort are still applied
   (tab state is preserved).

## Step 5 — Tree details and editing (1.5 min)

1. Tap **Library Mango**. **Expected:** a header with species and scientific name,
   an amber *Needs Attention* badge, planting date with age, location, last watered,
   two maintenance tasks, and watering history.
2. Tap ✏️ (Edit), change health to **Healthy**, then **Save changes**.
   **Expected:** a snackbar "Tree details updated", the badge turns green, and the
   dashboard health bar changes.

## Step 6 — Record watering (1 min)

1. On the details screen tap **Record watering**.
2. Type `abc` in *Quantity* and save. **Expected:** "Enter a number".
3. Enter `10` litres and `15` minutes, then save.

**Expected:** "Watering recorded for Library Mango", *Watering history* gains a
`10 L · 15 min` entry, and *Last watered* shows now. The dashboard caption
"N waterings this week" increases by one.

**Say:** "This only records the activity. It does not control any irrigation hardware."

## Step 7 — Maintenance scheduling (2 min)

1. Open the **Maintenance** tab. **Expected:** Pending/Completed counts and a red
   "1 task is overdue" banner. The overdue task shows its due date in red.
2. Tap **New task**: Title `Check tree guard`, Type **General Maintenance**, assign
   **Parking Peepal**, due date in 3 days, then **Schedule task**.
   **Expected:** it appears in Pending, sorted by due date.
3. Tick the checkbox on **Inspect leaves for pests**. **Expected:** the snackbar
   "marked as completed", Pending count −1, Completed count +1, and the overdue
   banner disappears.
4. Switch to **Completed**. The task is shown struck through with its completion date.
5. Use the ⋮ menu on a task → **Delete** → confirm. It is removed.

## Step 8 — Delete a tree (45 s)

On **Parking Peepal** details tap 🗑️.
**Expected:** a confirmation dialog explaining that watering history and tasks are
also removed. *Cancel* does nothing; **Delete tree** removes it. Its tasks disappear
from Maintenance and the dashboard counts drop.

## Step 9 — Data persistence (1 min)

1. Fully close the app (swipe it away from recent apps).
2. Reopen it.

**Expected:** everything is exactly as you left it: the new tree, the edit, the
watering record, and completed or deleted tasks. Data is stored on the device with
`shared_preferences`.

## Step 10 — Sample data and offline behaviour (1 min)

1. Dashboard ⋮ → **Remove sample data** → confirm. **Expected:** records marked *Sample*
   are removed, together with anything you added to a sample tree (such as the
   watering from Step 6). *Canteen Arjuna* (yours) remains.
2. ⋮ → **Load sample data** brings them back.
3. Turn on **airplane mode**. Add a tree, then in the species picker tap
   **Search online**. **Expected:** a message that the online service could not be
   reached; offline species are still listed and the tree can be saved.

---

## Likely viva questions

| Question | Short answer |
|---|---|
| Which state management did you use and why? | Provider with `ChangeNotifier`. It is simple, officially recommended for small apps, and keeps one source of truth. |
| How is data persisted? | JSON lists in `shared_preferences` via `LocalStorageService`. Each save happens before the UI updates. |
| What if stored data is corrupted? | Each record is parsed in `try/catch`. Bad ones are skipped and a warning is shown; the rest loads. |
| How do the dashboard numbers update? | The dashboard `watch`es both providers and recomputes `DashboardStats` on every change. |
| How do you prevent invalid data? | `Form` + `TextFormField` validators, a date picker limited to valid ranges, and numeric validation for watering amounts. |
| What happens to tasks when a tree is deleted? | `PlantationActions.deleteTree` deletes its tasks and watering records first, so nothing points to a missing tree. |
| Does it need the internet? | No. Only the optional online species search uses it, and it falls back to the offline catalogue. |
| How did you test it? | 63 automated unit and widget tests using in-memory storage and mocked HTTP (`flutter test`). |
