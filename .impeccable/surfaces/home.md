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

Soft Clinic — the user-pinned fusion: neumorphic material and controls, organic shape and motion, minimalist layout and type. Seed key d8d9fc36. Memorable moment: soft-extruded cards with organic blob avatars on a warm bone canvas; one terracotta action owns every screen.

## Direction contract

THESIS: CarePaw owns the moment where clinical data feels tactile and alive — soft-extruded surfaces you can almost press, organic shapes that feel grown not built, and minimalist calm that lets medical information lead. It refuses the flat card-grid clinic-app default.

OWN-WORLD: Warm bone canvas, terracotta primary, achromatic content fields with color confined to hairline edges; neumorphic dual-shadow extrusion on every control and surface; organic flowing asymmetric radii, blob avatars, paw-and-leaf marks; one warm accent per screen; warm charcoal dark mode; warm humanist sans with a rounded display voice.

STORY: A pet owner opens the app and immediately sees their pets, their place in the queue, and their next appointment — tactile, calm, and legible at a glance, in a busy clinic or on the move.

FIRST VIEWPORT: Greeting header with notification entry; horizontal pet summary cards with organic blob avatars and species tints; one terracotta primary action (Book Appointment); quiet sections for upcoming appointments and quick links below; soft-extruded cards on the warm canvas with generous whitespace.

FORM: The pinned user direction (seed d8d9fc36) — neumorphic material × organic shape × minimalist layout fused as one world; build order: pet owner flow first, then staff and vet surfaces.

FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, DESIGN.md, and every shipping raster carrying its provenance.

## Unresolved decisions

Final typeface pairing (warm humanist sans candidates) to be settled at first build; species accent usage rules; dark-mode canvas depth.
