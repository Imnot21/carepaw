---
name: CarePaw
description: Soft-3D clinic calm — a cool clinic canvas where every surface is extruded, the PILA VET HUB indigo carries action, and clay icons give the app its voice.
colors:
  clinic-mist: "#F4F6FB"
  chalk: "#FFFFFF"
  recessed-mist: "#E9EDF5"
  mist: "#F7F9FC"
  deep-slate: "#15171F"
  slate-card: "#1F2230"
  slate-well: "#191B25"
  slate-rim: "#2E3243"
  pila-indigo: "#2E3192"
  indigo-on-dark: "#8C93E8"
  indigo-ink: "#15172B"
  indigo-tint: "#E6E7F6"
  slate-tint: "#262A4A"
  indigo-deep: "#23267A"
  caduceus-cyan: "#0098C8"
  deep-cyan: "#00739A"
  cyan-on-dark: "#4CC9F0"
  light-source: "#FFFFFF"
  mist-depth: "#A9B1C7"
  deep-mist: "#5E6782"
  ink: "#111111"
  ink-secondary: "#2B2B2B"
  ink-soft: "#4A4A4A"
  ink-on-dark: "#FFFFFF"
  ink-secondary-dark: "#E5E7EB"
  hairline: "#DDE2EC"
  hairline-strong: "#C9D0DE"
  divider: "#E6EAF1"
  skeleton: "#E6EAF1"
  skeleton-dark: "#272A38"
  brick: "#B91C1C"
  brick-on-dark: "#F87171"
  forest: "#15803D"
  forest-on-dark: "#4ADE80"
  amber-bark: "#B45309"
  amber-on-dark: "#FBBF24"
  steel-blue: "#4A6FA5"
  steel-blue-on-dark: "#93B4E4"
  deep-cyan-progress: "#00739A"
  cyan-progress-on-dark: "#4CC9F0"
  species-cat: "#8B7D5B"
  species-dog: "#7A6C5D"
  species-bird: "#4A8B6E"
  species-rabbit: "#9C7BA8"
  species-reptile: "#5C8A6E"
  species-other: "#5B8BC0"
typography:
  display:
    fontFamily: "Nunito"
    fontSize: "34px"
    fontWeight: 700
    lineHeight: 1.15
    letterSpacing: "-0.5px"
  headline:
    fontFamily: "Nunito"
    fontSize: "24px"
    fontWeight: 700
    lineHeight: 1.25
    letterSpacing: "-0.2px"
  title:
    fontSize: "18px"
    fontWeight: 600
    lineHeight: 1.35
    letterSpacing: "0"
  body:
    fontSize: "14px"
    fontWeight: 400
    lineHeight: 1.6
    letterSpacing: "0.15px"
  label:
    fontSize: "12px"
    fontWeight: 600
    lineHeight: 1.35
    letterSpacing: "0.1px"
  number:
    fontFamily: "Nunito"
    fontSize: "24px"
    fontWeight: 700
    lineHeight: 1.2
    letterSpacing: "-0.1px"
rounded:
  xs: "12px"
  sm: "16px"
  md: "24px"
  lg: "28px"
  xl: "36px"
  pill: "999px"
spacing:
  xxs: "4px"
  xs: "8px"
  sm: "12px"
  md: "16px"
  lg: "20px"
  xl: "24px"
  xxl: "32px"
  hero: "48px"
  page-padding: "24px"
  section-gap: "28px"
  card-padding: "20px"
  tight-gap: "12px"
components:
  button-primary:
    backgroundColor: "{colors.pila-indigo}"
    textColor: "{colors.chalk}"
    typography: "{typography.label}"
    rounded: "{rounded.pill}"
    height: "50px"
    padding: "0 24px"
  button-secondary:
    backgroundColor: "{colors.chalk}"
    textColor: "{colors.pila-indigo}"
    typography: "{typography.label}"
    rounded: "{rounded.pill}"
    height: "50px"
  button-destructive:
    backgroundColor: "{colors.brick}"
    textColor: "{colors.ink-on-dark}"
    typography: "{typography.label}"
    rounded: "{rounded.pill}"
    height: "50px"
  card:
    backgroundColor: "{colors.chalk}"
    textColor: "{colors.ink}"
    rounded: "{rounded.md}"
    padding: "20px"
  input:
    backgroundColor: "{colors.recessed-mist}"
    textColor: "{colors.ink}"
    rounded: "{rounded.md}"
    padding: "16px"
  chip:
    backgroundColor: "{colors.chalk}"
    textColor: "{colors.ink}"
    typography: "{typography.label}"
    rounded: "{rounded.pill}"
    padding: "8px 12px"
  nav-bar:
    backgroundColor: "{colors.chalk}"
    rounded: "{rounded.pill}"
    height: "72px"
  stat-tile:
    backgroundColor: "{colors.chalk}"
    textColor: "{colors.ink}"
    rounded: "{rounded.md}"
    padding: "16px"
---

# Design System: CarePaw

## Overview

**Creative North Star: "The Clay Counter"**

CarePaw looks like a surface you could press with a fingertip — soft, warm, and continuous. The whole app is one clay plane lit from the top-left: cards stand proud of a cool clinic canvas, input wells sink into it, and nothing floats without casting depth. The visual world is built on two layers that must never fight: **organic neumorphism** owns surfaces, depth, and controls (dual light/depth extrusion on every plane, wells carved into the canvas), while **clinic clarity** owns layout, type, and colour (cool clinic canvas, generous whitespace, exactly one PILA VET HUB indigo accent, data-first density).

This system is a deliberate revival, re-executed at full strength. An earlier neumorphic attempt failed on dense clinical screens — edges dissolved, contrast turned to mush. That is treated as a calibration problem, not a direction problem: every shadow value is now a token rather than a per-call-site guess, the depth pair is tinted to the canvas hue instead of left neutral grey, and blur runs at roughly twice the distance so highlights fall off like light rather than like a bevel. Contrast is non-negotiable on top of the effect: accent *fills* and accent *ink* are separate tokens, and every text role clears AA in both modes.

The audience is a busy single-clinic operator and pet owners in transit. Screens are phone-first, task-oriented, and read at arm's length at a front desk — so numbers are the loudest element on a dashboard, labels the quietest, and feedback is honest (skeletons, empty states, friendly errors, no silent failures). Motion is budgeted: state changes are shadow swaps and restrained scale, one authored moment per screen, and everything collapses to zero travel when the platform asks for reduced motion.

**Key Characteristics:**
- Dual extrusion on every plane — a top-left light and a bottom-right tinted depth shadow, always as a pair
- Cool clinic canvas, PILA VET HUB indigo as the only accent, deep slate dark mode (never a quick invert)
- Nunito for display/headlines/numerals, the system face for body and controls
- Token-driven: spacing, radius, depth, and motion come from `NeuTokens`; colors resolve through `ThemeColors`
- Clay SVG icons as the single icon voice, with Material fallbacks only where the pack has no art
- Edges come from shadows, not borders; hairlines appear only where an edge carries data
- Reduce-motion is a first-class state: `NeuMotion` collapses kit animations to zero duration

## Colors

A cool, low-chroma clinic world built from the DocMyk's PILA VET HUB logo: one indigo accent, the logo's caduceus cyan for progress, and functional status hues.

### Brand logo
- **PILA VET HUB logo** (`assets/images/pilavethub_logo.png`, transparent cut-out of the clinic's logo) is shown through `ClinicLogo` (`lib/core/widgets/clinic_logo.dart`) on the login/register screens, both splash screens, and Help & Support.
- The logo always sits on a **white plate**, in both modes. Its indigo strokes fall to 1.6:1 on the dark canvas, so on dark the plate reads as a deliberate badge.
- The Android launcher icon, adaptive icon, native splash, and web favicon/manifest icons are the full logo on white (`#FFFFFF` launcher and splash background).

### Primary
- **PILA Indigo** (#2E3192): the one accent, sampled from the logo. Fills for primary buttons, FABs, selection, and tint washes; also the readable accent for labels, links, and glyphs (9.9:1 on the canvas, 8.7:1 on its tint). On dark grounds it lightens to **Indigo on Dark** (#8C93E8, 6.4:1 on the dark canvas). Never used for large background areas — one accent per screen; everything else stays quiet.
- **Text on accent**: white on the indigo fill in light mode (10.7:1); **Indigo Ink** (#15172B) on the dark-mode fill (6.3:1). Resolved by `ThemeColors.onPrimary`.
- **Indigo Tint** (#E6E7F6) / **Slate Tint** (#262A4A): quiet accent-washed planes (selected chips, highlight cards) in light / dark mode.

### Secondary
- **Caduceus Cyan** (#0098C8): the logo's second colour, for icons and large shapes only — 3.0:1 on white, too faint for small text. **Deep Cyan** (#00739A, 5.4:1 on white) is the readable version and the `progress` tone; **Cyan on Dark** (#4CC9F0) on dark grounds.

### Neutral
- **Clinic Mist** (#F4F6FB): the canvas. Every screen sits on it.
- **Chalk** (#FFFFFF): the top plane — cards, sheets, dialogs. The brightest surface in light mode.
- **Mist** (#F7F9FC): quiet groupings and table headers; the `flat` and `pressed` fill.
- **Recessed Mist** (#E9EDF5): wells — fields, progress tracks. One step *below* the canvas, always filled, never outlined.
- **Deep Slate** (#15171F): the dark canvas; **Slate Card** (#1F2230), **Slate Well** (#191B25), and **Slate Rim** (#2E3243) complete the family.
- **Ink scale**: #111111 / #2B2B2B / #4A4A4A primary→tertiary in light mode; #FFFFFF / #E5E7EB / #D1D5DB on dark.
- **Hairlines**: Hairline (#DDE2EC), Hairline Strong (#C9D0DE), Divider (#E6EAF1), with dark counterparts in the same cool family. Baked to the canvas hue, never neutral grey.

### Status
- **Brick** (#B91C1C / #F87171 on dark): errors and destructive actions; deep enough to serve as both a text color on light planes and a fill under white text.
- **Forest** (#15803D / #4ADE80 on dark): success and confirmations.
- **Amber Bark** (#B45309 / #FBBF24 on dark): warnings — waiting patients, low stock, expiring batches.
- **Steel Blue** (#4A6FA5 / #93B4E4 on dark): informational status, timestamps, neutral badges.
- **Deep Cyan** (#00739A / #4CC9F0 on dark): progress tones — scans, in-progress visits.

### Species
Muted species hues — cat (#8B7D5B), dog (#7A6C5D), bird (#4A8B6E), rabbit (#9C7BA8), reptile (#5C8A6E), other (#5B8BC0) — confined to avatar discs and record-type chips. Under this system they tint the disc's light/depth pair rather than outline it, so a cat disc is lit in cat tones.

### Named Rules
**The Text Beats Effect Rule.** The effect never gets to hurt the words. Accent read on the canvas uses PILA Indigo (Indigo on Dark in dark mode); accent fills carry white in light mode and Indigo Ink in dark mode; status fills carry white in light mode and ink in dark mode; body text steps down the ink scale, never greys invented per screen.

**The Tinted Depth Rule.** Shadows are the canvas hue darkened — Bone Depth (#B8AE9E) and Deep Bone (#7A6E5E) — never neutral grey. A grey shadow on bone reads as dirt.

**The One Accent Rule.** PILA Indigo appears on ≤10% of any given screen. Its rarity is what makes it point.

## Typography

**Display Font:** Nunito (bundled static 400/600/700/800; rounded, warm, friendly)
**Body Font:** the system face — Roboto / San Francisco (native legibility, zero cost)
**Numeral Font:** Nunito for dashboard numerals (`numberLarge` / `numberMedium`)

**Character:** a warm humanist display voice over a quiet, utilitarian body. Nunito carries the brand on headings, app-bar titles, and dashboard numbers; everything the user *operates* — rows, fields, buttons, captions — stays on the system face so long sessions read natively.

### Hierarchy
- **Display** (w700, 34/28/24, height 1.15–1.25, tracking −0.5…−0.2): onboarding and hero moments only.
- **Headline** (w600–700, 24/20/18, height 1.25–1.35): page and sheet titles, section heroes.
- **Title** (w600, 18/16/14, height 1.35–1.45, system face): card titles, list item titles, app-bar titles via `appBarTitle` (Nunito, 20).
- **Body** (w400, 16/14/12, height 1.5–1.6, tracking +0.15…+0.2): reading text; keep measure ≤ 75ch, on a phone it never exceeds the content width (max 640).
- **Label** (w600, 14/12/11, tracking +0.05…+0.1): buttons, chips, tile labels, stat captions; `overline` (w700, 10, +1.2 tracking) for eyebrow text.
- **Number** (Nunito w700, 34/24, tracking −0.3/−0.1): the loudest element on any dashboard tile.

### Named Rules
**The Inherited Colour Rule.** No `AppTextStyles` getter bakes in a color. Styles resolve colour from the ambient theme (`ColorScheme.onSurface`), and call sites that need a specific colour go through `ThemeColors` / `*Of(context)` helpers — so a heading is black on light and white on dark with zero per-site branching.

## Layout

Phone-first (iOS/Android) with one unified design language across all surfaces — no per-OS visual adaptation. Layout inside safe-area insets; a bottom tab bar serves 2–5 sections with a navigation stack for hierarchy.

- **Page padding** is always 24 (`pagePadding`), everywhere.
- **Gaps**: 28 between major blocks (`sectionGap`), 20 comfortable (`spaceLg`), 16 default (`spaceMd`), 12 tight rows (`tightGap`), 8 chip icon-to-label, 4 hairline nudges. More space above a heading than below it — a heading labels what follows.
- **Card padding** is 20 (`cardPadding`) or 24 by role; neighboring screens never disagree.
- **Content width** caps at 640 (`maxContentWidth`) so tablets and desktop windows keep cards from flinging to opposite edges.
- **Density is data-first**: front-desk screens (queue, inventory, appointments) run tighter rows and denser cards than owner screens, which breathe more.
- **Responsive habit**: stat grids run two-to-three-up on phones and three-up from 600px (`NeuStatGrid`); lists stay single-column.
- **Touch targets** never below 44 (`minTapTarget`).

## Elevation & Depth

Depth is the system. Every raised plane is lit from the top-left and casts depth to the bottom-right — **both halves are always present**, because a lone shadow reads as a sticker floating above the page, not as a surface with volume. Edges come from the shadow pair, not from borders: a hairline and a highlight fight over the same edge, so ordinary cards show the pair, and `border` survives only where the edge carries data (queue position, batch expiry).

| Plane | Top-left (light source) | Bottom-right (depth) | Use |
|-------|-------------------------|----------------------|-----|
| `raised` | white 0.85, offset(−6,−6) blur 14 | #B8AE9E 0.55, offset(6,6) blur 14 | cards, chips, discs — the workhorse |
| `pressed` | swapped: depth 0.35, offset(−3,−3) blur 6 | swapped: white 0.55, offset(3,3) blue 6 | held card, selected chip, sunken pill |
| `inset` | swapped 0.40, offset(−4,−4) blur 10 | swapped white 0.70, offset(4,4) blur 10 | input wells, progress tracks — always filled, never outlined |
| `flat` | none | none | quiet grouping, table header — a deliberate plane, flush with its parent |
| `floating` | none | single offset(0,10) blur 28, #7A6E5E 0.32 | nav bar, FAB, dialog, sheet — casts straight down; corner light would be a lie |

Dark mode drops the light source entirely: a white highlight on slate describes a light that is not there, so the top-left half becomes a faint #2E3243 rim in the surface's own hue and the depth shadow (near-black, higher alpha, slightly tighter distance) carries the volume.

### Shadow Vocabulary
- **Raised** (`−6 −6 14 rgba(255,255,255,0.85)` + `6 6 14 rgba(184,174,158,0.55)`): the default plane for anything interactive or card-like.
- **Pressed** (`−3 −3 6 rgba(184,174,158,0.35)` + `3 3 6 rgba(255,255,255,0.55)`): a surface mid-press — the pair swaps, the plane sinks.
- **Inset** (`−4 −4 10 rgba(184,174,158,0.40)` + `4 4 10 rgba(255,255,255,0.70)`): carved wells.
- **Floating** (`0 10 28 rgba(122,110,94,0.32)`): chrome that sits *above* other surfaces.
- **Accent glow** (`0 3 12 @ 0.24` of the accent, offset anchored): rationed — the accent may glow, the canvas may not.

Press behaviour is a shadow swap, not a transform: buttons and chips add a restrained scale (0.97), **cards never scale** — the lighting change is the quieter, more legible signal at card size. Durations: micro 80ms, press 90–100ms, color fades 200ms, page and skeleton transitions 300ms, shimmer 1500ms, all on the default ease-out (`Curves.easeOut`). When `MediaQuery.disableAnimations` is set, `NeuMotion` collapses every kit animation to zero duration — state still changes, nothing travels.

### Named Rules
**The No-Lone-Shadow Rule.** Never ship one half of the pair on an extruded plane; a single shadow is a sticker, not a surface.

**The Edge-Carries-Data Rule.** Hairlines are allowed only where the edge itself is information — separators in data rows, focused fields, table dividers. Decorative borders on cards and wells are banned.

## Shapes

Generous, organic contours. Extruded surfaces need room — a tight radius makes the top-left highlight terminate awkwardly — so the whole scale sits one step above where a flat card system would put it.

| Role | Value |
|------|-------|
| Badges, tooltips, small tags (`radiusXs`) | 12 |
| Chips, icon buttons, small inputs (`radiusSm`) | 16 |
| Cards, containers, fields (`radiusMd`) | 24 — the workhorse |
| Dialogs, sheets, hero surfaces (`radiusLg`) | 28 |
| App bars, large feature panels (`radiusXl`) | 36 |
| Buttons, chips, nav bar, FABs (`radiusPill`) | 999 |

Every surface in a stack shares the same radius, so a screen reads as one grid. Circular forms (avatars, icon buttons, FABs) are true circles. Brand motifs survive as quiet geometry: a paw print for the auth mark, a leaf as a surface accent.

### Named Rules
**The One Step Wider Rule.** When adding a new surface, take the nearest radius from this table — never invent a value, and never go tighter than `radiusSm` on an extruded plane.

## Components

Shared surfaces live in `lib/core/widgets/neomorphism/` (exported through `index.dart`) and read their depth, radius, and color from the token layer; feature shells like `AuthScaffold` layer on top.

| Component | Role | Key props |
|-----------|------|-----------|
| `NeuCard` | Extruded card, press shadow-swap | onTap, padding, color, shape, showBorder |
| `NeuContainer` | Base extruded plane | variant, color, shape, boxShadow |
| `NeuButton` | Action button; primary/outline/destructive cast an accent-tinted extrusion | text, variant (primary/secondary/outline/destructive/ghost/text), size, icon |
| `NeuTextField` | Carved input well, ring only on focus/error | label, hint, error, helper, validator, prefixIcon |
| `NeuAvatar` | Extruded circular disc, species-tinted pair | radius, initials, image, icon, backgroundColor |
| `NeuIconButton` | Circular icon button, extruded | icon, svgAsset, tooltip, size, plain |
| `NeuChip` | Filter/choice pill — `raised` vs `pressed` selected | label, icon, selected, selectedColor |
| `NeuSwitch` | Toggle | value, onChanged, enabled, label |
| `NeuProgress` / `NeuCircularProgress` | Recessed track / ring progress | value, height, color, trackColor |
| `NeuSkeletonList` / `NeuSkeletonDetail` | Content-shaped absence | itemCount / blocks, padding |
| `NeuBottomNav` | Floating bottom navigation, `floating` shadow, clay nav icons | items, currentIndex, onTap |
| `NeuDialog` / `NeuConfirmDialog` / `NeuBottomSheet` | Floating overlays | actions, maxWidth, maxHeight |
| `NeuFAB` | Floating action button | icon, variant, extended |
| `NeuStatTile` / `NeuStatGrid` | Dashboard metric tile & grid — number loudest, label quietest, icon in a recessed well | label, value, icon, svgAsset, accent, delta, onTap |
| `NeuStatusBadge` / `NeuTag` | Status pill (sunken) / record-type tag | label, tone / fromValue(value) |
| `NeuListRow` / `NeuListGroup` | Tappable row, grouped row stack | title, subtitle, icon, onTap |
| `NeuFilterBar` / `NeuChipRow` | Search + scrolling chip row | controller, chips, onClear |
| `NeuEmptyState` / `NeuErrorState` | Inset medallion, title, action | icon, title, message, actionLabel |
| `NeuToast` | Transient feedback — success / error / info | actionLabel for success/error |
| `AuthScaffold` / `AuthBrandMark` | Auth shell with the paw brand mark | child, tagline / radius, icon |

**Variant semantics.** `NeuVariant` selects a plane *and* a lighting state: `raised` (proud of the canvas, interactive — the workhorse), `pressed` (the same card held down; light and depth swap, the plane sinks, no scale change), `inset` (a recessed well for fields and tracks; always filled, never outlined), `flat` (flush with its parent; a deliberate plane, not a stripped raised), `transparent` (no plane at all).

### Icons
**The One Icon Voice Rule.** The user-made clay SVG pack (`assets/icons/`, rendered by `NeuSvgIcon`) is the only icon family on shipped surfaces. Multicolor clay art is never tinted with a `ColorFilter`. Where the pack has no art for a name, `ClayIconOrMaterial` / optional `svgAsset` params fall back to Material — a sanctioned exception, not a second style.

### Signature: The Clinic Pulse
The operator home opens with `NeuStatGrid` — three `NeuStatTile`s (waiting line, today's bookings, low stock) whose numbers are read across a counter. Tiles are raised, therefore tappable: each opens the surface that owns its number. Accent tints appear only on exception (waiting > 0, low stock > 0); unknown values render as a dash, never a fake zero.

## Do's and Don'ts

### Do:
- **Do** resolve every colour through `ThemeColors` (or `*Of(context)` style helpers) and every gap, radius, and duration through `NeuTokens`; the tokens are the system.
- **Do** use PILA Indigo (#2E3192) for accent text/icons on the canvas, white on indigo fills, and Indigo Ink (#15172B) on the dark-mode fill; verify each new pairing against the Text Beats Effect Rule.
- **Do** pair the light and depth shadows on every extruded plane, with blur ≥ 2× distance.
- **Do** keep interactive surfaces `raised` and input surfaces `inset`; press feedback is the shadow swap (+0.97 scale on buttons/chips only).
- **Do** give every async surface its three honest states: skeleton, empty state with an action, friendly error with retry — never a dead end or a raw exception string.
- **Do** test every screen in both light and dark mode; dark mode drops the light source and leans on the depth shadow.
- **Do** route motion through `NeuMotion` so reduce-motion collapses it; one authored moment per screen.

### Don't:
- **Don't** use neutral-grey shadows, cool greys in the palette, or white highlights in dark mode — the depth pair is always tinted to the surface's world.
- **Don't** bake a color into a text style, or invent a per-screen grey; step down the ink scale instead.
- **Don't** outline wells, add decorative card borders, or let hairlines appear where no data edge exists.
- **Don't** scale cards on press, animate layouts with bouncy springs, or run more than the budgeted motion.
- **Don't** introduce a second accent, a second icon family, or tinted multicolor clay art.
- **Don't** let the accent exceed its 10% budget, or print fake zeros in place of unknown values.
- **Don't** let the effect win a contrast fight: if a pairing fails AA, the words change the design, not the other way round.
