# CarePaw Design System

## Direction

**CarePaw** — a unified visual world built on two layers:

| Layer | Owns | Expression |
|-------|------|------------|
| **Organic neumorphism** | Surfaces, depth, controls | Dual light/depth extrusion on every plane, wells carved into the canvas, accent-tinted lighting |
| **Clinic clarity** | Layout, type, color | Warm bone canvas, generous whitespace, one terracotta accent, data-first density |

This is the revival of the earlier neumorphic direction, re-executed at full
strength. The previous attempt's failure — dense clinical screens losing their
edges and contrast turning to mush — is treated as a calibration problem, not a
direction problem. Every shadow value is now a token rather than a per-call-site
guess, the pair is tinted to the canvas hue instead of left as neutral grey,
and blur runs at roughly twice the distance so the highlight falls off like light
rather than like a bevel.

### How depth works now

A surface separates from the canvas with a **dual extrusion**. Each raised plane
is lit from the top-left and casts depth to the bottom-right — both halves are
always present, because a lone shadow reads as a sticker floating above the
page, not as a surface with volume.

| Plane | Top-left (light source) | Bottom-right (depth) | Notes |
|-------|-------------------------|----------------------|-------|
| `raised` — card, chip, disc | white 0.85, offset(-6,-6) blur 14 | `#B8AE9E` 0.55, offset(6,6) blur 14 | the workhorse |
| `pressed` — held card, selected chip, sunken pill | swapped: depth 0.35, offset(-3,-3) | swapped: white 0.55, offset(3,3) | the same surface, sunk into the canvas |
| `inset` — input well, progress track | swapped 0.40, offset(-4,-4) blur 10 | swapped white 0.70, offset(4,4) blur 10 | always filled, never outlined |
| `flat` — quiet grouping, table header | none | none | flush with its parent |
| `floating` — nav bar, FAB, dialog, sheet | none | single offset(0,10) blur 28, `#7A6E5E` 0.32 | casts straight down — corner light would be a lie |

Three calibration rules keep the extrusion legible:

1. **The depth shadow is tinted.** It is the canvas hue darkened, never a
   neutral grey — a grey shadow on `#F8F5F0` reads as dirt.
2. **Blur runs at ~2.3 the distance.** A tight shadow reads as a hard bevel; a
   soft one reads as a lit surface. `distance 6 / blur 14` is the floor.
3. **Dark mode drops the light source.** A white highlight on charcoal
   describes a light that is not there, so the top-left half becomes a faint
   `#3A3735` rim and the depth shadow carries the volume.

Edges come from the shadow pair, not from borders. A hairline and a highlight
fight over the same edge. `border` survives for the few rows where the edge
carries data — queue position, batch expiry — rather than decoration.

## Color Strategy

Warm bone canvas, terracotta primary, warm charcoal dark mode. Light mode:

| Role | Token | Value | Notes |
|------|-------|-------|-------|
| Canvas | `background` | `#F8F5F0` warm bone | |
| Card plane | `surface` | `#FFFFFF` | |
| Quiet grouping | `surfaceMuted` | `#FAF7F2` | `flat` and `pressed` fills |
| Recessed well | `surfaceInset` | `#F1ECE3` | input wells, tracks |
| Primary | `primary` | `#E27D60` terracotta | filled buttons, body on dark ground → `#F0927A` |
| Light source | `shadowLight` | `#FFFFFF` | top-left half, 0.85 in light mode |
| Depth shadow | `shadowDepth` | `#B8AE9E` | bone darkened — never neutral grey |
| Floating shadow | `shadowFloating` | `#7A6E5E` | bone's darker family, straight down |
| Error | `error` | `#DC2626` | |
| Success | `success` | `#16A34A` | |
| Warning | `warning` | `#D97706` | |

Dark mode is a warm charcoal, not an inverted light theme: canvas `#1A1A1A`,
surface `#262423`, well `#1F1E1D`, rim `#3A3735` instead of a white highlight,
lightened accent `#F0927A`. All colors resolve via `ThemeColors`.

Species accents (cat, dog, bird, rabbit, reptile) are muted species hues,
confined to avatar discs and record-type chips — and under neumorphism they
tint the light/depth pair on the disc rather than an outline ring, so a cat
disc is lit in cat tones and a dog disc in dog tones.

## Typography

- **Display / Headlines**: Nunito (rounded, warm, friendly) — carries the brand
- **Body / Labels / Controls**: system face (Roboto / San Francisco) — native
  legibility, zero cost
- **Scale**: display 24–34, headline 18–24, title 14–18, body 12–16, label 11–14
- **Tracking**: display −0.5 to −0.2, body 0.15–0.2, overline +1.2
- **Line height**: 1.15–1.6 by role

**Colour is never baked into a style.** Every `AppTextStyles` getter returns a
`TextStyle` with `color: null`, so it inherits the ambient colour set by
`AppTheme.colorScheme.onSurface`. A heading is therefore black on the light
canvas and white on the dark one without a single per-call-site `copyWith(color:)`.

Colour-keyed helpers (`primaryOf`, `warningOf`, etc.) resolve through
`ThemeColors` by context, and brightness-keyed helpers (`*Of(brightness)`) make
call sites without a context explicitly show which mode they are assuming.

## Shape System

One radius per role, from `NeuTokens` / `NeuShape`:

| Role | Token | Value | Former value |
|------|-------|-------|--------------|
| Badges, tooltips | `radiusXs` | 12 | 8 |
| Chips, icon buttons, small inputs | `radiusSm` | 16 | 10 |
| Cards, containers, fields | `radiusMd` | **24** | 14 |
| Dialogs, sheets, hero surfaces | `radiusLg` | **28** | 20 |
| App bars, large feature panels | `radiusXl` | **36** | 28 |
| Buttons, chips, nav, FABs | `radiusPill` | 999 | — |

Generous, organic contours. Extruded surfaces need room: a tight radius makes
the top-left highlight terminate awkwardly, so the whole scale sits one step
above where a flat card system would put it. Every surface in a stack shares the
same radius, so a screen reads as one grid.

Decorative motifs survive as brand moments:

| Motif | Helper | Use |
|------|--------|-----|
| Paw print | `NeuShape.pawPrint(Size)` | auth mark (`AuthBrandMark`) |
| Leaf | `NeuShape.leaf(Size)` | quiet surface accent |

## Component Library

All components in `lib/core/widgets/neomorphism/`:

| Component | Role | Key props |
|-----------|------|-----------|
| `NeuCard` | Extruded card, press shadow-swap | onTap, padding, color, shape, showBorder |
| `NeuContainer` | Base extruded plane | variant, color, shape, boxShadow |
| `NeuButton` | Action button, accent-tinted extrusion on filled variants | text, variant (primary/secondary/outline/destructive/ghost/text), size, icon |
| `NeuTextField` | Carved input well, ring only on focus/error | label, hint, error, helper, validator, prefixIcon |
| `NeuAvatar` | Extruded circular disc, species-tinted pair | radius, initials, image, icon, backgroundColor |
| `NeuIconButton` | Circular icon button, extruded | icon, tooltip, size, color |
| `NeuChip` | Filter/choice pill — `raised` / `pressed` sunken selected | label, icon, selected, selectedColor |
| `NeuSwitch` | Toggle | value, onChanged, enabled, label |
| `NeuProgress` | Linear progress, recessed track | value, height, color, trackColor |
| `NeuCircularProgress` | Circular progress | value, size, strokeWidth |
| `NeuSkeletonList` / `NeuSkeletonDetail` | List / detail loading skeletons | itemCount / blocks, padding |
| `NeuBottomNav` | Floating bottom navigation, `floating` shadow | items, currentIndex, onTap |
| `NeuDialog` / `NeuConfirmDialog` / `NeuBottomSheet` | Floating overlays, `floating` shadow | actions, maxWidth, maxHeight |
| `NeuFAB` | Floating action button | icon, variant, extended |
| `AuthScaffold` | Shared auth shell — mark, tiled heading, legal line | child, tagline, onBack, footer |
| `AuthBrandMark` | Inset paw badge — cavity, not a button | radius, icon |
| `NeuPage` / `NeuFloatingBar` | Page scaffold, floating filter bar | title, actions, header, slivers |
| `NeuSection` / `NeuDetailGroup` | Section header + content | title, actionLabel, trailing, children |
| `NeuEmptyState` / `NeuErrorState` | Empty / error state — inset medallion, title, action | icon, title, message, actionLabel |
| `NeuStatTile` / `NeuStatGrid` | Dashboard metric tile & grid | label, value, icon, accent, delta |
| `NeuStatusBadge` / `NeuTag` | Status pill (sunken) / record-type tag | label, tone / fromValue(value) |
| `NeuListRow` / `NeuListGroup` | Tappable row, grouped row stack | title, subtitle, icon, onTap |
| `NeuFilterBar` / `NeuChipRow` | Search + scrolling chip row | controller, chips, onClear |
| `NeuToast` | Transient feedback — success / error / info | actionLabel for success/error |

### Variant semantics

`NeuVariant` selects a **plane and a lighting state**:

- `raised` — a card standing proud of the canvas, lit from the top-left. The workhorse.
- `pressed` — the same card held down: the light and depth swap, so it sinks into the canvas. No scale change.
- `inset` — a recessed well for input fields and progress tracks. Always filled, never outlined — an edge around a recessed field reads as an error.
- `flat` — flush with its parent. Quiet grouping, no extrusion, no edge.
- `transparent` — no plane at all; padding and layout only.

`NeuCard` does not scale on press. At card size a lighting change is the
quieter, more legible signal; scale (0.97) is reserved for buttons and chips.
`NeuCard` also defaults `showBorder: false` — a hairline and a shadow pair
fight over the same edge, so ordinary cards show the pair.

Floating chrome (nav bar, FAB, dialog, sheet) uses `NeuShadow.floating`: a single
offset(0, 10) shadow straight down, not a corner light source, because these
sit above other surfaces rather than beside them.

## Spacing & Layout

Tokens from `NeuTokens` — one value per role, 38 pages:

| Role | Token | Value |
|------|-------|-------|
| Hairline nudge | `spaceXxs` | 4 |
| Chip icon–label | `spaceXs` | 8 |
| Compact internal | `spaceSm` | 12 |
| Default padding | `spaceMd` | 16 |
| Comfortable gap | `spaceLg` | 20 |
| Between blocks | `spaceXl` | 24 |
| Page breathing | `spaceXxl` | 32 |
| Hero vertical rhythm | `spaceHero` | 48 |
| Page horizontal padding | `pagePadding` | **24** |
| Between major blocks | `sectionGap` | **28** |
| Inside a card | `cardPadding` | **20** |
| Tight row | `tightGap` | 12 |
| Content max width | `maxContentWidth` | 640 |

- **Page padding**: always `pagePadding`, everywhere.
- **Card padding**: `cardPadding` or `pagePadding` by role — never `all(28)` and `all(14)` on neighbouring screens.
- **Section gaps**: `sectionGap`, so two pages never disagree about where a heading sits relative to the content above it.
- **Touch targets**: 44×44pt minimum (iOS) / 48×48dp minimum (Android).
- **More space above a heading than below it** — a heading labels what follows it.

## Motion

- **Easing**: exponential ease-out (`curveDefault`)
- **Duration**: micro 80ms, fast 90ms (icon/button press), card 100ms, medium 200ms, slow 300ms, shimmer 1500ms
- **Press feedback**: shadow swap (`raised` ↔ `pressed`) + a restrained scale — **0.97** for buttons and chips, **1** (no scale) for cards.
- **One authored moment per screen**, not scattered effects
- **Skeleton shimmer**: 1500ms, light→inset surface (light mode) or `skeletonDark`→`surfaceInsetDark` (dark)

## Light / Dark

- **Light-first**: the bright clinic floor is the primary scene
- **Dark mode**: deep warm charcoal, never a quick invert — the white light source is removed entirely, replaced by a faint `#3A3735` rim; the depth shadow carries the volume at higher alpha.
- **Both modes designed and tested** — all colors resolve via `ThemeColors`
- **Typography inherits** the colour set by `AppTheme.colorScheme.onSurface`, so the same heading is correct in both modes without a per-call-site branch.

## Platform

- **Mobile-first** (iOS/Android): the primary design target
- **Adaptive**: one product, one design language across all surfaces
- **Safe area**: layout inside safe-area insets
- **System navigation**: bottom tab bar for 2–5 sections, navigation stack for
  hierarchy
