# Waterfall Model — Phase Documentation

## 2.X Software Development Methodology

CarePaw was developed using the **Waterfall software development model**, a
sequential process in which each phase is completed and reviewed before the next
begins. The methodology was selected for a capstone project with a fixed
timeline and a defined set of functional requirements, where predictable phase
completion matters more than the ability to re-prioritise work mid-stream.

Each phase produced a documented deliverable, reviewed and signed off before
work on the following phase commenced.

---

## Phase Overview

| Phase | Name | Outcome |
|---|---|---|
| 1 | Requirements Analysis | System requirements specification |
| 2 | System Design | Architecture, database schema, UI design |
| 3 | Implementation | All 11 functional modules coded |
| 4 | Testing & Verification | Defects found and corrected |
| 5 | Deployment & Maintenance | Released, reviewed, refined |

---

## Phase 1 — Requirements Analysis

**Objective:** establish what the system must do before deciding how it will do
it.

**Activities**
- Identified the stakeholders: pet owners, veterinary staff, veterinarians, and
  clinic administrators
- Interviewed clinic staff on current practice — paper records, manual
  scheduling, unclear waiting queues, hand-written inventory
- Catalogued the functional requirements for each module
- Defined the four user roles and their permissions
- Agreed the non-functional requirements: security, data integrity, cross-platform delivery

**Deliverable:** System requirements specification covering all eight functional
modules and the security model.

**Exit criterion:** requirements agreed by the team and the project supervisor.

---

## Phase 2 — System Design

**Objective:** translate requirements into a technical blueprint.

**Activities**
- Selected the architecture: **Clean Architecture** in three layers
  (presentation, domain, data) with a strict downward-only dependency rule
- Organised the codebase **feature-first** rather than by technical layer
- Designed the data model: users, pets, appointments, queue entries, medical
  records, vaccinations, inventory items, batches, transactions, prescriptions,
  scan records, notifications, and audit logs
- Designed the RBAC model — four roles with distinct permissions
- Designed the UI: the "Soft Clinic" design language and the reusable component
  library
- Recorded four architecture decisions formally

**Deliverables**
- Architecture documentation (`CAREPAW_ARCHITECTURE.md`)
- Database design specification (`DATABASE_DESIGN.md`)
- Four accepted Architecture Decision Records — ADR-001 Clean Architecture,
  ADR-002 Feature-First Organisation, ADR-003 Immutable Medical Records,
  ADR-004 Human-Verified OCR
- Visual design specification

**Exit criterion:** architecture approved; all interfaces between layers defined.

### Design Change — See CR-001

A change to the persistence technology was raised during this phase and is
documented in **Change Request 001**. The originally specified local SQLite
database was replaced with **Google Cloud Firestore** following a scope
assessment. This is the only design change to the system.

---

## Phase 3 — Implementation

**Objective:** build each module to the Phase 2 design.

**Structure:** every module was implemented in three layers —
presentation (screens and BLoC), domain (entities, rules, repository interfaces),
and data (Firestore repositories and mappers). Work proceeded module by module,
each delivering a complete vertical slice rather than completing one layer across
all modules first.

**Modules implemented**

| # | Module | Summary |
|---|---|---|
| 1 | Authentication | Login, registration, password reset, role assignment, route guards |
| 2 | User Management | Profile, admin user and role management, account deletion |
| 3 | Pet Management | Pet profiles, ownership, list/detail/form screens |
| 4 | Appointments | Requests, confirmation, check-in, completion, status state machine |
| 5 | Queue | Live queue position, check-in, call-next, priority ordering |
| 6 | Medical Records | Visit records, append-only history, vaccinations |
| 7 | Inventory | Item catalogue, batches, expiry tracking, immutable transactions |
| 8 | Scanning | Scan records, list/detail screens, human-verified capture workflow |
| 9 | Notifications | In-app notification list, detail, preferences |
| 10 | Audit Logging | Append-only trail, admin filtering |
| 11 | Dashboards | Owner, staff, veterinarian, and admin dashboards |

**Cross-cutting work**
- Custom design system: 18 reusable components and a central token file
- Light and dark themes for all screens
- Role-adaptive bottom navigation
- Cloud Function for audited user deletion
- Firestore security rules covering all collections

**Deliverable:** a complete, runnable application across Android, iOS, and Web.

**Exit criterion:** all eleven modules functional; the application builds and runs
on all three targets.

---

## Phase 4 — Testing & Verification

**Objective:** verify the system against the Phase 1 requirements.

**Verification approach**

| Level | Method |
|---|---|
| Unit testing | `bloc_test` and `mocktail` against mocked repositories |
| Static analysis | `flutter analyze` and `flutter_lints` |
| Requirements verification | Each requirement in Phase 1 traced to its implementing module |
| Security verification | Firestore security rules reviewed per collection against the RBAC matrix |
| Data integrity verification | Confirmed medical records and inventory transactions cannot be updated or deleted |
| Manual acceptance | Each role's workflow exercised end to end |

**Defects found and corrected during this phase**

| # | Defect | Resolution |
|---|---|---|
| 1 | Text illegible in dark mode across multiple screens | Corrected theme contrast values; both modes re-verified |
| 2 | Duplicate service registration at startup | Removed the duplicate call |
| 3 | Route guards relied on string prefixes only | Verified role redirects against the full route table |
| 4 | Notification and scan records defaulted to a fixed user id | Replaced with the authenticated user |

**Defect density:** corrections were concentrated in presentation quality rather
than core logic, indicating the domain layer was built correctly.

**Deliverable:** verified application with defects closed.

**Exit criterion:** all Phase 1 requirements demonstrably implemented; no
unresolved severity-one defects.

---

## Phase 5 — Deployment & Maintenance

**Objective:** release the system and refine it after real use.

**Deployment**
- Built for Android and iOS, with Kotlin/Gradle and Xcode/Swift configurations
- Published the Web target to **Firebase Hosting**, with SPA routing configured
  so deep links survive a page refresh
- Configured Firebase App Check for release builds

**Post-deployment refinement**

| Activity | Description |
|---|---|
| Design review | Assessed the interface against real clinic usage; replaced the shadow-based surface treatment with a flat, hairline-bordered system better suited to dense data screens |
| Component consolidation | Centralised repeated button, card, and input implementations into the shared library |
| Documentation correction | Updated the project README to match the delivered architecture |

**Deliverable:** deployed application and revised documentation.

**Maintenance scope:** remaining work is limited to integrating the camera
capture and AI text recognition for the scanning module, completing the
notification delivery scheduling, and expanding unit test coverage.

---

## Phase Sequence Summary

```
1. Requirements  →  2. Design  →  3. Implementation  →  4. Testing  →  5. Deployment
        │                                                          ▲                    │
        │                                                          └──── CR-001 ─────────┘
        └─── scope assessment raises database change during design ──┘
```

Every phase produced a reviewable deliverable before the next phase began. The
single design change is documented in Change Request 001 with its rationale,
evaluation of alternatives, and impact assessment.

---

## Why Waterfall Was Chosen

| Reason | Explanation |
|---|---|
| Fixed timeline | The project had a defined submission date, so predictable phase completion mattered more than flexible re-planning |
| Defined requirements | Scope was established with the clinic stakeholders at the outset and did not change |
| Academic evaluation | The sequential model maps cleanly onto the documented chapters — requirements to Chapter 3, design and implementation to Chapter 4 |
| Traceable deliverables | Each phase produced documentation that demonstrates the design rationale, which is assessed in the defence |

The methodology's principal strength here is traceability: each phase output is
independently reviewable, and the single design change is captured formally
rather than absorbed silently into the work.