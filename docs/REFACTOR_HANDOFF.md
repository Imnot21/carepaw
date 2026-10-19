# Refactor sweep — handoff doc (continue on the laptop)

Last updated: 2026-10-19 · Branch: `feature/neumorphism-design` · Head: `7817377`
Repo: https://github.com/Imnot21/carepaw

This doc is the continuation package for the ">800-line file sweep" (P2 maintainability work).
Read this first on the laptop, then continue from **Next target**.

---

## 1. Current state

- `feature/neumorphism-design` == `master` == `7817377` (doc-update commits may follow; check
  `git log --oneline -3` on the laptop to see the true head).
- Working tree clean. `flutter analyze` clean. `flutter test` green (9/9).
- Sweep canon (locked): **zero behavior change**, one file per commit, analyze + test each,
  live spot-check on the emulator before push, push = branch + fast-forward `master`.
- `carepawdemo` mirror branch intentionally **not** pushed.

## 2. What was changed in the sweep (so far)

Each split = one commit. Numbers are line counts at split time.

| # | File (before) | Result | Commit |
|---|---|---|---|
| 1 | `inventory_detail_page.dart` 1192 | page 209 (+ render fix later `d293869`) | `1d2b1d1` |
| 2 | `queue_page.dart` 1132 | page 254 + `widgets/queue_widgets.dart` 852 | `9d71e95` |
| 3 | `pet_detail_page.dart` 1127 | page 599 + `widgets/pet_detail_widgets.dart` 557 | `f5d9f4c` |
| 4 | `appointment_form_page.dart` 1107 | page 482 + `widgets/appointment_form_widgets.dart` 791 | `13ed209` |
| 5 | `staff_queue_page.dart` 1100 | page 437 + `widgets/staff_queue_widgets.dart` 679 | `fc75e1c` |
| 6 | `pet_list_page.dart` 1024 | page 46 + `widgets/pet_list_widgets.dart` 983 | `89d8d30` |
| 7 | `notification_list_page.dart` 925 | page 509 + `widgets/notification_list_widgets.dart` 475 | `7817377` |
| 8 | `medical_record_form_page.dart` 902 | page 625 + `widgets/medical_record_form_widgets.dart` 330 | `121fc2c` |

Latest split (#8) details:
- Mixed split: 3 builder methods extracted into widgets (`MedicalRecordPetHeader` from
  `_buildPetHeader`, `MedicalRecordTypeSelector` from `_buildTypeSelector` with an `onChanged`
  callback, `MedicalRecordFormField` from `_buildField` — 18 call sites renamed, `context:`
  args dropped, `svgAsset!` after null-check because widget fields lose null-promotion) + the
  two tail views moved with `MedicalRecord` prefixes (`MedicalRecordNotLoggedInView`,
  `MedicalRecordAccessDeniedView` — avoids the queue/notification `NotLoggedInView`/
  `AccessDeniedView` clashes).
- Zero-drift verified with 4 block checks: tail + all three method bodies line-identical to
  HEAD after reverting renames/replacements; 7 unused imports pruned.
- Live-checked the New Record form: pet header + type chip, type selector (Visit→Vaccination
  swapped the header chip and Diagnosis→Vaccines Given), validators block submit on an empty
  form (no Firestore write), back nav; logcat clean.

Previous split (#7) details:
- Mixed split: tail classes moved mechanically (`NotificationCreateDialog` + private state,
  `NotificationEmptyState`, `NotificationNotLoggedInView`), and the 184-line
  `_buildNotificationCard` method was extracted into `NotificationCard` (takes
  `typeColor`/`typeSvg` + `onViewDetails`/`onDelete`; the unused `highlightUnread` param was
  dropped). Page keeps tabs/bloc/route wiring + list sections.
- Verified with two block checks: tail region and card body are line-identical to HEAD after
  reverting renames/replacements.
- 8 unused imports pruned; live-checked all four tabs + both card states + View Details nav.

Previous split (#6) details:
- Moved private helpers became public with `super.key`: `PetListView`, `StaffPetListView`,
  `PetNotLoggedInView` (the `Pet` prefix avoids colliding with the owner-queue
  `NotLoggedInView` in `queue_widgets.dart`).
- `_PetListViewState`, `_StaffPetListViewState`, `_PetCard`, `_EmptyPetsView`,
  `_StaffPetCard` stayed file-private.
- Reverse-rename gotcha: `PetListView`/`StaffPetListView` are substrings of their State
  class names — protect state names with placeholders before renaming (same trick applies to
  any `Foo` + `FooState` pair, and to ctor lines when verifying).
- 16 unused imports pruned from the page; zero-drift verified; analyze clean; 9/9 tests;
  live-checked vet Patients tab incl. search filter + empty state.

Previous split (#5) details:
- Moved private helpers became public with `super.key`: `StatsBar`, `StaffQueueEntryCard`,
  `StaffNotLoggedInView`, `StaffAccessDeniedView`.
- `_StatItem`, `_PriorityControl`, `_priorityColor` stayed file-private (used only inside the
  widgets file).
- `Staff*` prefix avoids colliding with the owner-queue `NotLoggedInView`/`AccessDeniedView`
  in `queue_widgets.dart` (public class names must stay unique per package — checked with a
  scan before renaming).
- 4 unused imports pruned from the page; zero-drift verified (moved region byte-identical to
  HEAD after reverting the renames; see §5).

Demo-critical fixes shipped alongside the sweep (already on master):

| Fix | Commit |
|---|---|
| Stock aggregation synced across batch/stock-in/stock-out/adjustment | `2ed0071` |
| Form validation errors clear as you type | `f54564c` |
| Inventory detail card/header live-refresh after edits/stock ops | `e5afdb3` |
| NeuDialog default width crash + root navigator fixes | `6050f45` |
| Read-only NeuTextField `onTap` forwarding | `8e10526` |
| Inventory detail render (slivers → Column/Expanded) | `d293869` |
| Inventory detail/form route lost `InventoryBloc` (create flow hung) | `55e7a26` |

## 3. Next target

Re-derive the list at session start, then continue top-down:

```
Get-ChildItem -Recurse lib -Filter *.dart | ForEach-Object { $n=(Get-Content $_.FullName).Count; if($n -gt 800){ '{0,5}  {1}' -f $n, $_.FullName } } | Sort-Object -Descending
```

Remaining >800 files (as of `121fc2c`):

| File | Lines | Status |
|---|---|---|
| `features/pets/presentation/widgets/pet_list_widgets.dart` | 983 | second pass (widgets file) |
| `features/pets/presentation/pages/pet_form_page.dart` | 876 | **next** |
| `features/appointments/presentation/pages/appointment_list_page.dart` | 860 | pending |
| `features/queue/presentation/widgets/queue_widgets.dart` | 858 | maybe second pass |
| `features/inventory/presentation/pages/inventory_list_page.dart` | 853 | pending |
| `core/widgets/neomorphism/neu_icon_system.dart` | 853 | pending (shared widget — extra care) |
| `features/medical_records/presentation/pages/medical_record_list_page.dart` | 821 | pending |
| `features/home/presentation/pages/staff_dashboard_page.dart` | 832 | **reserve — after defense** |
| `features/scanning/presentation/pages/scan_list_page.dart` | 808 | **reserve — after defense** |
| `app/router/app_router.dart` | 826 | not a widget file — leave |

Secondary backlog item: clear the 20 source TODOs (P2), together with or after the sweep.

## 4. Split recipe (what has worked)

1. **Recon** — line count, CRLF + no-BOM check, top-level declarations, importers, which
   private classes are referenced from the page vs only from other helpers, name-uniqueness of
   the public names you intend to create.
2. **Mechanical move when possible** — if the file already has private widget classes, cut them
   byte-identically into `features/<f>/presentation/widgets/<page>_widgets.dart`:
   - page-referenced classes → public, drop the leading `_`, add `super.key` as first ctor param
     (multi-line ctors: insert `super.key,` right after `{`);
   - file-local helpers stay private;
   - if the obvious public name already exists in the feature, prefix context (`Staff...`);
   - doc comments directly above a class move with it.
3. **Scripted transform with count assertions** — every replacement asserts its expected
   occurrence count; never eyeball-edit.
4. **Non-mechanical fallback** (used for `appointment_form_page` when only `_buildXxx` methods
   existed): extract methods into stateless widgets, thread state via params + callbacks;
   replace build-time state mutation with local `effective*` vars + parent-write callbacks.
5. **File I/O discipline** — read/write with .NET: `[IO.File]::ReadAllText/WriteAllText(path,
   text, (New-Object System.Text.UTF8Encoding($false)))`; keep CRLF; files must stay BOM-free.
6. **Prune unused imports mechanically** — loop `flutter analyze`, delete flagged
   `import ...;` lines, re-analyze (script did up to 3 rounds).
7. **Verify zero drift** — extract the old region from the git blob
   (`git show HEAD:path`, remember `core.autocrlf=true` → blob is LF; normalize LF→CRLF),
   apply the same renames, compare case-sensitively with the new widgets file body → must be
   `True`.
8. **Gate** — `flutter analyze` clean → `flutter test` (9/9) → `flutter build apk --debug` →
   `adb install -r -d build\app\outputs\flutter-apk\app-debug.apk` → live spot-check →
   logcat clean.
9. **Ship** — commit `refactor(<feature>): split <page> into widgets` (body with before/after
   numbers), `git push origin feature/neumorphism-design`, `git push origin HEAD:master`
   (plain fast-forward; fetch/verify master == old head first). If master moved (e.g., user
   pushed config), rebase on top and use `--force-with-lease` **only** when master's extra
   commits are known and yours is a clean mirror — confirm with the user first.
10. **Book-keeping** — update claude-mem work-state list `carepaw-p2-sweep`
    (`sweep_progress`, `current_work`, `next_target`) and `save_memory` a short note with
    commit hash + evidence.

### Mechanical-split script skeleton (adapt per file)

```powershell
$ErrorActionPreference = 'Stop'
$crlf = [string][char]13 + [string][char]10
$uts8 = New-Object System.Text.UTF8Encoding($false)
$text = [IO.File]::ReadAllText($pagePath, [Text.Encoding]::UTF8)
if (-not $text.Contains($crlf)) { throw 'expected CRLF' }
if (($text -replace [regex]::Escape($crlf), '').Contains([string][char]10)) { throw 'mixed EOL' }
$lines = $text -split [regex]::Escape($crlf)
# boundary: first moved class, walk back over /// comments; part before = page, after = widgets
# asserts: class list in moved part, occurrence counts for every symbol you rename,
#          counts after rename, no leftover old names
# header for widgets file: flutter + go_router + feature entity + used neomorphism imports
# ctor edits: "  const X({" -> "  const X({`r`n    super.key,`r`n"  /  "const X();" -> "const X({super.key});"
[IO.File]::WriteAllText($widgetPath, ($widgetOut -join $crlf), $uts8)
[IO.File]::WriteAllText($pagePath, $pageText, $uts8)
```

Desktop-only helpers used so far (not in repo, recreate from this recipe if needed):
`C:\Users\PC\AppData\Local\Temp\opencode\{split_staffq,split_pet,prune_imports,verify_*}.ps1`.

### Gotchas learned

- Public StatelessWidget fields do not get null-promotion → use `!` after null-check, or make
  the field non-nullable.
- `required` is a reserved word — as a field name use `isRequired`.
- Watch the page tail for helpers still referenced (e.g., `_formatDate`/`_formatTime`) — don't
  move them unless every caller moves too.
- Keep dialog/sheet UI that mutates parent state in the page; only pure render widgets move.

## 5. Gate checklist (per file, copy-paste)

```powershell
flutter analyze            # expect: No issues found!
flutter test               # expect: All tests passed! (9/9)
flutter build apk --debug
adb install -r -d build\app\outputs\flutter-apk\app-debug.apk
adb shell am start -n com.example.carepaw/.MainActivity   # then spot-check the moved screen
```

Push policy: `git status` clean → commit → push branch → push `HEAD:master` → verify both
remote refs equal local HEAD.

## 6. Demo context (facts that must stay true)

- Demo accounts — do **not** modify/delete:
  - `vet@carepaw.com` / `Carepaw123` — OWNER_ADMIN (id 3); used for staff/vet flows in demos.
  - `admin@carepaw.com` / `Carepaw123` — PET_OWNER (Alex Rivera, id 2; fresh owner state).
  - `azazeljin69@gmail.com` — OWNER_ADMIN (id 12).
- Demo data (Firestore project `carepaw-93d16`): `inventoryItems/1` "Test SyrupV3" with
  `currentStock` 24.00 + batch `B-001` (24.00, expires Nov 6 2026). Keep it coherent.
- Live checks must **not write** to Firestore (no check-ins, no stock ops) so the demo data
  stays clean.
- Emulator AVD `carepaw_demo` (Android 16); package `com.example.carepaw`; the app session
  (login) persists across reinstalls.
- Reserve surfaces — untouched until after the defense: staff/vet/admin dashboards, scan,
  audit, users management.

## 7. Open items (user decisions / after defense)

- [ ] **claude-mem observer signed out** (`claude auth login` needed) — automatic memory
      capture is off until re-authenticated; manual `save_memory` + work-state still work.
- [ ] **Memory KG MCP path**: on the desktop `MEMORY_FILE_PATH` points at
      `C:\Users\six6six\...` which does not exist there → KG writes fail (ENOENT).
      Fix per machine (user's own config commit `65e875a`).
- [ ] `docs/DEMO_RUNSHEET.md` line ~51 is stale (Device Preview note — now opt-in, defaults
      off since `6d3efc7`). Optional doc fix after defense.
- [ ] "Add Batch" is only reachable from the Batches-tab empty state (UI affordance note).
- [ ] After defense: `scan_detail_page.dart` missing `BlocProvider.value` on push
      (red-screen bug), staff dashboard 1px overflow, delete-item TODO, inventory detail
      landscape tuning.

## 8. Desktop tool paths (reference only — laptop will differ)

- flutter: `E:\flutter_windows_3.35.1-stable\flutter\bin\flutter.bat`
- adb: `C:\Users\PC\AppData\Local\Android\Sdk\platform-tools\adb.exe`
- Firestore REST recipe (for data checks): Android apiKey in `lib/firebase_options.dart`,
  sign-in `vet@carepaw.com` / `Carepaw123`, project `carepaw-93d16`.

---

*Continue with §3 "next target": `pet_form_page.dart` (876 lines) — recon first.
Keep one commit per file and the §5 gate.*
