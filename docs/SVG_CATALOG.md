# SVG Catalog — CarePaw icon picks (SVGRepo)

Location in repo: `assets/icons/` — 136 files: the clay pack plus `icon-map.json` (material-name mapping + `not_in_this_pack` list). Wired via `flutter_svg`. The 14-icon list below is the original research shortlist; the shipping set is the full pack.
Widget: `lib/core/widgets/neomorphism/neu_svg_icon.dart:11` (`NeuSvgIcon`, `SvgIcons`).

All files downloaded from `https://www.svgrepo.com/show/<id>/<slug>.svg`.
Search-cache license says CC0 — re-check the License field on each page before release.

## Where to see them
- Files: `assets/icons/*.svg` (open directly in VS Code / browser)
- In app: `NeuSvgIcon(SvgIcons.pawOutline)` — renders the clay SVG as-is. No `ColorFilter`: the clay art is multicolor (gradients, highlights), and `srcIn` would flatten it to a silhouette.
- Fallback: material names with no clay equivalent live in `assets/icons/icon-map.json` → `not_in_this_pack`; `ClayIconOrMaterial` auto-falls back to Material Icons for those.

## Nav / core
| File | Source | Use instead of |
|------|--------|----------------|
| `326738-paw-outline.svg` | https://www.svgrepo.com/svg/326738/paw-outline | `NeuIconType.pets` (Pets tab) — rounded outline, best extrusion match |
| `342758-paw.svg` | https://www.svgrepo.com/svg/342758/paw | Alt paw if outline feels thin |
| `101633-dog-paw.svg` | https://www.svgrepo.com/svg/101633/dog-paw | Home / brand mark |
| `438348-calendar-round.svg` | https://www.svgrepo.com/svg/438348/calendar-round | `NeuIconType.calendar` (Appointments) — round matches radius system |

## Species
| File | Source | Use instead of |
|------|--------|----------------|
| `41272-dog-face-outline-front.svg` | https://www.svgrepo.com/svg/41272/dog-face-outline-front | `NeuIconType.dog` — pick ONE dog, don't mix with alt |
| `70385-dog-face-frontal-outline.svg` | https://www.svgrepo.com/svg/70385/dog-face-frontal-outline | Dog alt for A/B |
| `54130-cat-face-outline.svg` | https://www.svgrepo.com/svg/54130/cat-face-outline | `NeuIconType.cat` — simpler whiskers, better at 20px |
| `43352-cat-face-outline.svg` | https://www.svgrepo.com/svg/43352/cat-face-outline | Cat alt, denser detail |
| `90471-duck-bird-outline.svg` | https://www.svgrepo.com/svg/90471/duck-bird-outline | `NeuIconType.bird` |
| `11303-bunny.svg` | https://www.svgrepo.com/svg/11303/bunny | `NeuIconType.rabbit` — verify filled-vs-outline at small size |

## Medical
| File | Source | Use instead of |
|------|--------|----------------|
| `96154-stethoscope-outline.svg` | https://www.svgrepo.com/svg/96154/stethoscope-outline | `NeuIconType.visit` |
| `42471-syringe.svg` | https://www.svgrepo.com/svg/42471/syringe | `NeuIconType.vaccination` |
| `58711-pill.svg` | https://www.svgrepo.com/svg/58711/pill | `NeuIconType.medication` — single pill scales best |
| `117985-pills.svg` | https://www.svgrepo.com/svg/117985/pills | Medication alt |

## Why these fit (impeccable / taste-skill)
Warm bone canvas + terracotta + rounded Nunito + extrusion shadows → need rounded monoline, single-weight, no sharp/filled/multicolor, legible at 16/20/24px. Thin/outline packs (`/vectors/paw-print-thin/`, `/vectors/veterinary/`, `/vectors/cat-face/`) beat detailed illustrations.

## Usage
```dart
NeuSvgIcon(SvgIcons.pawOutline, size: NeuTokens.iconMd)
NeuSvgIcon(SvgIcons.stethoscope, color: ThemeColors.primary(context))
NeuSvgIcon(SvgIcons.catFace, size: NeuTokens.iconSm, tooltip: 'Cat')
```
