# CarePaw Frontend Overhaul — Master Plan

Target: every page in `lib/features/**/presentation/pages/` + the shell.
Method: impeccable (Operate mode) + design-taste-frontend, applied to the
direction pinned in `PLAN_NEUMORPHISM.md`.
Status: **planning**. No page is edited until Phase 0 lands.

---

## 0. Read this first — the direction conflict

`PLAN_NEUMORPHISM.md` asks for neumorphism. `DESIGN.md` and `PRODUCT.md`
record that this app **already shipped** neumorphism, and that it was
deliberately replaced with a flat hairline system because:

- dense clinical screens (queue positions, batch expiry, record timelines)
  lost their edges and read as one blurred mass
- hairlines were invisible against the white highlight shadow
- contrast degraded as data density rose

The code confirms that history: `NeuShadow` currently has no card shadow at
all, and `NeuStyle.shadow` is documented as "Legacy. Ignored by the flat
system."

**Resolution used in this plan:** the user has read §0 and chosen the **full
revival** — strong dual light/dark shadows on every surface, as
`PLAN_NEUMORPHISM.md` originally specified. That is the brief; this plan
executes it at full strength. The first attempt's failure is treated as a
craft problem to be solved through calibrated shadow values rather than by
backing away from the aesthetic. §2 defines the calibration.

---

## 1. What is actually broken right now

Measured, not guessed.

| # | Defect | Evidence | Severity |
|---|--------|----------|----------|
| 1 | **Nunito text styles bake in light-mode colour.** `AppTextStyles.display* / headline* / number* / appBarTitle` all hardcode `color: AppColors.textPrimary` (`#111111`). Pages that don't override render near-black on the `#1A1A1A` dark canvas. | `app_text_styles.dart:22,31,40,49,58,67,143,179,188` · 65 usages, most with no `color:` — e.g. `queue_page.dart:132,264,973`, `staff_queue_page.dart:149,190,297,957` | **BLOCKER** |
| 2 | Pages patch #1 with hand-rolled ternaries instead of one fix. | `inventory_detail_page.dart:141,298,491,622,794` all repeat `_isDark ? AppColors.textPrimaryOnDark : AppColors.textPrimary` | MAJOR |
| 3 | `TextStyleX` helpers hardcode light colours too (`subtle`, `muted`, `link`, `primary`, `primaryGradient`, `primaryGlow`, `successText`, `error`…). | `app_text_styles.dart:207-305` | MAJOR |
| 4 | Raw `Colors.white` / `Colors.grey` / `Colors.black` bypass the palette. | 15 sites across 12 files — `staff_queue_page.dart:184,1005`, `queue_page.dart:1021`, `medical_record_list_page.dart:521,526`, `inventory_list_page.dart:663`, `appointment_list_page.dart:861`, `appointment_detail_page.dart:508`, `medical_record_detail_page.dart:80,85`, `medical_record_form_page.dart:816`, `inventory_form_page.dart:532`, `vet_dashboard_page.dart:103`, `staff_dashboard_page.dart:107`, `admin_dashboard_page.dart:85`, `scan_list_page.dart:785` | MAJOR |
| 5 | Magic numbers instead of tokens. | 642 literal `SizedBox(height/width: n)`, 408 literal `EdgeInsets.*` calls in `lib/features` | MAJOR |
| 6 | No shared page/state primitives — every page reinvents scaffold, section header, empty state, error state, stat tile, status badge. | 38 pages, 36 of them >300 lines with private `_build*` duplicates | MAJOR |
| 7 | Density varies page to page: page padding is 20, 24, 28, or 20-and-8 in different files. | `home_page.dart:125` (20/8/24) vs `login_page.dart:116` (28/40) | MINOR |
| 8 | Snackbars are hand-built per page with duplicated shape/margin literals. | `login_page.dart:90-108` and siblings | MINOR |

---

## 2. The neumorphism calibration

Full revival: every surface is extruded from the canvas with a dual shadow —
a light source from the top-left, depth falling to the bottom-right. The canvas
stays the warm bone `#F8F5F0` and the accent stays terracotta `#E27D60`, so the
app keeps the CarePaw identity while gaining the soft, tactile, organic surface
language.

The previous attempt failed because its shadow values were unbounded, not
because extrusion was wrong. So every number is calibrated, and the calibration
is a token, not a per-call-site guess.

**The dual shadow, on every plane:**

| Plane | Fill | Light source (top-left) | Depth (bottom-right) |
|---|---|---|---|
| `raised` — card | `surface` | `offset(-6,-6)` blur 14, white 0.85 | `offset(6,6)` blur 14, `#B8AE9E` 0.55 |
| `pressed` | `surfaceMuted` | `offset(-3,-3)` blur 6, `#B8AE9E` 0.35 | `offset(3,3)` blur 6, white 0.55 |
| `inset` — field, track | `surfaceInset` | `offset(-4,-4)` blur 10, `#B8AE9E` 0.40 | `offset(4,4)` blur 10, white 0.70 |
| `flat` — grouping | `surfaceMuted` | none | none |
| `transparent` | — | none | none |
| `floating` — FAB, nav, sheet, dialog | `surface` | none | `offset(0,10)` blur 28, `#7A6E5E` 0.32 |

Values that keep it legible rather than mushy:

1. **The depth shadow is tinted, never neutral gray.** `#B8AE9E` is the canvas
   hue darkened — a pure gray shadow on `#F8F5F0` reads as dirt.
2. **Blur ≥ 2× distance.** A tight shadow reads as a hard bevel; a soft one
   reads as a lit surface. `distance 6 / blur 14` is the floor.
3. **Hairlines are dropped, not kept.** In a fully extruded world a border and a
   highlight fight each other. Edges come from the shadow pair alone — this is
   the difference between conviction and compromise. Status-critical rows (queue
   position, batch expiry) still earn a hairline, because those are the rows
   where an edge carries data, not decoration.
4. **Radius grows.** Cards 24 (up from 14) — larger radii suit extruded
   surfaces, because a tight radius makes the highlight terminate awkwardly.
   Buttons and chips stay pill.
5. **Press swaps the shadow pair, never scales.** `raised` → `pressed` inverts
   which side is lit, so the card appears to sink into the canvas. Scale only on
   buttons and chips, at 0.97.
6. **Dark mode drops the light source entirely.** A white highlight on charcoal
   describes a light source that does not exist. Dark mode gets a single
   bottom-right black shadow at 0.50 plus a faint top-left `#3A3735` rim.
7. **Text never sits on the highlight side.** Body copy resolves to
   `textPrimary`; a `#111111` label on the top-left highlight zone is where the
   original washed out.

### Contrast budget

Extrusion spends contrast. These are hard limits, checked in Phase 12:

| Pair | Minimum |
|---|---|
| body text on any plane | 4.5:1 |
| labels, chips, badges, axis text | 4.5:1 |
| icons and non-text UI | 3:1 |
| card fill vs canvas | ≥ 1.15:1 lightness step |

A plane that cannot hold its contrast budget gets a deeper fill step, not a
weaker shadow — the shadow is the aesthetic, the fill is the safety valve.

---

## 3. PHASE 0 — Foundation (blocking; do this alone)

Nothing else is safe to start until this lands, because every phase inherits
these.

### 0.1 Fix text colour inheritance — the blocker
- `app_text_styles.dart`: strip `color:` from `displayLarge/Small/Medium`,
  `headlineLarge/Medium/Small`, `appBarTitle`, `numberLarge/Medium`. They then
  inherit the ambient `DefaultTextStyle` / `colorScheme.onSurface`.
- Rework `TextStyleX` so colour helpers are brightness-aware instead of
  hardcoded: `subtleOf(brightness)` already exists — make `subtle`, `muted`,
  `link`, `primary` resolve through it, and add `AppTextStyles.resolve(context)`
  style accessors for the cases that need a real context.
- `AppColors.link/primary` helpers stay for explicit cases.
- **Result:** all 65 dark-mode bugs fixed at once, and the 5 manual ternaries in
  `inventory_detail_page.dart` become deletable.

### 0.2 New shared primitives — `lib/core/widgets/neomorphism/`
| File | Widgets | Solves |
|---|---|---|
| `neu_page.dart` | `NeuPage`, `NeuPageAppBar` | scaffold, background, safe area, one page padding, one max content width |
| `neu_section.dart` | `NeuSection`, `NeuSectionHeader` | heading + optional action + consistent gap |
| `neu_state.dart` | `NeuEmptyState`, `NeuErrorState`, `NeuLoadingList` | the three states every page rewrote |
| `neu_stat.dart` | `NeuStatTile`, `NeuStatGrid` | dashboard metric tiles |
| `neu_badge.dart` | `NeuStatusBadge` + status→colour map | appointment/queue/batch status, one semantic source |
| `neu_row.dart` | `NeuListRow` | replaces raw `ListTile` |
| `neu_feedback.dart` | `NeuToast.success/error/info` | one snackbar shape, no per-page literals |
| `neu_filter_bar.dart` | `NeuFilterBar` | search + filter chips, one layout |

Export all from `index.dart`.

### 0.3 Restore the extruded shadow system — `neu_shadows.dart` + `design_tokens.dart` + `neu_container.dart`
- `NeuShadow` gains a paired `extruded()` used by `raised`, and re-inverted
  pairs for `pressed` and `inset`, exactly as tabulated in §2. `floating` stays
  single. All values come from tokens.
- Add tokens: `shadowExtrudeDistance`, `shadowExtrudeBlur`, `shadowExtrudeDarkOpacity`,
  `shadowExtrudeLightOpacity`, `shadowInsetDistance`, `shadowInsetBlur`,
  `shadowFloatingBlur`, plus layout tokens `pagePadding`, `sectionGap`,
  `cardPadding`, `maxContentWidth`.
- `radiusMd` 14 → **24**; `radiusLg` 20 → **28**; `radiusSm` 10 → **14**.
- `NeuContainer`: `raised` draws the extruded pair and drops its default hairline;
  `inset` fills and inverts the pair; `pressed` inverts; `flat` stays bare.
- `NeumorphicStyle.shadow` becomes live again.
- `app_colors.dart`: canvas and fills stay warm bone / terracotta per the brief.
  `border` is demoted to a data-row-only token (§2 rule 3).

### 0.4 Gate
`flutter analyze` clean. Nothing else starts until this passes.

---

## 4. PHASES 1–11 — Page by page

Each phase ends with `flutter analyze` clean and both brightness modes checked.
Each phase follows the same per-page checklist:

1. Wrap in `NeuPage`; delete the bespoke `Scaffold` + `SafeArea` + padding.
2. Replace the app bar with `NeuPageAppBar` (title, optional subtitle, actions).
3. Collapse duplicated `_build*` sections into `NeuSection`.
4. Route every colour through `ThemeColors` — zero raw `Colors.*`, zero raw
   `AppColors.*` outside species-accent lookups.
5. Replace raw Material widgets with the `Neu*` equivalent (`TextButton` →
   `NeuButton variant: text`, `ListTile` → `NeuListRow`, `CircleAvatar` →
   `NeuAvatar`, raw `TextField` → `NeuTextField`, `showDialog` → `NeuDialog`,
   `showModalBottomSheet` → `NeuBottomSheet`, `FloatingActionButton` → `NeuFAB`,
   `LinearProgressIndicator` → `NeuProgress`).
6. Replace magic numbers with `NeuTokens`.
7. Wire the three states: `NeuLoadingList` / `NeuEmptyState` / `NeuErrorState`.
8. A11y: 48dp minimum targets, tooltip on every icon-only control, `Semantics` on
   status badges and stat tiles.
9. Update `pet_utils.dart` / `medical_record_utils.dart` helpers as they come up.

| Phase | Surface | Files | Establishes |
|---|---|---|---|
| 1 | Auth | `login_page`, `register_page`, `forgot_password_page`, `reset_password_page` | form + card standard, toast feedback |
| 2 | Shell + owner home | `app_shell`, `role_tabs`, `home_page` | nav, greeting header, quick-link rows |
| 3 | Dashboards | `admin_dashboard_page`, `vet_dashboard_page`, `staff_dashboard_page`, `admin_settings_page` | `NeuStatTile` grid, settings row list |
| 4 | Pets | `pet_list_page`, `pet_detail_page`, `pet_form_page`, `pet_utils.dart` | species avatar treatment, list card |
| 5 | Appointments | `appointment_list_page`, `appointment_detail_page`, `appointment_form_page` | `NeuStatusBadge` lifecycle |
| 6 | Queue | `queue_page`, `staff_queue_page` | **the proof screen** — dense data must stay crisp |
| 7 | Medical records | `medical_record_list_page`, `medical_record_detail_page`, `medical_record_form_page` | append-only timeline |
| 8 | Inventory | `inventory_list_page`, `inventory_detail_page`, `inventory_form_page`, `batch_card.dart`, `transaction_card.dart` | expiry urgency colour ladder |
| 9 | Scanning | `scan_list_page`, `scan_detail_page`, `scan_camera_page` | human-verification callout |
| 10 | Notifications | `notification_list_page`, `notification_detail_page`, `notification_settings_page` | settings toggles |
| 11 | Admin + users | `admin_user_management_page`, `profile_page`, `admin_audit_page` | role badge, audit row |

---

## 5. PHASE 12 — Cross-cutting sweep

- **Dark mode:** toggle both brightness on all 38 pages. The Phase 0 fix should
  make this a verification pass, not a repair pass.
- **Contrast audit:** WCAG AA on every text/background pair the sweep produced,
  including neumorphic pressed and inset states.
- **Density lock:** one page padding, one section gap, one card padding app-wide.
- **A11y pass:** tap targets, tooltips, semantics, focus order.
- **Docs:** rewrite `DESIGN.md` for the new world (it currently documents the
  flat system and will be stale), update `PRODUCT.md` brand commitment, add
  `lib/core/widgets/neomorphism/README.md`.

---

## 6. Definition of done

- [ ] 38 pages + 2 shell files migrated
- [ ] Zero raw `Colors.white/black/grey` in `lib/features`
- [ ] Zero raw `AppColors.*` in page/widget code except species-accent lookup
- [ ] Zero literal spacing/radius numbers outside `NeuTokens`
- [ ] Every page renders correctly in light **and** dark
- [ ] Every page has loading, empty, and error states
- [ ] `flutter analyze` clean
- [ ] `DESIGN.md` matches the shipped world
