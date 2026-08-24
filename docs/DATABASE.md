# CarePaw — Database Schema Documentation

This document describes the database schema, entity relationships, integrity
rules, and query patterns used by CarePaw. The database is implemented with
**Drift (SQLite)** and lives at `<app-documents>/carepaw.sqlite`.

---

## 1. Schema Overview

### 1.1 Tables

| Table | Purpose | Key Features |
|-------|---------|--------------|
| `users` | Pet owners, veterinarians, staff, admins | Roles, active flag, timestamps |
| `pets` | Patient records | Owner FK, species, breed, vitals |
| `appointments` | Scheduling | Pet FK, vet FK, strict status enum, timestamps |
| `medical_records` | Append-only health history | Pet FK, vet FK, appt FK (nullable), record type enum |
| `vaccinations` | Dedicated vaccine tracking | Pet FK, vet FK, batch, due date |
| `inventory_items` | Medicine / supply catalog | Category, unit, min/max stock, supplier |
| `inventory_batches` | Expiration & lot tracking | Item FK, batch #, qty, received/expires dates |
| `inventory_transactions` | Traceable stock movements | Batch FK, IN/OUT/ADJUSTMENT, before/after qty |
| `prescriptions` | Medication orders | MedRecord FK, pet FK, dosage, frequency, refills |
| `queue_entries` | Real-time check-in queue | Appt FK, position, status enum, room, wait estimate |
| `notifications` | User alerts | User FK, type enum, reference ID/type, read status |
| `scan_records` | OCR scans with human verification | Type enum, image path, OCR text, confidence, status |
| `audit_logs` | Security / sensitive op tracking | User FK, action, entity, old/new values (JSON), IP, UA |

---

## 2. Entity Relationships

```
users (1) ───< (N) pets
users (1) ───< (N) appointments (as veterinarian)
pets (1) ───< (N) appointments
pets (1) ───< (N) medical_records
users (1) ───< (N) medical_records (as veterinarian)
appointments (1) ───< (1) queue_entries
pets (1) ───< (N) vaccinations
users (1) ───< (N) vaccinations (as veterinarian)
pets (1) ───< (N) prescriptions
medical_records (1) ───< (N) prescriptions
inventory_items (1) ───< (N) inventory_batches
inventory_batches (1) ───< (N) inventory_transactions
users (1) ───< (N) inventory_transactions (performed_by)
users (1) ───< (N) notifications
users (1) ───< (N) scan_records (confirmed_by)
users (1) ───< (N) audit_logs
```

> **Cardinality notes:**
> - `appointments → queue_entries` is effectively **one-to-one** (one queue entry
>   per appointment).
> - `medical_records → prescriptions` is **one-to-many** (a visit may yield
>   multiple prescriptions).
> - `inventory_batches → inventory_transactions` is **one-to-many** (multiple
>   movements per batch).

---

## 3. Integrity Rules & Constraints

### 3.1 Foreign Keys
All FK columns are declared in Drift with `.references(Table, #column)`.
Foreign key enforcement is enabled via:

```sql
PRAGMA foreign_keys = ON;
```

in `MigrationStrategy.onCreate` and `beforeOpen`.

### 3.2 Soft Delete / Status Fields
- `users.is_active` — logical deletion.
- `pets.is_active` — logical deletion.
- `medical_records` — **no delete**; append-only by design. Use corrections or
  new records.
- `inventory_items` — no soft delete; use `current_stock = 0`.
- `queue_entries` — status enum transitions only (`WAITING → CALLED →
  IN_ROOM → COMPLETED` or `SKIPPED`).

### 3.3 Status Enums (enforced by CHECK constraints at app layer)
| Table | Column | Valid Values |
|-------|--------|--------------|
| users | role | `PET_OWNER`, `VETERINARIAN`, `STAFF`, `ADMIN` |
| appointments | status | `REQUESTED`, `CONFIRMED`, `CHECKED_IN`, `IN_PROGRESS`, `COMPLETED`, `CANCELLED`, `NO_SHOW` |
| medical_records | record_type | `VISIT`, `VACCINATION`, `SURGERY`, `LAB_RESULT`, `PRESCRIPTION`, `NOTE`, `ALLERGY` |
| inventory_items | category | `MEDICINE`, `VACCINE`, `SUPPLY`, `EQUIPMENT`, `FOOD` |
| prescriptions | status | `ACTIVE`, `COMPLETED`, `CANCELLED`, `EXPIRED` |
| queue_entries | status | `WAITING`, `CALLED`, `IN_ROOM`, `COMPLETED`, `SKIPPED` |
| notifications | type | `APPOINTMENT_REMINDER`, `QUEUE_UPDATE`, `PRESCRIPTION_READY`, `INVENTORY_LOW`, `SYSTEM` |
| scan_records | scan_type | `RECEIPT`, `MEDICINE_BOX`, `PRESCRIPTION`, `LAB_RESULT` |
| scan_records | status | `PENDING`, `CONFIRMED`, `REJECTED` |
| inventory_transactions | type | `IN`, `OUT`, `ADJUSTMENT` |

> Valid values are encoded as string columns with app-level validation. A future
> migration may add native CHECK constraints.

### 3.4 Stock Traceability
**Rule:** Never silently modify `inventory_items.current_stock`. All changes
must go through `inventory_transactions`:

```
Stock IN  → INSERT inventory_transactions (type='IN',  qty_change=+N, qty_before=X, qty_after=X+N)
Stock OUT → INSERT inventory_transactions (type='OUT', qty_change=-N, qty_before=X, qty_after=X-N)
Adjustment→ INSERT inventory_transactions (type='ADJUSTMENT', ...)
```

`qty_before` and `qty_after` are snapshot values captured at transaction time
for auditability.

---

## 4. Indexes

| Index | Table | Columns | Purpose |
|-------|-------|---------|---------|
| `idx_pets_owner_id` | pets | owner_id | Owner → pets lookup |
| `idx_appointments_pet_id` | appointments | pet_id | Pet → appointments |
| `idx_appointments_veterinarian_id` | appointments | veterinarian_id | Vet → appointments |
| `idx_appointments_scheduled_at` | appointments | scheduled_at | Date-range queries |
| `idx_appointments_status` | appointments | status | Status filtering |
| `idx_medical_records_pet_id` | medical_records | pet_id | Pet → records |
| `idx_medical_records_veterinarian_id` | medical_records | veterinarian_id | Vet → records |
| `idx_medical_records_record_type` | medical_records | record_type | Type filtering |
| `idx_medical_records_recorded_at` | medical_records | recorded_at | Timeline queries |
| `idx_vaccinations_pet_id` | vaccinations | pet_id | Pet → vaccines |
| `idx_vaccinations_next_due_at` | vaccinations | next_due_at | Due reminders |
| `idx_inventory_category` | inventory_items | category | Category filter |
| `idx_inventory_current_stock` | inventory_items | current_stock | Low-stock queries |
| `idx_inventory_batches_inventory_id` | inventory_batches | inventory_id | Item → batches |
| `idx_inventory_batches_expires_at` | inventory_batches | expires_at | Expiration sweep |
| `idx_prescriptions_pet_id` | prescriptions | pet_id | Pet → Rx |
| `idx_prescriptions_status` | prescriptions | status | Active Rx filter |
| `idx_prescriptions_expires_at` | prescriptions | expires_at | Expiry cleanup |
| `idx_queue_appointment_id` | queue_entries | appointment_id | Appt → queue entry |
| `idx_queue_status` | queue_entries | status | Queue board |
| `idx_queue_position` | queue_entries | position | Ordering |
| `idx_queue_room` | queue_entries | room | Room assignment |
| `idx_notifications_user_id` | notifications | user_id | User → notifications |
| `idx_notifications_type` | notifications | type | Type filter |
| `idx_notifications_is_read` | notifications | is_read | Unread badge |
| `idx_scan_records_type` | scan_records | scan_type | Type filter |
| `idx_scan_records_status` | scan_records | status | Pending review |
| `idx_scan_records_confirmed_by` | scan_records | confirmed_by | Verifier audit |
| `idx_scan_records_created_at` | scan_records | created_at | Recency |
| `idx_inventory_transactions_batch_id` | inventory_transactions | batch_id | Batch history |
| `idx_inventory_transactions_reference` | inventory_transactions | (reference_type, reference_id) | Link to appt/scan |
| `idx_inventory_transactions_created_at` | inventory_transactions | created_at | Time-series |
| `idx_audit_logs_user_id` | audit_logs | user_id | User activity |
| `idx_audit_logs_entity_type` | audit_logs | entity_type | Entity audit |
| `idx_audit_logs_created_at` | audit_logs | created_at | Time-series |

---

## 5. Migration History

| Version | Date | Description |
|---------|------|-------------|
| 1 | 2025-01-XX | Initial schema — all 13 tables, indexes, FKs |

Future migrations will be appended here with up/down scripts and
`MigrationStrategy.onUpgrade` logic.

---

## 6. Query Patterns

### 6.1 Repository Interfaces
Each feature defines a repository interface in `domain/` with methods such as:

```dart
// PetRepository
Future<Pet?> findById(int id);
Future<List<Pet>> findByOwner(int ownerId);
Future<Pet> save(Pet pet);
Future<void> delete(int id);
Stream<Pet?> watchById(int id);
Future<PaginatedResult<Pet>> findPaginated(PaginationParams params);

// AppointmentRepository
Future<List<Appointment>> findByPet(int petId, {AppointmentStatus? status});
Future<List<Appointment>> findByVeterinarian(int vetId, DateTime from, DateTime to);
Future<Appointment?> findById(int id);
Future<Appointment> save(Appointment appt);
Future<void> transitionStatus(int id, AppointmentStatus newStatus, String? reason);
Stream<List<Appointment>> watchUpcoming(int petId);

// QueueRepository
Future<QueueEntry?> findByAppointment(int appointmentId);
Future<List<QueueEntry>> getWaitingQueue();
Future<void> callNext(int queueId, String room);
Future<void> complete(int queueId);
Stream<List<QueueEntry>> watchQueue();
```

### 6.2 Drift DAOs
DAOs in `core/database/dao/` expose typed, reactive queries. Example:

```dart
// QueueDao
Stream<List<QueueEntryData>> watchWaitingQueue();
Future<QueueEntryData?> getQueueEntryForAppointment(int appointmentId);
Future<int> insertAndGetPosition(QueueEntriesCompanion entry);
Future<void> updateStatus(int id, String status, {String? room});
```

### 6.3 Common Patterns

**Paginated list:**
```dart
final params = PaginationParams(page: 1, pageSize: 20, orderBy: 'createdAt', ascending: false);
final result = await repository.findPaginated(params);
```

**Watch real-time stream:**
```dart
repository.watchQueue().listen((entries) {
  // UI rebuilds on every queue change
});
```

**Transaction (multi-table write):**
```dart
await database.transaction(() async {
  await inventoryBatchDao.updateQuantity(batchId, newQty);
  await inventoryTransactionDao.insert(Transaction(...));
  await auditLogDao.log(userId, 'STOCK_OUT', 'InventoryBatch', batchId, ...);
});
```

---

## 7. Data Integrity Guidelines

1. **Medical records are append-only** — never `DELETE`, never `UPDATE` the
   clinical content. Add a new record with `recordType: 'NOTE'` for corrections.

2. **Inventory stock is derived** — `current_stock` on `InventoryItems` is a
   cached denormalization; the *source of truth* is the sum of
   `InventoryBatches.quantity` or the `InventoryTransactions` ledger. The app
   updates the cache within the same transaction that logs the movement.

3. **Queue position is authoritative** — computed on check-in via a transaction
   that inserts the `QueueEntry` with the next `position`. Reordering requires
   a batch update within a transaction.

4. **Scan records are evidence** — `rawOcrText`, `extractedData`, `confidenceScore`,
   and any `corrections` are preserved. Only on `CONFIRMED` may downstream
   inventory updates occur.

5. **Audit logs are immutable** — once written, never modified or deleted.

---

## 8. Schema Definition Reference

See `lib/core/database/tables.dart` for the canonical Drift table definitions.
The generated DAOs in `lib/core/database/dao/*.g.dart` expose the query API.