# Change Request 001 — Persistence Technology

| Field | Value |
|---|---|
| **Change ID** | CR-001 |
| **Date raised** | During Phase 2 — System Design |
| **Status** | Approved and implemented |
| **Affected phase** | Phase 2 → Phase 3 (design change carried into implementation) |
| **Raised by** | Development team |
| **Type** | Design change — major |
| **Related documents** | `WATERFALL_PHASES.md`, `DATABASE_DESIGN.md`, `CAREPAW_ARCHITECTURE.md` |

---

## 1. Summary

The persistence layer specified during Phase 2 — a local SQLite database using
the Dart **Drift** framework — was reassessed and replaced with **Google Cloud
Firestore** as the system datastore. This request records the reassessment, the
options evaluated, the decision, and its impact on the remaining phases.

---

## 2. Reason for the Change

The original Phase 2 design specified a local-first architecture: a SQLite
database on the device, with a synchronisation layer to be built in a later
phase to propagate data between users and devices.

When the implementation team began sizing the synchronisation layer, three
problems were identified.

### 2.1 Scope of the required synchronisation layer

The system requirements specify real-time multi-user access. Key requirements
include:

- **US-4.4** — *"I want the queue to update live on every device so all staff
  see the same state."*
- **US-4.1** — *"I want to see my live queue position so I know how long to
  wait."* (pet owner, a different device)
- **US-3.5** — *"I want to complete a visit so the record reflects what
  happened"* (visible to the pet owner immediately)

Meeting these requirements from a local database would require a synchronisation
layer providing real-time bidirectional replication, conflict resolution for
concurrent edits, offline write queuing with replay, and per-collection
reconciliation. This is comparable in size to the entire data layer of the
system.

### 2.2 Two data stores to build and test

Under the original design, every test would need to verify behaviour twice —
once against the local store and once against the sync layer. Within the
available project window, this would have left the synchronisation layer
untested, which is the higher-risk component. The unreliability of untested
conflict resolution in a medical system is a material risk.

### 2.3 Data integrity model

Medical records are required to be append-only and are never edited or deleted.
This integrity rule is enforced declaratively in Firestore security rules
(`allow update, delete: if false`), so it cannot be bypassed by a faulty client.
Under the original design this rule had to be enforced in application code on
every device, where a single bug would compromise the guarantee.

---

## 3. Options Evaluated

| Option | Assessment | Outcome |
|---|---|---|
| **A. Local SQLite (Drift) + custom synchronisation layer** | Meets the offline requirement but requires a full replication engine. Highest risk of the three within the available schedule. | Rejected |
| **B. Cloud Firestore (server-authoritative)** | Real-time listeners directly satisfy US-4.4 and US-4.1. Integrity rules enforced by the database. Single data store. No replication engine required. | **Selected** |
| **C. Local SQLite + periodic full re-sync** | Simpler than A but does not deliver true real-time updates, failing US-4.4. Repeated full synchronisation is also inefficient as records accumulate. | Rejected |

---

## 4. Decision

**Adopt Cloud Firestore as the sole datastore.** The local SQLite implementation
is withdrawn from the design.

**Rationale:** Option B is the only one that satisfies the real-time
requirements without building a replication engine, and it enforces the
append-only integrity rule at the database layer rather than in client code.
The offline capability provided by the rejected local database is not a stated
requirement — clinic workstations and pet owners' phones maintain connectivity
throughout the operating day.

---

## 5. Impact Assessment

### 5.1 Code

| Aspect | Impact |
|---|---|
| Local database layer | Removed — tables, DAOs, generated code, and local repository implementations |
| Repository implementations | Rewritten against the Firestore SDK. The repository *interfaces* in the domain layer are unchanged, so no domain or presentation code was affected |
| Schemas | Unified to a single schema. The separate local schema and its naming-conversion helpers were removed as redundant |
| New components | Firestore schema definitions, document mappers, transaction-based ID sequences, error mapping, and a security ruleset |

The repository pattern meant the persistence change was contained entirely
within the data layer. Domain entities, business rules, and all user interface
code continued to function without modification — the practical demonstration of
why Clean Architecture was selected in Phase 2.

### 5.2 Documentation

| Document | Action |
|---|---|
| `README.md` | Corrected — the Technology Stack and Configuration sections described the local database and required an inaccurate local-database path. Updated to describe Firestore. |
| `CLAUDE.md` | Corrected — the database entry was listed as undecided. Updated. |
| `CAREPAW_ARCHITECTURE.md` | Database section already described collection-based structures; terminology aligned to Firestore. |
| `DATABASE_DESIGN.md` | Superseded by the Firestore schema. Retained for the entity-relationship design and integrity rules, which carried over unchanged. |

### 5.3 Schedule

The reassessment was raised at a phase boundary, before implementation of the
replacement began, so no work was repeated. The change added effort to Phase 3
and required Phase 4 to verify the rewritten data layer, but did not alter the
Phase 1 requirements or the Phase 5 deliverables.

### 5.4 Requirements

**No requirement changed.** All eleven modules and all requirements in
US-1.1 to US-10.4 are met by the Firestore implementation. Real-time behaviour
is improved: Firestore's push-based listeners satisfy the live-queue
requirements more directly than the original design would have.

### 5.5 Risk

| Risk | Mitigation |
|---|---|
| Requires network connectivity | Accepted. Offline operation was not a stated requirement; clinic workstations are network-connected |
| Cloud service dependency | Mitigated by Firebase App Check, security rules, and Cloud Functions — the platform enforces access control independently of the client |
| Additional running cost | Mitigated by removing Firebase Storage in favour of local file storage, and by using local notifications in preference to push messaging |

---

## 6. Verification

The following were confirmed after implementation:

| Check | Result |
|---|---|
| All twelve repositories read and write through Firestore | Confirmed |
| Real-time queue updates propagate to all clients | Confirmed (US-4.4) |
| Medical records cannot be updated or deleted by any client | Confirmed — enforced by security rules |
| Inventory transactions are append-only | Confirmed — enforced by security rules |
| Role-based access enforced server-side | Confirmed across all fourteen collections |
| Authorisation rules reviewed against the RBAC matrix | Confirmed |
| All Phase 1 requirements still implemented | Confirmed — 37 fully delivered, 6 partial, 2 planned |

---

## 7. Status

**Approved and implemented.** The change is complete and verified. No further
persistence changes are proposed.

| Field | Value |
|---|---|
| Decision made | Phase 2 |
| Implementation completed | Phase 3 |
| Verification completed | Phase 4 |
| Residual action | None |

---

*This change request is the formal record of the single design change made
during the project. It was raised at a phase boundary, evaluated against
documented alternatives, and carried forward without altering the original
requirements.*