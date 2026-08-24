# CarePaw — Architecture Documentation

This document describes the system architecture of CarePaw, the design decisions
behind it, and the module boundaries that keep the codebase maintainable and
thesis-ready.

---

## 1. High-Level Overview

CarePaw is a **Flutter** application structured around **Clean Architecture**
principles and a **feature-first** organization. The system is composed of
independent domains — authentication, pets, appointments, queue, medical
records, inventory, scanning/OCR, and notifications — that all share a common
core infrastructure (database, error handling, storage, dependency injection,
routing, and theming).

```
                 CAREPAW
                    │
       ┌────────────┼────────────┐
       │            │            │
  Pet Owner   Veterinary   Administration
                   │
       ┌────────────┼──────────────┐
       │            │              │
  Appointments    Queue     Medical Records
       │
       └─────────┬───────────────
                 │
            Inventory
                 │
            OCR / Scanning
                 │
           Notifications
```

All modules eventually work together rather than existing as disconnected
features. The database is the authoritative source of truth for state
(especially queue and inventory), and OCR results never mutate data without
explicit human confirmation.

---

## 2. Architectural Layers

CarePaw follows the dependency rule: **dependencies point inward**. Outer
layers may depend on inner layers, never the reverse.

### Presentation Layer (planned)
- Flutter widgets, BLoC state management, GoRouter navigation.
- Must contain **no business logic, no database queries, no API calls**.
- Reusable common widgets live in `core/widgets/common`.

### Application Layer (emerging)
- Use cases / application services (to be added per feature).
- BLoC/Cubit state containers bridging domain and presentation.
- DTOs and input validation orchestration.

### Domain Layer (`features/*/domain`)
- **Entities** — pure Dart objects (e.g. `User`, `Pet`, `Appointment`,
  `MedicalRecord`, `InventoryItem`, `QueueEntry`, `Notification`,
  `ScanRecord`).
- **Repository interfaces** — contracts such as `UserRepository`,
  `PetRepository`, `AppointmentRepository`, `QueueRepository`,
  `MedicalRecordRepository`, `VaccinationRepository`, `Inventory*Repository`,
  `ScanRepository`, `NotificationRepository`.
- **Business rules** — state enums, role checks, validation semantics.

### Data Layer (`features/*/data`, `core/database`)
- **Repository implementations** — `*RepositoryImpl` classes backed by Drift
  DAOs.
- **Data sources** — `core/database/dao/*` Drift DAOs.
- **Models / tables** — `core/database/tables.dart` Drift table definitions.

### Core Infrastructure (`core/`)
Shared, cross-cutting services used by every feature:
- `core/database` — Drift database, table schema, DAOs.
- `core/errors` — Typed `Failure` hierarchy and `Exception` mapping.
- `core/di` — GetIt dependency injection configuration.
- `core/storage` & `core/security` — local and secure storage.
- `core/utils` — validators.
- `core/widgets` — reusable UI primitives.
- `core/constants` — app-wide constants.

---

## 3. Design Decisions (ADRs)

### ADR-001: Use Clean / Layered + Feature-First Architecture

**Status:** Accepted

**Context:** CarePaw must be explainable to a thesis panel and maintainable by a
small team. A monolithic Flutter app with logic in widgets would not satisfy
these goals.

**Decision:** Organize code by feature (`features/<name>/`), and within each
feature separate `domain`, `data`, (and future `application`/`presentation`).
Shared infrastructure lives in `core/`.

**Consequences:**
- Clear separation of concerns and testable business logic.
- Dependency rule enforced by construction.
- More initial structure, but predictable as the project grows.

---

### ADR-002: Use Drift (SQLite) for Local Persistence

**Status:** Accepted

**Context:** The app needs a reliable, offline-capable, strongly-typed local
database with relationship integrity and migrations.

**Decision:** Use Drift (a reactive SQLite library for Dart) with
`@DriftDatabase` schema, generated DAOs, and foreign-key enforcement via
`PRAGMA foreign_keys = ON`.

**Consequences:**
- Type-safe SQL, compile-time schema checking, streaming watch APIs.
- Local-first; cloud sync can be layered on later without changing the domain.

---

### ADR-003: Repository Pattern with Domain Interfaces

**Status:** Accepted

**Context:** Domain logic must not depend on Drift types; persistence can change
without affecting business rules.

**Decision:** Each feature defines a repository **interface** in `domain/` and
an implementation in `data/`. The interface depends only on domain entities and
`core/repositories/base_repository.dart`.

**Consequences:**
- Swappable data sources, easy mocking in tests.
- Domain layer remains pure Dart.

---

### ADR-004: Backend as Authoritative for Queue & Inventory

**Status:** Accepted

**Context:** Real-time queue position and stock levels must be consistent and
not derived purely from UI calculations.

**Decision:** Queue entries and inventory stock are persisted in the database;
transitions are applied as transactions. OCR extractions are stored as
*scan records* pending human confirmation and never directly mutate stock.

**Consequences:**
- Consistent state, auditable changes.
- OCR cannot corrupt inventory data.

---

### ADR-005: Typed Failure Hierarchy for Error Handling

**Status:** Accepted

**Context:** Errors must be predictable, user-friendly, secure, and actionable,
without leaking stack traces or DB internals.

**Decision:** A `Failure` base class with hierarchical subtypes
(`NetworkFailure`, `AuthFailure`, `ValidationFailure`, `DataFailure`,
`StorageFailure`, plus domain-specific failures such as
`AppointmentConflictFailure`, `InsufficientStockFailure`,
`LowConfidenceOcrFailure`) is used to communicate errors across layers.

**Consequences:**
- Presentation layer switches on failure type to show the right message.
- No internal details exposed to users.

---

## 4. Module Boundaries

| Module            | Domain Responsibility                              | Key Files |
|-------------------|---------------------------------------------------|-----------|
| Authentication    | User identity, roles, auth result types           | `features/authentication/domain/entities/user.dart` |
| Users             | User profiles, RBAC entity                        | `features/users/domain`, `data` |
| Pets              | Pet ownership & profiles                          | `features/pets/domain`, `data` |
| Appointments      | Scheduling & valid status transitions             | `features/appointments/domain`, `data` |
| Queue             | Real-time check-in & queue position               | `features/queue/domain`, `data` |
| Medical Records   | Append-only health history, vaccinations, Rx      | `features/medical_records/domain`, `data` |
| Inventory         | Items, batches, transactions (traceable)          | `features/inventory/domain`, `data` |
| Scanning          | OCR scan records with human verification          | `features/scanning/domain`, `data` |
| Notifications     | Alerts, read/unread, preferences                  | `features/notifications/domain`, `data` |

---

## 5. State Management & Routing

- **State Management:** `flutter_bloc` (BLoC/Cubit). Blocs will sit between the
  presentation and domain layers.
- **Routing:** `go_router` with a declarative route tree in
  `app/router/app_router.dart`. Routes are defined in `app/router/routes.dart`.
  Role-based redirect logic is scaffolded (commented TODO) for future auth
  integration.
- **Dependency Injection:** `get_it` configured in `core/di/dependency_injection.dart`,
  registering the database, DAOs, and repositories as singletons.

---

## 6. Data Flow

**Write (e.g., stock change):**
```
UI (BLoC) → Repository interface → RepositoryImpl → DAO → Drift → SQLite
                                     ↓
                          InventoryTransaction row inserted (traceable)
```

**Read (e.g., queue status):**
```
UI (BLoC) → Repository interface → RepositoryImpl → DAO → Drift → SQLite
                                     ↓
                          Stream<List<QueueEntry>> → UI updates
```

**Scan (OCR):**
```
UI → ScanRepository → ScanRecord (PENDING)
        ↓
Human reviews & corrects → ScanRecord (CONFIRMED) → Inventory update via transaction
```

---

## 7. Security Architecture

- **Authorization** enforced in domain/repository logic, never trusted from UI.
- **Secure storage** via `flutter_secure_storage` for sensitive tokens/values.
- **Input validation** centralized in `core/utils/validators.dart` and reinforced
  by database constraints.
- **File uploads / OCR** treated as untrusted until confirmed.
- **Audit logging** via the `AuditLogs` table for sensitive operations.
- **Secrets** never hardcoded; committed via secure storage / environment only.

See `CLAUDE.md` security memory for the full ruleset.

---

## 8. Future Work

- Implement presentation layer (widgets, screens) per feature.
- Wire BLoCs to repositories.
- Activate GoRouter auth redirect logic.
- Add remote API data source behind repositories (optional).
- Build out test suites (unit, widget, integration).
