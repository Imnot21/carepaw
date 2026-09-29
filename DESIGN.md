# CarePaw — Soft Clinic Design System

## Direction

**Soft Clinic** — a unified visual world fusing three design languages, each owning one layer:

| Language | Owns | Expression |
|----------|------|------------|
| **Neumorphism** | Material & controls | Soft dual-shadow extrusion on every surface; pressed/inset states; tactile, molded feel |
| **Organic** | Shape & motion | Flowing asymmetric radii, blob avatars, pill buttons, squircle contours; motion on long exponential ease-outs |
| **Minimalist** | Layout & type | Generous whitespace, one terracotta accent, essential-only content, quiet hierarchy |

The product's unique mechanism: a veterinary clinic management system where clinical data feels tactile and alive — soft surfaces you can almost press, organic shapes that feel grown not built, and minimalist calm that lets medical information lead.

## Color Strategy

**Restrained** (the Operate default): neutrals plus one accent.

- **Canvas**: warm bone `#F7F4EF` (light) / warm charcoal `#1C1917` (dark)
- **Surface**: white `#FFFFFF` (light) / warm dark `#292524` (dark)
- **Primary**: terracotta `#E27D60` — the one warm accent per screen
- **Text**: warm near-black `#1C1917` (light) / warm off-white `#FAFAF9` (dark)
- **Status**: success `#16A34A`, error `#DC2626`, warning `#D97706`
- **Species accents**: muted tints (cat `#8B7D5B`, dog `#7A6C5D`, bird `#4A8B6E`, rabbit `#9C7BA8`, reptile `#5C8A6E`) — used sparingly for avatars and chips only

Color lives at hairline edges and moments of emphasis; content fields stay achromatic.

## Typography

- **Display / Headlines**: Nunito (rounded, organic, friendly) — carries the brand's warm character
- **Body / Labels / Controls**: system face (Roboto / San Francisco) — native legibility, zero cost
- **Scale**: display 24–34, headline 18–24, title 14–18, body 12–16, label 11–14
- **Tracking**: display −0.5 to −0.2, body 0.15–0.2, overline +1.2
- **Line height**: 1.15–1.6 depending on role

## Shape System

All shapes derive from `NeuShape` (`lib/core/widgets/neomorphism/neu_shapes.dart`):

- **Cards**: `cardFlow` — asymmetric flowing radii (28/22/22/28), like a leaf or water-worn pebble
- **Buttons**: pill — fully rounded, no hard corners
- **Avatars**: `blob` / `blobSm` — asymmetric organic contours, no two corners alike
- **Nav bar**: `navFlow` — slightly asymmetric pill, like a river stone
- **Feature surfaces**: `squircle` — continuous contour between circle and rectangle
- **Chips**: pill — fully rounded

## Component Library

All components in `lib/core/widgets/neomorphism/`:

| Component | Role | Key props |
|-----------|------|-----------|
| `NeuCard` | Raised surface, press feedback | onTap, padding, color, shape |
| `NeuContainer` | Base surface | variant (raised/pressed/inset/flat/transparent), color, shape |
| `NeuButton` | Pill action button | text, variant (primary/secondary/outline/destructive/ghost/text), size, icon |
| `NeuTextField` | Inset input field | label, hint, error, helper, validator, prefixIcon |
| `NeuAvatar` | Blob avatar | radius, initials, image, icon, backgroundColor |
| `NeuIconButton` | Circular icon button | icon, tooltip, size, color |
| `NeuChip` | Pill filter/choice chip | label, icon, selected, selectedColor |
| `NeuSwitch` | Toggle | value, onChanged, enabled |
| `NeuProgress` | Linear progress | value, height, color |
| `NeuCircularProgress` | Circular progress | value, size, strokeWidth |
| `NeuSkeletonList` | List loading placeholder | itemCount, padding |
| `NeuSkeletonDetail` | Detail loading placeholder | blocks, padding |
| `NeuBottomNav` | Bottom navigation | items, currentIndex, onTap |

## Spacing & Layout (Minimalist Layer)

- **Page padding**: 20–24px horizontal
- **Card padding**: 16–24px
- **Section gaps**: 24–32px
- **Tight groups**: 8–12px
- **Touch targets**: 44×44pt minimum (iOS) / 48×48dp minimum (Android)
- **More space above a heading than below it**

## Motion

- **Easing**: exponential ease-out (organic settle)
- **Duration**: 90–200ms for press feedback, 180–300ms for state changes
- **Press feedback**: scale 0.96–0.985 + shadow swap (raised → pressed)
- **One authored moment per screen**, not scattered effects

## Light / Dark

- **Light-first**: the bright clinic floor is the primary scene
- **Dark mode**: deep warm charcoal, never a quick invert
- **Both modes designed and tested** — all colors resolve via `ThemeColors`

## Platform

- **Mobile-first** (iOS/Android): the primary design target
- **Adaptive**: one product, one design language across all surfaces
- **Safe area**: layout inside safe-area insets
- **System navigation**: bottom tab bar for 2–5 sections, navigation stack for hierarchy
