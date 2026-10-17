---
target: clinic dashboard (operator flow)
total_score: 30
max_score: 40
na_heuristics: 
p0_count: 0
p1_count: 2
target_identity: "file:D:\\Desktop\\carepaw\\lib\\features\\home\\presentation\\pages\\clinic_dashboard_page.dart"
target_fingerprint: "sha256:9f71e790b97bfe0a14a82886357ba3746bf1c9404ae5980c91b350c3490339fd"
target_path: "D:\\Desktop\\carepaw\\lib\\features\\home\\presentation\\pages\\clinic_dashboard_page.dart"
timestamp: 2026-10-17T08-18-19Z
slug: entation-pages-clinic-dashboard-page-dart-9cf2df6f
---
**Method: design review only (detector not applicable, native platform)**

# Critique — Clinic Dashboard (operator flow)

**Target:** `lib/features/home/presentation/pages/clinic_dashboard_page.dart` — plus the flow it opens: bookings, line (queue), patients, records, stock, scan, notifications.

## Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 3 | Skeletons, toasts, confirm dialogs exist flow-wide; the dashboard itself shows zero live clinic state and has no refresh affordance |
| 2 | Match System / Real World | 3 | "Bookings / Line / Patients / Stock / Scan" is genuine clinic vocabulary — but "Records" duplicates "Patients'" destination, breaking the mental model |
| 3 | User Control and Freedom | 3 | Back navigation everywhere, no trapped states, confirmations before destructive actions; no undo (confirm instead) |
| 4 | Consistency and Standards | 4 | One surface system end-to-end: clay icons, token-driven extrusion, unified accents; dashboard press feedback matches the rest |
| 5 | Error Prevention | 3 | Validation + confirmations + strict appointment/queue transitions; no autosave/draft recovery on long forms |
| 6 | Recognition Rather Than Recall | 3 | Tiles are labeled, icon buttons tooltipped, filters visible; "Line" and "Records" ask a first-timer to infer |
| 7 | Flexibility and Efficiency | 3 | Search, filters, pagination on lists; no dashboard refresh gesture, no batched check-in from home |
| 8 | Aesthetic and Minimalist Design | 3 | Clean and cohesive — but the dashboard is underfurnished rather than rich; six equal tiles earn their pixels weakly |
| 9 | Error Recovery | 3 | Friendly error copy now standardized, error states carry actions, forms preserve input; recovery is generic rather than specific |
| 10 | Help and Documentation | 2 | About page exists; nothing contextual at decision points |
| **Total** | | **30/40** | **Good** |

## Design Specificity Verdict

**LLM assessment:** The flow has an authored identity — clay pictograms, warm bone canvas, terracotta reserved for action, paper-aligned vocabulary. The clinic's *differentiators* (live queue, verification-first scanning, traceable stock) are, however, invisible on the operator landing: it is a 6-tile launcher in a 3×2 grid — a structure any tool app could ship unchanged. The dashboard loads **no feature data at all** (only the auth state crosses it): no waiting count, no today's bookings, no low-stock warning. The paper system it mirrors ("PILA VET HUB") exists precisely to hold the clinic's state at a glance; the digital version currently holds only the menu. The owner home (`home_page.dart`) is richer — primary action card, pet summary, upcoming appointments, quick links — which makes the operator home read as the *thinner* product surface despite being the primary target.

**Deterministic scan:** not applicable (native platform).

## Overall Impression

Strong system, thin landing. The visual language finally reads as one voice and the copy is clinic-native; the single biggest opportunity is turning the operator home from a menu into the clinic's pulse — live numbers on or above the tiles — and resolving the Records/Patients collision, which is the one place the IA actively lies.

## What's Working

1. **Clinic-native vocabulary** — "Bookings / Line / Patients / Stock / Scan" maps to the paper workflow the operator already runs; no generic "Dashboard / Items / Records Management".
2. **One surface voice** — clay icon set, token-driven dual extrusion, text-safe terracotta hold across both modes; the icon migration removed the last mixed-family pockets.
3. **Feedback plumbing is real** — skeletons, empty states, toasts, confirm dialogs, and (as of this session) non-leaking error copy exist across the flow, not just on hero screens.

## Priority Issues

- **[P1] The landing is a launcher, not a dashboard.** No live clinic state anywhere on it (no data blocs load); six equal tiles give a flat hierarchy; the product's differentiator (real-time line) is one tap away, not zero taps away.
  **Why it matters:** the operator must re-enter the Line tab to answer "how many are waiting?", the most frequent question on a front desk. The brief's own contract — "the clinic's state at a glance" — is unmet.
  **Fix:** a slim "clinic pulse" strip above the grid fed by existing blocs (queue waiting count, today's bookings, low-stock count), or live counters baked into the tiles; keep the grid below it as the menu.
  **Suggested command:** `/impeccable layout`

- **[P1] "Records" duplicates "Patients".** Both tiles push `Routes.vetPatients`. Records only exists per-pet (`/vet/records?petId=` and `/medical-records?petId=` fall back to "pet required" placeholders when opened bare), so the tile currently promises a distinct destination it doesn't have.
  **Why it matters:** two labels, one behavior — the operator learns the grid is unreliable, and a demo walkthrough hits the same screen twice for two different promises.
  **Fix:** either a patient-picker → straight-into-records flow behind the tile, or drop the tile and let records live under the patient card; do not keep the duplicate.
  **Suggested command:** `/impeccable clarify`

- **[P2] No refresh affordance on the operator home.** The owner home wraps its scroll view in `RefreshIndicator`; the clinic dashboard has none — and with no live data, there is nothing to refresh anyway (same root as #1).
  **Why it matters:** without a gesture, the only way to "check again" is to leave and re-enter the tab.
  **Fix:** lands together with the pulse strip — wrap `CustomScrollView` in `RefreshIndicator` and reload the data on pull.
  **Suggested command:** `/impeccable polish`

- **[P2] Flat hierarchy across six equal tiles.** Nothing signals urgency or frequency: a low-stock day looks identical to a quiet one; the highest-traffic job (Line) has the same weight as Scan.
  **Why it matters:** the operator's eye has no entry point; in a fast-front-desk scene, equal weight equals slow scanning.
  **Fix:** a subtle accent badge/dot on tiles with live exceptions (low stock), and/or a 2×1 hero cell for Line once it carries a count.
  **Suggested command:** `/impeccable layout`

- **[P3] Role tag speaks system, not clinic.** "Clinic overview • Owner/Admin" names the permission model; the operator on the floor doesn't think in roles.
  **Why it matters:** small — but it's the first line of the product's primary surface.
  **Fix:** replace with day context or station context ("Front desk • Tuesday") or drop the suffix.
  **Suggested command:** `/impeccable clarify`

## Persona Red Flags

**Alex (Power User):** reaching any medical record is minimum four interactions (Patients → search → pet → records); no dashboard refresh gesture; no batch check-in from home; the Line tab is the only stateful surface and it's not summarized anywhere. Alex will pin the Line tab and stop using the dashboard.

**Casey (Distracted Mobile):** tiles sit in the thumb zone and targets are ≥48dp — good; but after every interruption ("did my queue move?") Casey must re-navigate to Line to find out. The dashboard gives no answer at a glance, and pull-to-refresh doesn't exist as a reflex escape.

**Sam (Accessibility):** labeled tiles (not icon-only), tooltipped icon buttons, skeleton loaders announced by structure, and no color-only status in the nav — no blocking findings on the landing. Residual: animated skeleton shimmer is now motion-safe (`disableAnimations`), keep it that way.

## Minor Observations

- Grid aspect ratio 0.95 leaves each tile slightly airy; fine on a 3-column phone, would re-check on narrow devices in Phase 4.
- Notification FAB correctly appears for the operator only — contextually right.
- Both homes share the same app-bar pattern — consistent.
- No "today" anywhere: the dashboard has no date context, so "today's bookings" has no anchor even conceptually.

## Questions to Consider

- What if the six tiles carried live numbers — would the operator rarely need to leave this screen?
- Does "Records" deserve its own tile if records only exist under a patient?
- What would make the operator trust the line from their chair without walking to the front desk?
