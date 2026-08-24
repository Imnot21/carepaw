# CarePaw

> Smart Veterinary Patient Management System

CarePaw is an integrated veterinary clinic management system that connects pet
owners, pets, veterinarians, and clinic staff through a single, organized
platform. It modernizes everyday clinic operations — appointment scheduling,
real-time queue monitoring, digital medical records, medicine inventory, and
OCR-assisted scanning — while keeping sensitive medical data secure,
auditable, and historically intact.

The core concept behind CarePaw is simple:

> **Making veterinary care simpler, smarter, and more pet-friendly.**

---

## Features

- **Authentication & Authorization** — Role-based access for pet owners,
  veterinarians, staff, and administrators (RBAC-ready).
- **Pet Management** — Digital pet profiles owned by their pet owners.
- **Appointment Scheduling** — Request, confirm, reject, check-in, and complete
  appointments with strict, valid state transitions.
- **Real-Time Queue** — Backend-authoritative queue state with check-in,
  call-next, and position tracking.
- **Digital Medical Records** — Append-only, authorization-protected pet health
  history, vaccinations, and prescriptions.
- **Smart Medicine Inventory** — Stock, batches, expiration tracking, and
  fully traceable inventory transactions.
- **Scanning & OCR** — Receipt and medicine-box scanning with human-in-the-loop
  verification; OCR output is never blindly trusted.
- **Notifications** — Appointment reminders, queue updates, prescription-ready,
  and low-inventory alerts.
- **Audit Logging** — Security and sensitive-operation tracking across the
  system.

---

## Technology Stack

| Layer            | Technology                                              |
|------------------|---------------------------------------------------------|
| Framework        | Flutter 3.12+                                           |
| Language         | Dart 3.12+                                              |
| State Management | BLoC (`flutter_bloc`)                                   |
| Routing          | GoRouter (`go_router`)                                  |
| Dependency Inject. | GetIt + Injectable (`get_it`, `injectable`)           |
| Local Storage    | `shared_preferences`, `flutter_secure_storage`          |
| Database         | Drift (SQLite) (`drift`, `sqlite3_flutter_libs`)        |
| Utils            | `intl`, `uuid`, `logger`, `equatable`, `path_provider`  |

---

## Requirements

- Flutter SDK **3.12+**
- Dart SDK **3.12+**
- Windows / macOS / Linux / Android / iOS / Web build targets supported

---

## Installation

```bash
# 1. Clone the repository
git clone <repository-url>
cd carepaw

# 2. Install dependencies
flutter pub get

# 3. Generate code (Drift DAOs, Injectable, etc.)
flutter pub run build_runner build --delete-conflicting-outputs

# 4. Run the application
flutter run
```

---

## Configuration

The current implementation uses a local Drift/SQLite database and local secure
storage. No remote server is required to run the app in its current state.

- **Local database** — Stored at
  `<application-documents>/carepaw.sqlite` with foreign keys enforced.
- **Secure storage** — Sensitive values use `flutter_secure_storage`.

> Secrets and environment-specific configuration must never be committed. See
> [CONTRIBUTING.md](docs/CONTRIBUTING.md) and the project `CLAUDE.md` security
> rules.

---

## Running the App

```bash
flutter run
```

Routing is handled declaratively by GoRouter. All feature screens currently
render a placeholder scaffold with route-aware titles; business logic,
repositories, and the database layer are implemented and ready to be wired to
the UI.

---

## Testing

```bash
# Run all tests
flutter test

# Run generated tests with coverage
flutter test --coverage
```

> Test suites are part of the planned work (see Implementation Status below).
> Critical workflows to cover are listed in [DEVELOPMENT.md](docs/DEVELOPMENT.md).

---

## Project Structure

```
lib/
├── app/                      # App configuration, routing, theme
│   ├── router/               # GoRouter routes & router config
│   └── theme/                # Colors, text styles, light/dark themes
├── core/                     # Shared infrastructure
│   ├── constants/            # App-wide constants
│   ├── errors/               # Failures & exceptions (typed error system)
│   ├── database/             # Drift database, tables, DAOs
│   ├── di/                   # Dependency injection (GetIt)
│   ├── security/             # Secure storage helpers
│   ├── storage/              # Local storage helpers
│   ├── utils/                # Validators and utilities
│   └── widgets/              # Reusable common widgets (Button, Loader, TextField)
├── features/                 # Feature modules (feature-first)
│   ├── authentication/       # User entity + roles
│   ├── users/                # User profiles & repository
│   ├── pets/                 # Pet profiles & repository
│   ├── appointments/         # Scheduling & repository
│   ├── queue/                # Real-time queue & repository
│   ├── medical_records/      # Records, vaccinations & repositories
│   ├── inventory/            # Items, batches, transactions & repositories
│   ├── scanning/             # OCR scan records & repository
│   └── notifications/        # Notifications & repository
└── main.dart                 # App entrypoint
```

Each feature follows a clean, layered structure:

```
feature/
├── data/         # Repository implementations
├── domain/       # Entities, repository interfaces, business rules
└── (presentation/ — to be added as UI is built)
```

---

## Documentation

Detailed documentation lives in the [`docs/`](docs/) folder:

- [Architecture](docs/ARCHITECTURE.md) — Layered design, module boundaries, ADRs
- [Database](docs/DATABASE.md) — Schema, relationships, integrity rules
- [API / Contracts](docs/API.md) — Repository & data-access contracts
- [Development Guide](docs/DEVELOPMENT.md) — Setup, env, testing, tasks
- [Contributing](docs/CONTRIBUTING.md) — Code style, PR process
- [User Guide](docs/USER_GUIDE.md) — End-user walkthroughs
- [Thesis Support](docs/THESIS_SUPPORT.md) — Capstone documentation outline

---

## Implementation Status

| Module                 | Status      |
|------------------------|-------------|
| Project Setup          | ✅ Complete |
| Core Architecture      | ✅ Complete |
| Database Schema        | ✅ Complete |
| Domain & Repository Layer | ✅ Complete (data + domain) |
| Routing & Theme        | ✅ Complete (scaffolding) |
| Presentation / UI      | 📋 Planned  |
| Authentication (flows) | 📋 Planned  |
| Testing Suites         | 📋 Planned  |

> Status terminology: **PLANNED** (intended), **IMPLEMENTED** (code exists),
> **TESTED** (tests executed), **VERIFIED** (behavior confirmed).

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
