# CarePaw Thesis Documentation

This directory contains the comprehensive technical documentation for the CarePaw Smart Veterinary Patient Management System, prepared for thesis submission.

## Document Index

| Document | Description | Key Contents |
|----------|-------------|--------------|
| [DATABASE_DESIGN_THESIS.md](DATABASE_DESIGN_THESIS.md) | Complete database design documentation | Schema, tables, indexes, FKs, ADRs, migration strategy, security implications |
| [ER_DIAGRAM.md](ER_DIAGRAM.md) | Entity Relationship Diagrams | Complete mermaid ER diagram (14 tables, 17 FKs), simplified core diagram, index strategy |
| [WORKFLOWS.md](WORKFLOWS.md) | System workflows & user journeys | 4 user journeys (Pet Owner, Staff, Vet, Admin), cross-cutting workflows, notification, sync, audit |
| [STATE_MACHINES.md](STATE_MACHINES.md) | State machines for all entities | 9 state machines with valid transitions, guards, side effects, combined flow |

---

## Quick Reference

### Database Summary
- **14 Tables** covering users, pets, appointments, medical records, inventory, queue, scanning, notifications, audit, sync
- **17 Foreign Keys** enforcing referential integrity
- **35 Indexes** optimized for query patterns
- **10 Enum Fields** with database-level defaults
- **Soft Deletion** via `isActive` flags (no hard deletes)

### Key Architectural Decisions (ADRs)
1. **Local-First SQLite (Drift)** - Offline-capable, reactive streams
2. **Append-Only Medical Records** - Historical integrity, audit trail
3. **FIFO Inventory Batches** - Expiry compliance, traceability
4. **Human-Verified OCR** - Safety gate, never auto-trust
5. **Database-Authoritative Queue** - Prevents race conditions
6. **Role-Based Access Control** - PET_OWNER, VETERINARIAN, STAFF, ADMIN
7. **Reactive Streams** - Real-time UI via Drift `watch()`
8. **Sync Metadata** - Offline-first with conflict resolution

### Critical Security Rules
- ❌ Never hardcode secrets
- ❌ Never trust OCR blindly - human verification required
- ❌ Never delete medical records - use corrections/superseding
- ❌ Never expose sensitive medical info in notifications
- ✅ Authorization enforced server-side (DAO layer)
- ✅ All sensitive operations logged to audit_logs
- ✅ Database constraints protect against invalid states
- ✅ Transactions for related operations

### State Machine Highlights

| Entity | States | Terminal States | Key Guard |
|--------|--------|-----------------|-----------|
| Appointment | 7 | COMPLETED, CANCELLED, NO_SHOW | Role-based transitions |
| QueueEntry | 5 | COMPLETED, SKIPPED | Database-authoritative position |
| ScanRecord | 3 | CONFIRMED, REJECTED | Human verification required |
| Prescription | 4 | COMPLETED, CANCELLED, EXPIRED | Refill tracking |
| InventoryTransaction | 3 types | Immutable | FIFO batch consumption |

---

## Usage in Thesis

### For Database Chapter
- Reference `DATABASE_DESIGN_THESIS.md` for complete schema
- Use `ER_DIAGRAM.md` mermaid diagrams (render in LaTeX via mermaid-cli or include as images)

### For System Design Chapter
- Reference `WORKFLOWS.md` for user journey sequences
- Use sequence diagrams from workflows

### For Implementation Chapter
- Reference `STATE_MACHINES.md` for business logic enforcement
- Show how DAO methods implement transition guards

### For Security Chapter
- Reference ADRs in `DATABASE_DESIGN_THESIS.md` section 7
- Audit log design in `DATABASE_DESIGN_THESIS.md` section 5.13
- OCR verification workflow in `WORKFLOWS.md` section 2.2

---

## Generating Diagram Images

To convert mermaid diagrams to images for thesis:

```bash
# Install mermaid-cli
npm install -g @mermaid-js/mermaid-cli

# Generate ER diagram
mmdc -i ER_DIAGRAM.md -o er-diagram.png -w 1920

# Generate workflow diagrams
mmdc -i WORKFLOWS.md -o workflows.png -w 1920

# Generate state machine diagrams
mmdc -i STATE_MACHINES.md -o state-machines.png -w 1920
```

Or use VS Code extension "Markdown Preview Mermaid Support" to export.

---

## Source Code References

| Layer | Path |
|-------|------|
| Database Schema | `lib/core/database/tables.dart` |
| Domain Entities | `lib/features/*/domain/entities/*.dart` |
| DAO Implementations | `lib/core/database/dao/*.dart` |
| Repository Interfaces | `lib/features/*/domain/repositories/*.dart` |
| Application Services | `lib/features/*/application/*.dart` |
| UI Components | `lib/features/*/presentation/*.dart` |

---

*Generated for CarePaw Thesis Documentation - 2026*