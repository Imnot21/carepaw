---
version: 1
slug: "clinic-dashboard"
primary_target: "clinic-dashboard"
related_targets: ["appointments","queue","pets","medical-records","inventory","scanning","notifications"]
---

# Surface brief — Clinic Dashboard (operator home, primary)

## Scope and visitor mode

Primary target: the clinic dashboard (`lib/features/home/presentation/pages/clinic_dashboard_page.dart`), then the operator flow it opens: bookings (appointments), line (queue), patients, records, stock (inventory), scanning, notifications. Mode: Operate — the clinic owner-admin runs the front desk from a phone: check-ins, calls, patient lookup, stock, and scan intake in short, interrupted bursts.

Audience, job, action: the operator needs the clinic's state at a glance and a one-tap route into each job. Proof/content: real repository data — appointment and queue states, patient counts, stock levels, scan results. Constraints: mobile-first (iOS/Android), 48dp touch targets, light + dark mode, WCAG AA contrast, calm clinical trust.

## Chosen direction

Organic neumorphism × clinic clarity — the calibrated revival locked in `DESIGN.md`. Dual light/depth extrusion on every raised plane, wells carved into the canvas, one terracotta accent on warm bone. This brief replaces the retired "Flat Clinic" draft: flat lost the edges dense clinical rows needed, so depth comes back — but calibrated, token-driven, and never at contrast's expense.

## Direction contract

THESIS: CarePaw makes clinical data calm and unmistakable — through depth, not borders. Every surface is lit from one light source, every plane has a known lightness, every status a hue you can name at a glance. It refuses both the border-grid flatness that blurred dense rows and the uncalibrated extrusion that made them mush: the operator's jobs are one tap away, and a line of six waiting patients stays as legible as a line of one.

OWN-WORLD: Warm bone canvas (`#F8F5F0`), raised white planes, wells in `#F1ECE3`; the dual extrusion pair (white light top-left, bone-tinted depth bottom-right) carries every edge; terracotta `#E27D60` the single accent; floating chrome (nav, FAB, dialogs) casting straight down; Nunito display against the system face for body; the clay SVG set as the only icon family; hairlines kept only where a row's edge carries data (queue position, batch expiry).

STORY: The operator opens the app and sees the clinic's work as six living cards on warm bone — Bookings, Line, Patients, Records, Stock, Scan — taps into any one, and the surfaces that follow keep their legibility at clinic-floor speed.

FIRST VIEWPORT: Greeting app bar — time-of-day greeting with the operator's name, "Clinic overview • Owner/Admin", notifications entry as the single trailing control — over a 3×2 grid of extruded "Clinic work" cards; each clay icon sits in a pressed well with a terracotta label beneath.

FORM: Neumorphic extrusion × warm humanist type × clay icons as one world; build order: clinic dashboard first, then the operator flow it opens, then the pet owner flow.

FINISH: unreviewed and undocumented is unfinished; the build ends with the finish review, the verdict, DESIGN.md, and every shipping raster carrying its provenance.

## Unresolved decisions

- Which card carries the day's live signal (pending bookings count / waiting line) — and whether it renders as a status pill or an inset counter.
- Whether "Records" routes through Patients (pick a patient first) or to a record list of its own; the card currently duplicates the Patients route.
- Queue density at 10+ waiting patients: spaced extruded rows or tighter hairline rows (the data-edge exception in `DESIGN.md`).
