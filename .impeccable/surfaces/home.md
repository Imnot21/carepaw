---
version: 1
slug: "home"
primary_target: "home"
related_targets: ["pets","appointments","queue","medical-records","profile"]
---

# Surface brief — Pet Owner Home (primary)

## Scope and visitor mode

Primary target: pet owner home surface (`lib/features/home/presentation/pages/home_page.dart`), then the full pet owner flow: pets, appointments, queue, medical records, profile. Mode: Operate — the visitor completes tasks (book, check-in, review records) in short, distracted sessions on mobile.

Audience, job, action: pet owners managing their pet's care; they need to see pets, next appointment, and queue position at a glance and act in one or two taps. Proof/content: real pet data from the repository, real appointment and queue states. Constraints: mobile-first (iOS/Android), 44/48pt touch targets, light + dark mode, WCAG AA contrast, calm clinical trust.

## Chosen direction

Flat Clinic — the current user-directed replacement for the earlier neumorphic world. Hairline-bordered planes and tinted wells on a warm bone canvas; one terracotta action owns every screen. Seed key d8d9fc36. Memorable moment: crisply edged cards with species-tint avatars on warm bone, where a queue of six patients stays as legible as a queue of one.

The neumorphic direction it replaced claimed it would refuse the flat card-grid default. It did — by refusing contrast. Dense clinical screens (queue positions, batch expiry, record timelines) lost their edges and read as one blurred mass, so the claim cost more than it bought. The flat system keeps the warm bone canvas and the terracotta accent, and spends its character on typography, spacing, and hairline warmth instead of simulated depth.

## Direction contract

THESIS: CarePaw makes clinical data calm and unmistakable. Every surface has a defined edge, every plane a known lightness, and every status a hue you can name at a glance. It refuses both the mush of extruded surfaces and the coldness of a generic SaaS grid.

OWN-WORLD: Warm bone canvas (`#F8F5F0`), white card planes, muted groupings, recessed input wells; 1px warm hairlines (`#E7E0D5`) carrying every edge; terracotta `#E27D60` as the single accent; one shadow, rationed to the nav bar, FAB, dialog, and sheet; a single radius per role so a stack of surfaces aligns; warm humanist sans (Nunito) for display against the system face for body; paw and leaf motifs as quiet brand marks.

STORY: A pet owner opens the app and immediately sees their pets, their place in the queue, and their next appointment — calm, warm, and legible in one glance, in a busy clinic or on the move.

FIRST VIEWPORT: Greeting header with notification entry; horizontal pet summary cards with circular avatars and species tints; one terracotta primary action (Book Appointment); quiet bordered sections for upcoming appointments and quick links below; generous whitespace on the warm bone canvas.

FORM: Flat material × warm humanist type × generous layout as one world; build order: pet owner flow first, then staff and vet surfaces.

FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, DESIGN.md, and every shipping raster carrying its provenance.

## Unresolved decisions

Species accent usage rules beyond avatars and record-type chips; whether the empty-state accent medallion keeps its glow or drops to a flat disc.
