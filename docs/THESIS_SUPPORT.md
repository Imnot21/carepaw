# CarePaw — Thesis/Capstone Documentation Support

This document provides a structured outline and guidance for preparing the
thesis/capstone documentation for CarePaw. It maps the implemented system
to typical academic documentation requirements.

---

## 1. Recommended Thesis Structure

### 1.1 Chapter 1: Introduction
- **1.1 Background** — Problems in veterinary clinic management (manual
  appointments, paper records, unclear wait times, inventory tracking)
- **1.2 Problem Statement** — Formal definition of the gaps CarePaw addresses
- **1.3 Objectives** — Primary and secondary goals
- **1.4 Scope** — Features included (and explicitly excluded) in this version
- **1.5 Significance** — Impact on clinic efficiency, pet owner experience,
  data integrity
- **1.6 Thesis Organization** — Chapter roadmap

### 1.2 Chapter 2: Literature Review
- **2.1 Existing Veterinary Management Systems** — Commercial (e.g., ezyVet,
  Cornerstone, AVImark) and academic projects
- **2.2 Technology Comparison** — Flutter vs. React Native vs. native; SQLite
  vs. PostgreSQL vs. Firebase; BLoC vs. Provider vs. Riverpod
- **2.3 OCR in Healthcare/Inventory** — Tesseract, ML Kit, cloud APIs;
  human-in-the-loop validation patterns
- **2.4 Real-Time Queue Systems** — WebSocket, polling, Firebase Realtime,
  Drift streams
- **2.5 Security & Privacy in Pet Health Data** — GDPR, HIPAA analogs,
  role-based access, audit logging

### 1.3 Chapter 3: System Design
- **3.1 Requirements Analysis**
  - Functional requirements (per module: auth, pets, appointments, queue,
    medical records, inventory, scanning, notifications)
  - Non-functional requirements (performance, security, usability,
    maintainability, offline-first)
  - User stories / use cases per role (Pet Owner, Veterinarian, Staff, Admin)
- **3.2 Architecture Design**
  - High-level architecture diagram (Clean Architecture layers)
  - Module decomposition (feature-first)
  - Data flow diagrams (write path, read path, scan path)
  - ADR summaries (reference ARCHITECTURE.md ADRs)
- **3.3 Database Design**
  - ER diagram (reference DATABASE.md relationships)
  - Table definitions with constraints (reference DATABASE.md)
  - Integrity rules (soft delete, append-only, traceability)
  - Indexing strategy
- **3.4 UI/UX Design**
  - User journey maps (Pet Owner, Staff, Vet — reference USER_GUIDE.md)
  - Wireframes / screen flow (to be added as UI is built)
  - Design system (colors, typography, components — reference app/theme/)
  - Accessibility considerations

### 1.4 Chapter 4: Implementation
- **4.1 Technology Stack** — Justification for each choice
- **4.2 Core Infrastructure**
  - Dependency injection setup (GetIt)
  - Error handling (Failure hierarchy)
  - Routing (GoRouter with role-based redirects)
  - Theme system (light/dark, pet-friendly palette)
  - Local storage (shared_preferences, secure_storage)
- **4.3 Feature Implementation** (per module)
  - Domain entities & repository contracts
  - Drift schema & DAO generation
  - Repository implementations
  - Business rules (status transitions, stock traceability, OCR validation)
  - BLoC state management (planned)
  - UI screens (planned — describe widget tree approach)
- **4.4 Key Algorithms / Logic**
  - Queue position calculation & reordering
  - Appointment conflict detection
  - Inventory transaction atomicity
  - Scan record confirmation flow
  - Notification scheduling (planned)

### 1.5 Chapter 5: Testing
- **5.1 Test Strategy** — Pyramid: unit → widget → integration
- **5.2 Unit Tests** — Domain logic, validators, repository contracts
- **5.3 Widget Tests** — Critical UI components (once built)
- **5.4 Integration Tests** — End-to-end flows:
  - Pet Owner: Register → Add Pet → Request Appt → Check In → View Records
  - Staff: Login → Manage Appts → Process Queue → Scan Medicine → Confirm
  - Vet: Login → View Patient → Record Visit → Create Prescription
- **5.5 Test Coverage** — Targets, tools (mocktail, bloc_test)
- **5.6 Security Testing** — Authorization checks, input validation, OCR
  sanitization

### 1.6 Chapter 6: Evaluation
- **6.1 Functional Verification** — Requirements traceability matrix
- **6.2 Performance Metrics** — App startup, DB query latency, frame times
- **6.3 Usability Evaluation** — Heuristic evaluation, user testing (planned)
- **6.4 Security Assessment** — Threat model, penetration testing notes
- **6.5 Comparison with Requirements** — Met / partial / future work

### 1.7 Chapter 7: Conclusion & Future Work
- **7.1 Summary of Contributions**
- **7.2 Limitations** — Current scope boundaries
- **7.3 Future Enhancements** — Cloud sync, telemedicine, AI-assisted
  diagnosis, multi-clinic, analytics dashboard
- **7.4 Lessons Learned**

---

## 2. Mapping Implemented Code to Thesis Sections

| Thesis Section | Implemented Code References |
|----------------|----------------------------|
| Architecture Design | `docs/ARCHITECTURE.md`, `lib/app/`, `lib/core/`, `lib/features/*/domain` |
| Database Design | `docs/DATABASE.md`, `lib/core/database/tables.dart`, `lib/core/database/database.dart` |
| Repository Contracts | `docs/API.md`, `lib/features/*/domain/repositories/` |
| Domain Entities | `lib/features/*/domain/entities/*.dart` |
| Error Handling | `lib/core/errors/failures.dart`, `lib/core/errors/exceptions.dart` |
| DI Configuration | `lib/core/di/dependency_injection.dart` |
| Routing | `lib/app/router/app_router.dart`, `lib/app/router/routes.dart` |
| Theme | `lib/app/theme/app_theme.dart`, `lib/app/theme/app_colors.dart` |
| Validators | `lib/core/utils/validators.dart` |
| Common Widgets | `lib/core/widgets/common/` |
| Security Rules | `CLAUDE.md` (Security Memory), `lib/core/security/` |

---

## 3. Diagrams to Create

### 3.1 Architecture Diagram (Layered)
```
┌─────────────────────────────────────────────┐
│           PRESENTATION (Flutter)             │
│  Widgets │ BLoCs │ GoRouter │ Theme          │
├─────────────────────────────────────────────┤
│           APPLICATION (Use Cases)            │
│  (To be added per feature)                   │
├─────────────────────────────────────────────┤
│              DOMAIN (Pure Dart)              │
│  Entities │ Repository Interfaces │ Rules    │
├─────────────────────────────────────────────┤
│               DATA (Drift/SQLite)            │
│  RepositoryImpl │ DAOs │ Tables │ Migrations │
├─────────────────────────────────────────────┤
│           CORE INFRASTRUCTURE                │
│  DI │ Errors │ Storage │ Security │ Utils   │
└─────────────────────────────────────────────┘
```

### 3.2 ER Diagram
Use the relationships in `docs/DATABASE.md` Section 2. Tools:
- `dbdiagram.io` (text-to-diagram)
- `mermaid.js` in Markdown
- Draw.io / Lucidchart

### 3.3 Data Flow Diagrams
- **Appointment Request → Confirm → Check-in → Queue → Complete**
- **Scan → OCR → Review → Confirm → Inventory Transaction**
- **Stock IN/OUT → Transaction → Batch Update → Audit Log**

### 3.4 State Machine Diagrams
- **Appointment Status Transitions** (7 states)
- **Queue Entry Status Transitions** (5 states)
- **Scan Record Status** (3 states)
- **Prescription Status** (4 states)

---

## 4. Code Metrics for Thesis

Run these to gather quantitative data:

```bash
# Lines of code (excluding generated)
find lib -name "*.dart" ! -name "*.g.dart" ! -name "*.freezed.dart" | xargs wc -l

# File count by layer
find lib/core -name "*.dart" ! -name "*.g.dart" | wc -l
find lib/features -name "*.dart" ! -name "*.g.dart" | wc -l
find lib/app -name "*.dart" ! -name "*.g.dart" | wc -l

# Test count (when added)
find test -name "*_test.dart" | wc -l

# Cyclomatic complexity (approximate)
dart run dart_code_metrics:metrics analyze lib --reporter=console
```

---

## 5. Artifacts to Include in Appendix

| Artifact | Source |
|----------|--------|
| Complete Drift schema | `lib/core/database/tables.dart` |
| Repository interfaces | `lib/features/*/domain/repositories/*.dart` |
| Entity definitions | `lib/features/*/domain/entities/*.dart` |
| Failure hierarchy | `lib/core/errors/failures.dart` |
| Routing table | `lib/app/router/routes.dart` |
| DI registration | `lib/core/di/dependency_injection.dart` |
| Theme configuration | `lib/app/theme/app_theme.dart` |
| Validators | `lib/core/utils/validators.dart` |
| ADR log | `docs/ARCHITECTURE.md` Section 3 |
| Migration history | `docs/DATABASE.md` Section 5 |

---

## 6. Defense Preparation

### 6.1 Likely Questions & Answers

**Q: Why Clean Architecture instead of a simpler structure?**
A: Separates concerns for testability, maintainability, and thesis
demonstrability. Domain logic is pure Dart with no framework dependencies.

**Q: Why Drift/SQLite instead of Firebase/PostgreSQL?**
A: Offline-first requirement, zero backend cost for thesis, type-safe SQL,
reactive streams, full control over schema/migrations.

**Q: How do you ensure OCR doesn't corrupt inventory?**
A: Scan records are stored as `PENDING` with raw OCR text, extracted data,
confidence score. Human must review and `CONFIRM` (with corrections) before
any inventory transaction is created. See `ScanRecord` entity and
`InventoryTransaction` flow.

**Q: How is medical record integrity maintained?**
A: `MedicalRecords` table has no delete/update of clinical content. Corrections
are new records with `recordType: 'NOTE'`. Audit logs capture all access.

**Q: How does the queue stay consistent?**
A: Single source of truth in `queue_entries` table. Position assigned
atomically on check-in via transaction. Reordering uses batch update in
transaction. UI watches Drift stream — no local calculation.

**Q: What about multi-device sync / cloud?**
A: Current scope is local-first. Repository interfaces are backend-agnostic;
a remote implementation can replace Drift without changing domain.

**Q: How do you handle concurrent stock updates?**
A: SQLite transactions with `PRAGMA foreign_keys = ON`. `InventoryTransaction`
records `quantityBefore` and `quantityAfter` for audit. Optimistic locking
via version column can be added.

### 6.2 Demo Script (5-10 minutes)

1. **Pet Owner:** Register → Add Pet → Request Appointment → Check In → View
   Queue Position → See Medical Record
2. **Staff:** Login → Confirm Appointment → Manage Queue (Call Next, Complete)
   → Scan Medicine Box → Review OCR → Confirm → See Inventory Updated
3. **Vet:** Login → View Assigned Patient → Open Record → Add Visit Record →
   Create Prescription
4. **Admin:** Login → User Management → Audit Logs

> Use the placeholder routes for now; swap in real screens as built.

---

## 7. Documentation Maintenance

- Update this file as the thesis evolves
- Keep `docs/` in sync with code changes (per CONTRIBUTING.md)
- Use version tags for thesis milestones (e.g., `thesis-draft-1`,
  `thesis-final`)

---

## 8. References

- [CarePaw CLAUDE.md](../CLAUDE.md) — Project memory & rules
- [Architecture](ARCHITECTURE.md) — ADRs, layer details
- [Database](DATABASE.md) — Schema, relationships, integrity
- [API/Contracts](API.md) — Repository interfaces, entities, failures
- [Development Guide](DEVELOPMENT.md) — Setup, workflows, testing
- [User Guide](USER_GUIDE.md) — End-user workflows
- [Flutter Documentation](https://docs.flutter.dev/)
- [Drift Documentation](https://drift.simonbinder.eu/)
- [BLoC Library](https://bloclibrary.dev/)

---

*This document supports the thesis documentation process. Adapt sections to
your institution's specific formatting requirements.*