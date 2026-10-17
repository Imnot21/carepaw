# CarePaw

> Smart Veterinary Patient Management System

CarePaw is an integrated veterinary clinic management system that connects pet
owners, pets, and clinic operators through a single, organized platform. It
modernizes everyday clinic operations — appointment scheduling, real-time queue
monitoring, digital medical records, medicine inventory, and OCR-assisted
scanning — while keeping sensitive medical data secure, auditable, and
historically intact.

The core concept behind CarePaw is simple:

> **Making veterinary care simpler, smarter, and more pet-friendly.**

The app is built and screen-verified end to end on live Firebase data: the
clinic operator flow (login → dashboard → appointments → patients → queue →
inventory → records → notifications → settings) and the pet owner flow
(home → pets → appointments → queue).

---

## Features

- **Authentication & Authorization** — role-based access for pet owners and
  clinic operators (Owner/Admin), with registration and password reset.
- **Clinic Dashboard** — at-a-glance pulse (waiting, today's bookings, low
  stock) plus quick access to every clinic surface.
- **Pet Management** — digital pet profiles owned by their pet owners.
- **Appointment Scheduling** — request, confirm, reject, check-in, and complete
  appointments with strict, valid state transitions.
- **Real-Time Queue** — backend-authoritative queue state with check-in,
  call-next, and position tracking.
- **Digital Medical Records** — append-only, authorization-protected pet health
  history, vaccinations, and prescriptions.
- **Smart Medicine Inventory** — stock, batches, expiration tracking, and fully
  traceable inventory transactions.
- **Scanning & OCR** — receipt and medicine-box scanning with human-in-the-loop
  verification; OCR output is never blindly trusted.
- **Notifications** — appointment reminders, queue updates, prescription-ready,
  and low-inventory alerts, delivered in-app and via local notifications.
- **Audit Logging** — security and sensitive-operation tracking across the
  system.

---

## Demo Accounts

| Role | Email | Password |
|------|-------|----------|
| Clinic operator (Owner/Admin) | `admin@carepaw.com` | `Carepaw123` |
| Clinic operator (Owner/Admin) | `vet@carepaw.com` | `Carepaw123` |

Pet owner accounts can be registered from the app's sign-up screen.

---

## Technology Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (stable), Dart `^3.12.2` |
| State management | BLoC (`flutter_bloc`, `equatable`) |
| Routing | GoRouter (`go_router`) |
| Dependency injection | GetIt (`get_it`) |
| Backend | Firebase — Auth, Cloud Firestore, Messaging, App Check, Cloud Functions |
| Local storage | `shared_preferences`, `flutter_secure_storage` |
| Security | `pointycastle`, `local_auth`, `crypto` |
| Local notifications | `flutter_local_notifications` + `timezone` |
| Media | Local file storage by design (Firebase Storage avoided — no cloud cost); files via `path_provider` |
| Icons & type | Clay SVG pack (`flutter_svg`, 136 assets) + bundled Nunito (no runtime font fetching) |
| Dev tooling | `device_preview` (debug builds only), `logger`, `permission_handler` |

---

## Requirements

- Flutter SDK (stable channel) with Dart `^3.12.2`
- Primary target: Android (emulator or device); desktop debug runs also work

---

## Getting Started

```bash
flutter pub get
flutter run
```

- Firebase ships preconfigured for the demo project (`lib/firebase_options.dart`
  and `android/app/google-services.json`). To point at your own Firebase
  project, replace those two files with your project's configuration.
- Debug builds include the `device_preview` overlay so layouts can be checked
  against a phone frame; tap the **Device Preview** toggle to switch between
  framed and full-screen. Release builds contain no overlay at all.

---

## Testing

```bash
flutter test          # unit + widget tests
flutter analyze       # static analysis (currently clean)
```

Current suites cover the clinic-pulse BLoC and the neumorphic stat-tile widget;
coverage is expanding from the critical flows.

---

## Project Structure

```
lib/
├── app/                      # App configuration
│   ├── router/               # GoRouter routes & config
│   ├── shell/                # Bottom-nav shell
│   └── theme/                # Palette, text styles, light/dark themes
├── core/                     # Shared infrastructure
│   ├── constants/            # App-wide constants
│   ├── di/                   # Dependency injection (GetIt)
│   ├── errors/               # Failures & exceptions
│   ├── firebase/             # Firebase init + options wiring
│   ├── notifications/        # Local notification service
│   ├── repositories/         # Shared repository helpers
│   ├── security/             # Secure storage & crypto helpers
│   ├── storage/              # Local persistence
│   ├── utils/                # Validators and utilities
│   └── widgets/neomorphism/  # The Neu* soft-3D design system
├── features/                 # Feature modules (feature-first)
│   ├── authentication/  users/  pets/  appointments/  queue/
│   ├── medical_records/  inventory/  scanning/  notifications/
│   ├── audit/  home/
│   └── ...                   # each module: data/ · domain/ · presentation/
└── main.dart                 # App entrypoint
```

---

## Design System

The UI runs on a soft-3D **neumorphic revival** — token-driven dual-extrusion
shadows, a warm bone canvas, terracotta primary, and a single clay icon voice —
with reduce-motion honored throughout. See [DESIGN.md](DESIGN.md) for the full
canon.

---

## Documentation

- [Design canon](DESIGN.md) — the shipped visual system
- [Product overview](PRODUCT.md) — what CarePaw is and who it serves
- [Demo run-sheet](docs/DEMO_RUNSHEET.md) — the operator + owner demo script
- [Features table](docs/APP_FEATURES.md) — who can use what, at a glance
- [App flowchart](docs/APP_FLOWCHART.md) — the screens and their story
- [System workflow](docs/SYSTEM_WORKFLOW.md) — how the system works, in plain words
- [The story in simple words](docs/SYSTEM_FLOW_SIMPLE.md) — non-technical walkthrough
- [ERD](docs/ERD.md) — data model, matched to the thesis paper
- [Panelist Q&A](docs/Q_AND_A.md) — defense preparation
- [Role alignment](docs/ROLE_ALIGNMENT_PLAN.md) — Owner + Owner/Admin roles
- [Related technologies](docs/RELATED_TECHNOLOGIES.md) — the tools and why
- [SVG catalog](docs/SVG_CATALOG.md) — the clay icon pack

---

## Implementation Status

| Area | Status |
|------|--------|
| Core architecture, DI, routing, theme | ✅ Complete |
| Data + domain layers (Firebase) | ✅ Complete |
| Clinic operator flow (dashboard → appointments → patients → queue → inventory → records → notifications → settings) | ✅ Complete — screen-verified on device |
| Pet owner flow (home → pets → appointments → queue) | ✅ Complete — screen-verified on device |
| Authentication (login, register, password reset) | ✅ Complete |
| Notifications (in-app + local) | ✅ Complete |
| Scanning, audit log, staff/vet/admin views | 🔒 Implemented — reserved for post-defense enablement |
| Test suites | 🚧 Unit/widget tests in place, expanding |

---

## Important Rules

1. Never commit secrets — use environment variables / secure storage.
2. Never trust OCR blindly — always require human confirmation.
3. Never delete medical records — use corrections / superseding.
4. Always check authorization — every sensitive operation.
5. Always use transactions — for related DB operations.
6. Always validate input — client and server side.
7. Always log sensitive operations — audit trail required.

---

## License

Proprietary — developed as a thesis/capstone project.

---

*CarePaw — Smart Veterinary Patient Management System*
