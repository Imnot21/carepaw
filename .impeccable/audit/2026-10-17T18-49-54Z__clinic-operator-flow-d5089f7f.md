---
target: clinic operator flow (dashboard → bookings → line → patients → records → stock → notifications) + pet owner flow
total_score: 15
max_score: 20
p0_count: 0
p1_count: 0
p2_count: 2
p3_count: 1
addendum: "2026-10-17 same-day fixes: dialog IME inset fixed; stray colors 39->17; 1.3x font-scale pass done; tablet+landscape pass done (tile caps 539f5a3). Adaptivity 2->3; total 14->15."
baseline: "13/20 (recorded at Phase 0-3 close-out)"
target_identity: "file:D:\\Desktop\\carepaw\\lib\\features\\home\\presentation\\pages\\clinic_dashboard_page.dart"
target_fingerprint: "sha256:d5089f7f5b01cb08d7478ddfa4d0a5990ea8a70d22bcfdb57d44c0c4d97de317"
timestamp: 2026-10-17T18-49-54Z
slug: clinic-operator-flow-d5089f7f
---

**Method: source-level audit (native platform, adaptive). Detector not applicable (Flutter).**

# Audit — CarePaw clinic operator flow + owner flow

## Audit Health Score

| # | Dimension | Score | Key Finding |
|---|-----------|-------|-------------|
| 1 | Accessibility | 3 | Semantics + tooltips across the whole `Neu*` library; Reduce Motion honored via `NeuMotion`; no text-scale overrides. Residual: large-text-scale behavior not re-verified on all demo screens. |
| 2 | Performance | 3 | Virtualized lists everywhere (`.builder`/`.separated`, ~20 sites); skeleton states flow-wide; startup already optimized (parallel init, bundled font, sync router). Residual: no frame-time evidence in release. |
| 3 | Appearance & Theming | 3 | Complete token file with light/dark twin for every role; clay icon set as the single family. Residual: 39 raw `Color(0x…)` outside tokens (30 in theme layer itself, 6 camera chrome, 3 widget strays). |
| 4 | Platform Conformance | 3 | Standard push/pop navigation, no gesture hijacks, insets now respected on the demo path (nav clearance, FAB/CTA collisions fixed). Custom neumorphic chrome is the documented brand system, consistently applied. |
| 5 | Adaptivity | 2 | Real-device-size breakage fixed this pass (nav labels, stat grid, pulse strip, dialog overflow). Residual: dialog actions can sit behind the IME; tablet/landscape untested. |
| **Total** | | **14/20** | **Good (14–17) — address Adaptivity** |

## Platform Conformance Verdict

**Pass.** This reads as a native app, not a ported website: standard navigation stack and back behavior, safe-area and nav-bar clearance respected on every verified screen, one icon family (clay SVG set), 48dp+ targets via `Neu*` defaults. The custom bottom nav, buttons, and toggles are a deliberate, documented brand layer — applied consistently, so they read as product identity rather than platform drift.

## Executive Summary

- Audit Health Score: **14/20 (Good)** — up from the recorded 13/20 baseline.
- Issues found: P0 0 / P1 0 / P2 3 / P3 2.
- This pass eliminated the visible runtime breakage class: every overflow, clipped label, and empty-state collision found in the emulator sweep (operator + owner, 1080×2424) was fixed and re-verified.
- Top remaining issues are edges, not blockers: keyboard/IME covering dialog actions; stray hard-coded colors; oversized page files (10 >800 lines) with 20 TODO/FIXME markers.
- Recommended next steps: run `/impeccable adapt` for the IME edge and scaling verification, `/impeccable polish` for token/maintainability cleanup — both safely **after** the demo defense.

## Detailed Findings by Severity

### [P2] Dialog actions can sit behind the keyboard
- **Location**: `lib/features/notifications/presentation/pages/notification_list_page.dart` (create-notification dialog); `NeuDialog` shell generally.
- **Category**: Adaptivity (keyboard/IME).
- **Impact**: With the IME open, "Create"/"Cancel" are covered; the user must dismiss the keyboard first (observed live on the demo path).
- **Guideline**: Material — dialogs must remain operable with the IME shown (inset-aware padding / scrollable body).
- **Recommendation**: wrap dialog content in inset-aware padding (as `patient_picker_sheet.dart` and `inventory_detail_page.dart` already do with `viewInsets.bottom`) or make the dialog body scrollable.
- **Suggested command**: `/impeccable adapt`

### [P2] 39 hard-coded colors outside the token file
- **Location**: `app_text_styles.dart` (16), `app_theme.dart` (14), `scan_list_page.dart` (3), `scan_camera_page.dart` (2), `scan_detail_page.dart` (1), `neu_button.dart` (1), `neu_icon_system.dart` (1), `neu_avatar.dart` (1).
- **Category**: Theming.
- **Impact**: Feature-code strays can drift from the palette; theme-layer values escape the single source of truth.
- **Guideline**: Token discipline established in `DESIGN.md`.
- **Recommendation**: replace strays with `AppColors` roles; keep camera chrome hexes only where an overlay demands it (comment why if kept).
- **Suggested command**: `/impeccable polish`

### [P2] Ten pages exceed 800 lines; 20 TODO/FIXME/HACK markers
- **Location**: `inventory_detail_page.dart` (1151), `pet_detail_page.dart` (1079), `queue_page.dart` (1074), `appointment_form_page.dart` (1056), `staff_queue_page.dart` (1044), … (22 files >600).
- **Category**: Maintainability (Engineering).
- **Impact**: No direct user impact; raises regression risk on the busiest screens.
- **Recommendation**: extract section widgets opportunistically when those files are next touched; sweep the TODO list before any post-demo release.
- **Suggested command**: `/impeccable polish`

### [P3] Large-text-scale behavior not re-verified
- **Location**: full demo path.
- **Category**: Accessibility / Adaptivity.
- **Impact**: The fixed 3px nav-label clipping and grid overflows were verified at default scale only; a 1.3–2.0 system scale could reintroduce clipping.
- **Recommendation**: one emulator pass at 1.3 scale (`adb shell settings put system font_scale 1.3`) over the demo path.
- **Suggested command**: `/impeccable adapt`

### [P3] Tablet / landscape layouts untested
- **Location**: app-wide.
- **Category**: Adaptivity.
- **Impact**: A tablet or landscape run will show a stretched phone layout; acceptable for a phone-first demo, but unverified.
- **Recommendation**: post-demo, review size-class breakpoints for the dashboard/list surfaces first.
- **Suggested command**: `/impeccable adapt`

## Patterns & Systemic Issues

- Overflow-class defects clustered in **shared layout widgets** (nav height, stat grid, FAB vs empty state) — fixed at the component level so all consumers inherit the fix.
- Bloc-provider scope was a recurring failure mode for **imperatively pushed routes** (dialogs and ad-hoc `MaterialPageRoute`); the fix pattern (`BlocProvider.value` at push site) now repeats consistently.
- Route-level `BlocProvider` composition was the single root cause behind two blank-screen incidents; plain `Scaffold`-based page shells replaced exotic sliver compositions on the affected pages.

## Positive Findings

1. **Token architecture is real**: every surface role has a light/dark twin in `app_colors.dart`; both appearances are first-class by construction.
2. **Accessibility is structural**: `Semantics` wraps the entire `Neu*` primitive set (nav announces selection, icon buttons carry tooltips, decorative layers excluded), and `NeuMotion` collapses animation when Reduce Motion is on.
3. **Skeleton-first UI**: `neu_skeleton`/`neu_state` give every list a calm loading and empty state — no spinner flashes.
4. **Verification culture**: emulator sweep evidence (pixel-scan + screenshots) backs every claimed fix; first widget + bloc tests (9/9) sit on the clinic pulse.

## Recommended Actions

1. **[P2] `/impeccable adapt`** — IME-inset handling for dialog actions; font-scale 1.3 verification pass.
2. **[P2] `/impeccable polish`** — tokenize stray colors; extract widgets from the largest pages as touched.
3. **[P3] `/impeccable adapt`** — tablet/landscape review (post-demo).
4. Finish with `/impeccable polish` when the above land.

## Addendum — post-audit fixes (same day, verified)

1. **Dialog IME edge — fixed.** `NeuDialog` now lifts with the keyboard (`AnimatedPadding` on `MediaQuery.viewInsetsOf`) and wraps content in a scroll view. Verified live: the create-notification dialog stays fully operable while the keyboard is open — the flow was completed end-to-end without dismissing the IME.
2. **Stray colors — reduced 39 → 17.** All literals in `app_text_styles.dart` re-pointed at `AppColors` (the three unused `*At` status helpers now use the AA-verified status tokens); `app_theme.dart` swapped 3 exact matches; `neu_button` / `neu_avatar` / `neu_icon_system` now use tokens. Remaining literals are ColorScheme role definitions in the theme layer and scan camera/status chrome (reserve surface, documented exception).
3. **Font-scale pass — completed at 1.3×.** Clinic dashboard, bookings, queue, profile, and notification detail all hold with no overflow stripes. One accepted degradation: bottom-nav labels ellipsize at 1.3× ("Booki…") — semantics still read the full label.
4. **Tablet/landscape pass — completed.** Emulator re-sized to 800×1280dp portrait and 1280×800dp landscape and the operator flow swept: dashboard, bookings, queue, patients, stock, profile. No overflow anywhere (pixel scan, 0 red-band rows); the dashboard already steps its grids to 3 columns at ≥600dp. One real finding fixed in `539f5a3`: aspect-ratio tiles ballooned into near-empty panels on wide viewports — tile heights are now capped at ≥600dp (`NeuStatGrid` uses `mainAxisExtent: 160`; the action grid uses a 1.45 aspect), and the phone layout is byte-identical (0.70/0.95 aspects preserved, re-verified on device). Note: the in-app Device Preview overlay (`device_preview`, `enabled: !kReleaseMode`) presents a sidebar/rail at wide widths — it is debug-build chrome only; release builds ship without it.

Revised scores: Adaptivity 2 → 3 (residual: wide-viewport content stretches edge-to-edge rather than using dedicated multi-column masters — cosmetic, not breakage). **Revised total: 15/20 (Good).** Remaining: the >800-line page / TODO sweep (P2, maintainability only).
