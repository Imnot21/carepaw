# CarePaw Database Design

## Thesis Documentation - Local-First Veterinary Management System

**Version 1.0 | Schema Version 1 | August 2026**

---

## 1. Database Architecture Overview

### 1.1 Technology Selection

CarePaw implements a **local-first** data architecture using **Drift** (formerly `moor`), a reactive SQLite abstraction layer for Flutter/Dart. The selection was driven by the following thesis-relevant requirements:

| Requirement | Solution |
|-------------|----------|
| Offline-first operation | SQLite embedded database (no network dependency at runtime) |
| Strong typing | Drift generates compile-time-checked SQL queries |
| Reactive data streams | Built-in `Stream` support for real-time UI updates |
| Transaction safety | Native `transaction()` wrapper for atomic operations |
| Schema evolution | Versioned migrations via `MigrationStrategy` |
| Cross-platform | Single codebase for Android, iOS, Web, Desktop |
| Performance | Native C bindings via `sqlite3_flutter_libs` |

### 1.2 Local-First Strategy

```
┌─────────────────────────────────────────────────────────┐
│                   Presentation Layer                      │
│                    (Flutter UI)                          │
└──────────────────┬──────────────────────────────────────┘
                   │ Repository Pattern
┌──────────────────▼──────────────────────────────────────┐
│              Domain Layer (Entities)                     │
│           (Business Logic, Validation)                   │
└──────────────────┬──────────────────────────────────────┘
                   │ DAO Layer
┌──────────────────▼──────────────────────────────────────┐
│            Data Access Object Layer                      │
│         (Drift DAOs, Typed Queries)                     │
└──────────────────┬──────────────────────────────────────┘
                   │ SQLite (via Drift)
┌──────────────────▼──────────────────────────────────────┐
│         Local SQLite Database (carepaw.sqlite)          │
│         Embedded, Encrypted-Optional, Offline          │
└─────────────────────────────────────────────────────────┘
```

**Advantages for Thesis Demonstration:**
- No backend required for full functionality demonstration
- Deterministic test environment
- Instant local queries (sub-millisecond)
- Natural data ownership (single-clinic deployment)
- Simplified security model (device-level encryption)

---

## 2. Entity-Relationship Diagram

```
┌─────────────────┐
│     USERS       │◄──────────────────────────────────────┐
│─────────────────│                                        │
│ id (PK)         │──────────────┐                         │
│ email (UQ)      │              │                         │
│ role            │              │                         │
│ is_active       │              │                         │
└─────────────────┘              │                         │
         │                       │                         │
         │ 1:N                   │ 1:N                     │ N:1
         ▼                       ▼                         │
┌─────────────────┐    ┌─────────────────┐    ┌──────────────┐
│      PETS       │    │  APPOINTMENTS   │    │ AUDIT_LOGS   │
│─────────────────│    │─────────────────│    │──────────────│
│ id (PK)         │    │ id (PK)         │    │ id (PK)      │
│ owner_id (FK)   │    │ pet_id (FK)     │    │ user_id (FK) │
│ species         │    │ veterinarian_id │    │ action       │
│ breed           │    │ status          │    │ entity_type  │
└─────────────────┘    └────────┬────────┘    └──────────────┘
         │                      │
         │ 1:N                  │ 1:1
         │                      │
         ├──────────────────────┤
         │ 1:N                  │ 1:N
         ▼                      ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│ MEDICAL_RECORDS │    │  QUEUE_ENTRIES  │    │ VACCINATIONS    │
│─────────────────│    │─────────────────│    │─────────────────│
│ id (PK)         │    │ id (PK)         │    │ id (PK)         │
│ pet_id (FK)     │    │ appointment_id  │    │ pet_id (FK)     │
│ vet_id (FK)     │    │ position        │    │ vet_id (FK)     │
│ record_type     │    │ status          │    │ next_due_at     │
│ medications(JSON)│    │ room            │    │ administered_at │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │
         │ 1:N
         ▼
┌─────────────────┐    ┌─────────────────┐
│ PRESCRIPTIONS   │    │ INVENTORY_ITEMS │◄───┐
│─────────────────│    │─────────────────│    │
│ id (PK)         │    │ id (PK)         │    │
│ medical_rec(FK) │    │ name            │    │
│ pet_id (FK)     │    │ category        │    │
│ status          │    │ current_stock   │    │
└─────────────────┘    └────────┬────────┘    │
                                │ 1:N         │
                                ▼             │
                       ┌─────────────────┐    │
                       │INVENTORY_BATCHES│    │
                       │─────────────────│    │
                       │ id (PK)         │    │
                       │ inventory_id(FK)│    │
                       │ expires_at      │    │
                       │ quantity        │    │
                       └────────┬────────┘    │
                                │ 1:N         │
                                ▼             │
                       ┌─────────────────────┴┐
                       │INVENTORY_TRANSACTIONS│
                       │──────────────────────│
                       │ id (PK)              │
                       │ batch_id (FK)        │
                       │ type (IN/OUT/ADJ)    │
                       │ quantity_change      │
                       │ performed_by (FK)    │
                       └──────────────────────┘

┌─────────────────┐    ┌─────────────────┐
│ NOTIFICATIONS   │    │  SCAN_RECORDS   │
│─────────────────│    │─────────────────│
│ id (PK)         │    │ id (PK)         │
│ user_id (FK)    │    │ scan_type       │
│ type            │    │ image_path      │
│ is_read         │    │ raw_ocr_text    │
│ reference_id    │    │ confidence      │
└─────────────────┘    │ status          │
                       └─────────────────┘
```

**Legend:**
- PK = Primary Key
- FK = Foreign Key
- UQ = Unique Constraint
- JSON = Stored as TEXT (JSON-encoded)

---

## 3. Table Schema Documentation

### 3.1 Users Table

**Purpose:** Stores veterinarians, pet owners, staff, and administrators with role-based access control.

**File:** `lib/core/database/tables.dart` (lines 4-19)

| Column | Dart Type | SQL Type | Constraints | Nullable | Default |
|--------|-----------|----------|-------------|----------|---------|
| `id` | `int` | `INTEGER` | PRIMARY KEY (AUTOINCREMENT) | No | Auto |
| `email` | `String` | `TEXT` | UNIQUE, Length 3-254 | No | - |
| `passwordHash` | `String` | `TEXT` | - | No | - |
| `fullName` | `String` | `TEXT` | Length 1-100 | No | - |
| `phone` | `String?` | `TEXT` | Length 5-15 | Yes | NULL |
| `role` | `String` | `TEXT` | Enum: PET_OWNER, VETERINARIAN, STAFF, ADMIN | No | 'PET_OWNER' |
| `avatarUrl` | `String?` | `TEXT` | - | Yes | NULL |
| `isActive` | `bool` | `BOOLEAN` | - | No | true |
| `createdAt` | `DateTime` | `TIMESTAMP` | - | No | CURRENT_TIMESTAMP |
| `updatedAt` | `DateTime` | `TIMESTAMP` | - | No | CURRENT_TIMESTAMP |

**Indexes:** None declared (auto-indexed PK and UNIQUE email)

**Design Rationale:**
- Email is the natural key (unique constraint ensures no duplicate accounts)
- Password stored as hash (never plaintext - security requirement)
- Role as string enum allows easy extension without schema migration
- `isActive` enables soft-deactivation (preserves historical data references)
- No `deletedAt` column - users are never hard-deleted (audit requirement)

---

### 3.2 Pets Table

**Purpose:** Patient records owned by users.

**File:** `lib/core/database/tables.dart` (lines 22-44)

| Column | Dart Type | SQL Type | Constraints | Nullable | Default |
|--------|-----------|----------|-------------|----------|---------|
| `id` | `int` | `INTEGER` | PRIMARY KEY | No | Auto |
| `ownerId` | `int` | `INTEGER` | FK → Users(id) | No | - |
| `name` | `String` | `TEXT` | Length 1-50 | No | - |
| `species` | `String` | `TEXT` | Enum: DOG, CAT, BIRD, RABBIT, REPTILE, OTHER | No | 'DOG' |
| `breed` | `String?` | `TEXT` | Length 1-50 | Yes | NULL |
| `birthDate` | `DateTime?` | `TIMESTAMP` | - | Yes | NULL |
| `weightKg` | `double?` | `REAL` | - | Yes | NULL |
| `color` | `String?` | `TEXT` | Length 1-30 | Yes | NULL |
| `microchipId` | `String?` | `TEXT` | Length 1-20 | Yes | NULL |
| `avatarUrl` | `String?` | `TEXT` | - | Yes | NULL |
| `isActive` | `bool` | `BOOLEAN` | - | No | true |
| `createdAt` | `DateTime` | `TIMESTAMP` | - | No | CURRENT_TIMESTAMP |
| `updatedAt` | `DateTime` | `TIMESTAMP` | - | No | CURRENT_TIMESTAMP |

**Indexes:**
```sql
CREATE INDEX idx_pets_owner_id ON pets(owner_id);
```

**Design Rationale:**
- `ownerId` FK enforces ownership (prevents orphaned pets)
- `isActive` allows deactivation without losing medical history
- Species as enum (constrained vocabulary)
- Weight stored as `REAL` (supports decimals like 12.5 kg)
- Microchip ID optional (not all pets are chipped)

---

### 3.3 Appointments Table

**Purpose:** Scheduling and appointment lifecycle tracking.

**File:** `lib/core/database/tables.dart` (lines 47-77)

| Column | Dart Type | SQL Type | Constraints | Nullable | Default |
|--------|-----------|----------|-------------|----------|---------|
| `id` | `int` | `INTEGER` | PRIMARY KEY | No | Auto |
| `petId` | `int` | `INTEGER` | FK → Pets(id) | No | - |
| `veterinarianId` | `int` | `INTEGER` | FK → Users(id) | No | - |
| `scheduledAt` | `DateTime` | `TIMESTAMP` | - | No | - |
| `durationMinutes` | `int` | `INTEGER` | - | No | 30 |
| `status` | `String` | `TEXT` | Enum: REQUESTED, CONFIRMED, CHECKED_IN, IN_PROGRESS, COMPLETED, CANCELLED, NO_SHOW | No | 'REQUESTED' |
| `reason` | `String?` | `TEXT` | Length 1-200 | Yes | NULL |
| `notes` | `String?` | `TEXT` | Length 1-2000 | Yes | NULL |
| `checkInAt` | `DateTime?` | `TIMESTAMP` | - | Yes | NULL |
| `startedAt` | `DateTime?` | `TIMESTAMP` | - | Yes | NULL |
| `completedAt` | `DateTime?` | `TIMESTAMP` | - | Yes | NULL |
| `cancelledAt` | `DateTime?` | `TIMESTAMP` | - | Yes | NULL |
| `cancellationReason` | `String?` | `TEXT` | Length 1-200 | Yes | NULL |
| `createdAt` | `DateTime` | `TIMESTAMP` | - | No | CURRENT_TIMESTAMP |
| `updatedAt` | `DateTime` | `TIMESTAMP` | - | No | CURRENT_TIMESTAMP |

**Indexes:**
```sql
CREATE INDEX idx_appointments_pet_id ON appointments(pet_id);
CREATE INDEX idx_appointments_veterinarian_id ON appointments(veterinarian_id);
CREATE INDEX idx_appointments_scheduled_at ON appointments(scheduled_at);
CREATE INDEX idx_appointments_status ON appointments(status);
```

**Design Rationale:**
- Separate timestamp columns (`checkInAt`, `startedAt`, etc.) track the full lifecycle
- Status enum restricted to valid state machine values
- Multiple indexes for common queries (by pet, by vet, by date, by status)
- `cancellationReason` required when status = CANCELLED (enforced at application level)
- No cascading delete (preserves audit trail even if pet is deactivated)

---

### 3.4 Medical Records Table

**Purpose:** Append-only health history. **Immutable by design.**

**File:** `lib/core/database/tables.dart` (lines 80-110)

| Column | Dart Type | SQL Type | Constraints | Nullable | Default |
|--------|-----------|----------|-------------|----------|---------|
| `id` | `int` | `INTEGER` | PRIMARY KEY | No | Auto |
| `petId` | `int` | `INTEGER` | FK → Pets(id) | No | - |
| `veterinarianId` | `int` | `INTEGER` | FK → Users(id) | No | - |
| `appointmentId` | `int?` | `INTEGER` | FK → Appointments(id) | Yes | NULL |
| `recordType` | `String` | `TEXT` | Enum: VISIT, VACCINATION, SURGERY, LAB_RESULT, PRESCRIPTION, NOTE, ALLERGY | No | 'VISIT' |
| `title` | `String` | `TEXT` | Length 1-100 | No | - |
| `description` | `String?` | `TEXT` | Length 1-2000 | Yes | NULL |
| `diagnosis` | `String?` | `TEXT` | Length 1-1000 | Yes | NULL |
| `treatment` | `String?` | `TEXT` | Length 1-1000 | Yes | NULL |
| `medications` | `String?` | `TEXT` | JSON-encoded | Yes | NULL |
| `attachments` | `String?` | `TEXT` | JSON-encoded | Yes | NULL |
| `recordedAt` | `DateTime` | `TIMESTAMP` | - | No | CURRENT_TIMESTAMP |
| `createdAt` | `DateTime` | `TIMESTAMP` | - | No | CURRENT_TIMESTAMP |

**Indexes:**
```sql
CREATE INDEX idx_medical_records_pet_id ON medical_records(pet_id);
CREATE INDEX idx_medical_records_veterinarian_id ON medical_records(veterinarian_id);
CREATE INDEX idx_medical_records_record_type ON medical_records(record_type);
CREATE INDEX idx_medical_records_recorded_at ON medical_records(recorded_at);
```

**Design Rationale:**
- **Append-only**: No UPDATE/DELETE operations at DAO level (enforced by application)
- `medications` and `attachments` stored as JSON (flexible schema, avoids EAV table explosion)
- `appointmentId` links record to visit context (nullable for historical/imported records)
- `recordType` enables filtering (vaccinations, allergies, lab results, etc.)
- No soft-delete column - corrections create new records (superseding pattern)

---

### 3.5 Vaccinations Table

**Purpose:** Specific vaccine tracking with due date calculation.

**File:** `lib/core/database/tables.dart` (lines 113-132)

| Column | Dart Type | SQL Type | Constraints | Nullable | Default |
|--------|-----------|----------|-------------|----------|---------|
| `id` | `int` | `INTEGER` | PRIMARY KEY | No | Auto |
| `petId` | `int` | `INTEGER` | FK → Pets(id) | No | - |
| `veterinarianId` | `int` | `INTEGER` | FK → Users(id) | No | - |
| `vaccineName` | `String` | `TEXT` | Length 1-100 | No | - |
| `manufacturer` | `String?` | `TEXT` | Length 1-100 | Yes | NULL |
| `batchNumber` | `String?` | `TEXT` | Length 1-50 | Yes | NULL |
| `administeredAt` | `DateTime` | `TIMESTAMP` | - | No | - |
| `nextDueAt` | `DateTime?` | `TIMESTAMP` | - | Yes | NULL |
| `notes` | `String?` | `TEXT` | Length 1-500 | Yes | NULL |
| `createdAt` | `DateTime` | `TIMESTAMP` | - | No | CURRENT_TIMESTAMP |

**Indexes:**
```sql
CREATE INDEX idx_vaccinations_pet_id ON vaccinations(pet_id);
CREATE INDEX idx_vaccinations_next_due_at ON vaccinations(next_due_at);
```

**Design Rationale:**
- Separate from MedicalRecords for specialized queries (due date reminders)
- `nextDueAt` enables proactive notification scheduling
- `batchNumber` supports traceability (recall scenarios)
- `administeredAt` is non-nullable (vaccine must have administration date)

---

### 3.6 Inventory Items Table

**Purpose:** Medicine and supply catalog with stock levels.

**File:** `lib/core/database/tables.dart` (lines 135-160)

| Column | Dart Type | SQL Type | Constraints | Nullable | Default |
|--------|-----------|----------|-------------|----------|---------|
| `id` | `int` | `INTEGER` | PRIMARY KEY | No | Auto |
| `name` | `String` | `TEXT` | Length 1-100 | No | - |
| `category` | `String` | `TEXT` | Enum: MEDICINE, VACCINE, SUPPLY, EQUIPMENT, FOOD | No | 'MEDICINE' |
| `unit` | `String` | `TEXT` | Length 1-20 | No | - |
| `currentStock` | `double` | `REAL` | - | No | 0.0 |
| `minStock` | `double` | `REAL` | - | No | 0.0 |
| `maxStock` | `double?` | `REAL` | - | Yes | NULL |
| `unitCost` | `double?` | `REAL` | - | Yes | NULL |
| `supplier` | `String?` | `TEXT` | Length 1-100 | Yes | NULL |
| `location` | `String?` | `TEXT` | Length 1-50 | Yes | NULL |
| `createdAt` | `DateTime` | `TIMESTAMP` | - | No | CURRENT_TIMESTAMP |
| `updatedAt` | `DateTime` | `TIMESTAMP` | - | No | CURRENT_TIMESTAMP |

**Indexes:**
```sql
CREATE INDEX idx_inventory_category ON inventory_items(category);
CREATE INDEX idx_inventory_current_stock ON inventory_items(current_stock);
```

**Design Rationale:**
- `currentStock` is derived from batch quantities (updated via transactions)
- `minStock` / `maxStock` enable automated low-stock alerts
- `category` enum for filtering (separate from medical records)
- `unitCost` nullable (some items don't have direct cost, e.g., donations)
- No `deletedAt` - items deactivated via `isActive` pattern (not shown here but implied)

---

### 3.7 Inventory Batches Table

**Purpose:** Lot-level tracking with expiration dates (FIFO consumption).

**File:** `lib/core/database/tables.dart` (lines 163-180)

| Column | Dart Type | SQL Type | Constraints | Nullable | Default |
|--------|-----------|----------|-------------|----------|---------|
| `id` | `int` | `INTEGER` | PRIMARY KEY | No | Auto |
| `inventoryId` | `int` | `INTEGER` | FK → InventoryItems(id) | No | - |
| `batchNumber` | `String` | `TEXT` | Length 1-50 | No | - |
| `quantity` | `double` | `REAL` | - | No | - |
| `receivedAt` | `DateTime` | `TIMESTAMP` | - | No | CURRENT_TIMESTAMP |
| `expiresAt` | `DateTime?` | `TIMESTAMP` | - | Yes | NULL |
| `costPerUnit` | `double?` | `REAL` | - | Yes | NULL |
| `supplier` | `String?` | `TEXT` | Length 1-100 | Yes | NULL |
| `createdAt` | `DateTime` | `TIMESTAMP` | - | No | CURRENT_TIMESTAMP |

**Indexes:**
```sql
CREATE INDEX idx_inventory_batches_inventory_id ON inventory_batches(inventory_id);
CREATE INDEX idx_inventory_batches_expires_at ON inventory_batches(expires_at);
```

**Design Rationale:**
- **FIFO consumption**: Queries order by `expiresAt` ASC (earliest expiry consumed first)
- `batchNumber` enables recall tracing
- `expiresAt` nullable (non-expiring items like equipment)
- `quantity` is authoritative (current remaining in this batch)
- No soft-delete: batches are never deleted (audit requirement for pharmaceuticals)

---

### 3.8 Inventory Transactions Table

**Purpose:** **Immutable audit trail of all stock movements.**

**File:** `lib/core/database/tables.dart` (lines 269-294)

| Column | Dart Type | SQL Type | Constraints | Nullable | Default |
|--------|-----------|----------|-------------|----------|---------|
| `id` | `int` | `INTEGER` | PRIMARY KEY | No | Auto |
| `batchId` | `int` | `INTEGER` | FK → InventoryBatches(id) | No | - |
| `type` | `String` | `TEXT` | Enum: IN, OUT, ADJUSTMENT | No | 'ADJUSTMENT' |
| `quantityChange` | `double` | `REAL` | - | No | - |
| `quantityBefore` | `double` | `REAL` | - | No | - |
| `quantityAfter` | `double` | `REAL` | - | No | - |
| `reason` | `String` | `TEXT` | Length 1-200 | No | - |
| `referenceType` | `String?` | `TEXT` | Length 1-50 | Yes | NULL |
| `referenceId` | `int?` | `INTEGER` | - | Yes | NULL |
| `performedBy` | `int` | `INTEGER` | FK → Users(id) | No | - |
| `notes` | `String?` | `TEXT` | Length 1-500 | Yes | NULL |
| `createdAt` | `DateTime` | `TIMESTAMP` | - | No | CURRENT_TIMESTAMP |

**Indexes:**
```sql
CREATE INDEX idx_inventory_transactions_batch_id ON inventory_transactions(batch_id);
CREATE INDEX idx_inventory_transactions_reference ON inventory_transactions(reference_type, reference_id);
CREATE INDEX idx_inventory_transactions_created_at ON inventory_transactions(created_at);
```

**Design Rationale:**
- **Append-only**: No UPDATE/DELETE (financial/regulatory requirement)
- `quantityBefore` / `quantityAfter` = full state snapshot (no recalculation needed)
- `referenceType` / `referenceId` links to source (appointment, prescription, scan)
- `performedBy` enforces accountability
- Composite index on (reference_type, reference_id) for fast lookups
- Type enum: IN (stock receipt), OUT (consumption/dispense), ADJUSTMENT (correction)

---

### 3.9 Prescriptions Table

**Purpose:** Medication orders linked to medical records.

**File:** `lib/core/database/tables.dart` (lines 183-210)

| Column | Dart Type | SQL Type | Constraints | Nullable | Default |
|--------|-----------|----------|-------------|----------|---------|
| `id` | `int` | `INTEGER` | PRIMARY KEY | No | Auto |
| `medicalRecordId` | `int` | `INTEGER` | FK → MedicalRecords(id) | No | - |
| `petId` | `int` | `INTEGER` | FK → Pets(id) | No | - |
| `medicationName` | `String` | `TEXT` | Length 1-100 | No | - |
| `dosage` | `String` | `TEXT` | Length 1-50 | No | - |
| `frequency` | `String` | `TEXT` | Length 1-50 | No | - |
| `durationDays` | `int` | `INTEGER` | - | No | - |
| `quantity` | `double` | `REAL` | - | No | - |
| `refillsRemaining` | `int` | `INTEGER` | - | No | 0 |
| `instructions` | `String?` | `TEXT` | Length 1-500 | Yes | NULL |
| `prescribedAt` | `DateTime` | `TIMESTAMP` | - | No | CURRENT_TIMESTAMP |
| `expiresAt` | `DateTime?` | `TIMESTAMP` | - | Yes | NULL |
| `status` | `String` | `TEXT` | Enum: ACTIVE, COMPLETED, CANCELLED, EXPIRED | No | 'ACTIVE' |
| `createdAt` | `DateTime` | `TIMESTAMP` | - | No | CURRENT_TIMESTAMP |

**Indexes:**
```sql
CREATE INDEX idx_prescriptions_pet_id ON prescriptions(pet_id);
CREATE INDEX idx_prescriptions_status ON prescriptions(status);
CREATE INDEX idx_prescriptions_expires_at ON prescriptions(expires_at);
```

**Design Rationale:**
- `medicalRecordId` links to visit context
- `refillsRemaining` enables refill tracking without new prescription
- `expiresAt` supports medication expiry (controlled substances)
- Status enum: ACTIVE (in use), COMPLETED (course finished), CANCELLED, EXPIRED
- No hard-delete (prescriptions are legal documents)

---

### 3.10 Queue Entries Table

**Purpose:** Real-time clinic queue with positions and status.

**File:** `lib/core/database/tables.dart` (lines 213-240)

| Column | Dart Type | SQL Type | Constraints | Nullable | Default |
|--------|-----------|----------|-------------|----------|---------|
| `id` | `int` | `INTEGER` | PRIMARY KEY | No | Auto |
| `appointmentId` | `int` | `INTEGER` | FK → Appointments(id) | No | - |
| `position` | `int` | `INTEGER` | - | No | - |
| `status` | `String` | `TEXT` | Enum: WAITING, CALLED, IN_ROOM, COMPLETED, SKIPPED | No | 'WAITING' |
| `checkedInAt` | `DateTime` | `TIMESTAMP` | - | No | CURRENT_TIMESTAMP |
| `calledAt` | `DateTime?` | `TIMESTAMP` | - | Yes | NULL |
| `roomEnteredAt` | `DateTime?` | `TIMESTAMP` | - | Yes | NULL |
| `completedAt` | `DateTime?` | `TIMESTAMP` | - | Yes | NULL |
| `room` | `String?` | `TEXT` | - | Yes | NULL |
| `estimatedWaitMinutes` | `int?` | `INTEGER` | - | Yes | NULL |
| `notes` | `String?` | `TEXT` | - | Yes | NULL |
| `createdAt` | `DateTime` | `TIMESTAMP` | - | No | CURRENT_TIMESTAMP |
| `updatedAt` | `DateTime?` | `TIMESTAMP` | - | Yes | NULL |

**Indexes:**
```sql
CREATE INDEX idx_queue_appointment_id ON queue_entries(appointment_id);
CREATE INDEX idx_queue_status ON queue_entries(status);
CREATE INDEX idx_queue_position ON queue_entries(position);
CREATE INDEX idx_queue_room ON queue_entries(room);
```

**Design Rationale:**
- **Database is authoritative** (not UI-calculated) - ensures consistency
- `position` is integer (reordered on skip/complete)
- `status` enum: WAITING → CALLED → IN_ROOM → COMPLETED (or SKIPPED)
- `room` enables multi-room clinic support
- Real-time updates via Drift `Stream` queries
- No FK cascading (queue entry preserved even if appointment modified)

---

### 3.11 Notifications Table

**Purpose:** User alerts (reminders, queue updates, etc.).

**File:** `lib/core/database/tables.dart` (lines 243-266)

| Column | Dart Type | SQL Type | Constraints | Nullable | Default |
|--------|-----------|----------|-------------|----------|---------|
| `id` | `int` | `INTEGER` | PRIMARY KEY | No | Auto |
| `userId` | `int` | `INTEGER` | FK → Users(id) | No | - |
| `type` | `String` | `TEXT` | Enum: APPOINTMENT_REMINDER, QUEUE_UPDATE, PRESCRIPTION_READY, INVENTORY_LOW, SYSTEM | No | 'SYSTEM' |
| `title` | `String` | `TEXT` | Length 1-100 | No | - |
| `message` | `String` | `TEXT` | Length 1-500 | No | - |
| `referenceId` | `int?` | `INTEGER` | - | Yes | NULL |
| `referenceType` | `String?` | `TEXT` | Length 1-50 | Yes | NULL |
| `isRead` | `bool` | `BOOLEAN` | - | No | false |
| `readAt` | `DateTime?` | `TIMESTAMP` | - | Yes | NULL |
| `createdAt` | `DateTime` | `TIMESTAMP` | - | No | CURRENT_TIMESTAMP |

**Indexes:**
```sql
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_type ON notifications(type);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);
```

**Design Rationale:**
- `userId` FK ensures private notifications (no cross-user leakage)
- `type` enables filtering and notification preferences
- `referenceId` / `referenceType` links to source entity
- `isRead` / `readAt` track engagement
- Extensible: New notification types added without schema change
- No sensitive medical data in `message` (privacy requirement)

---

### 3.12 Scan Records Table

**Purpose:** OCR scan artifacts with human verification workflow.

**File:** `lib/core/database/tables.dart` (lines 297-325)

| Column | Dart Type | SQL Type | Constraints | Nullable | Default |
|--------|-----------|----------|-------------|----------|---------|
| `id` | `int` | `INTEGER` | PRIMARY KEY | No | Auto |
| `scanType` | `String` | `TEXT` | Enum: RECEIPT, MEDICINE_BOX, PRESCRIPTION, LAB_RESULT | No | 'RECEIPT' |
| `imagePath` | `String` | `TEXT` | Length 1-500 | No | - |
| `rawOcrText` | `String?` | `TEXT` | - | Yes | NULL |
| `extractedData` | `String?` | `TEXT` | JSON-encoded | Yes | NULL |
| `confidenceScore` | `double?` | `REAL` | 0.0-1.0 | Yes | NULL |
| `status` | `String` | `TEXT` | Enum: PENDING, CONFIRMED, REJECTED | No | 'PENDING' |
| `confirmedBy` | `int?` | `INTEGER` | FK → Users(id) | Yes | NULL |
| `confirmedAt` | `DateTime?` | `TIMESTAMP` | - | Yes | NULL |
| `corrections` | `String?` | `TEXT` | JSON-encoded | Yes | NULL |
| `createdAt` | `DateTime` | `TIMESTAMP` | - | No | CURRENT_TIMESTAMP |

**Indexes:**
```sql
CREATE INDEX idx_scan_records_type ON scan_records(scan_type);
CREATE INDEX idx_scan_records_status ON scan_records(status);
CREATE INDEX idx_scan_records_confirmed_by ON scan_records(confirmed_by);
CREATE INDEX idx_scan_records_created_at ON scan_records(created_at);
```

**Design Rationale:**
- **OCR never trusted blindly** (security requirement)
- `status` workflow: PENDING → CONFIRMED/REJECTED (human-in-loop)
- `confidenceScore` enables low-confidence flagging
- `corrections` stores user edits (audit trail for OCR accuracy)
- `confirmedBy` enforces accountability
- Image stored as path (not BLOB) - keeps DB small, files in secure storage

---

### 3.13 Audit Logs Table

**Purpose:** Security audit trail for sensitive operations.

**File:** `lib/core/database/tables.dart` (lines 328-350)

| Column | Dart Type | SQL Type | Constraints | Nullable | Default |
|--------|-----------|----------|-------------|----------|---------|
| `id` | `int` | `INTEGER` | PRIMARY KEY | No | Auto |
| `userId` | `int?` | `INTEGER` | FK → Users(id) | Yes | NULL |
| `action` | `String` | `TEXT` | Length 1-50 | No | - |
| `entityType` | `String` | `TEXT` | Length 1-50 | No | - |
| `entityId` | `int?` | `INTEGER` | - | Yes | NULL |
| `oldValues` | `String?` | `TEXT` | JSON-encoded | Yes | NULL |
| `newValues` | `String?` | `TEXT` | JSON-encoded | Yes | NULL |
| `ipAddress` | `String?` | `TEXT` | Length 1-45 | Yes | NULL |
| `userAgent` | `String?` | `TEXT` | Length 1-200 | Yes | NULL |
| `createdAt` | `DateTime` | `TIMESTAMP` | - | No | CURRENT_TIMESTAMP |

**Indexes:**
```sql
CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_entity_type ON audit_logs(entity_type);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at);
```

**Design Rationale:**
- **Immutable** (no UPDATE/DELETE)
- `action` captures what happened (LOGIN, CREATE, UPDATE, DELETE, etc.)
- `entityType` / `entityId` enable entity-specific audit queries
- `oldValues` / `newValues` JSON snapshots (full state change record)
- `userId` nullable (system actions, anonymous failures)
- IP/User-Agent for forensic analysis
- Retention policy: Delete older than N days (configurable)

---

## 4. Relationship Mapping

### 4.1 Foreign Key Relationships

| Child Table | Column | Parent Table | On Delete | Cardinality |
|-------------|--------|--------------|-----------|-------------|
| `Pets` | `ownerId` | `Users` | RESTRICT | 1:N (User → Pets) |
| `Appointments` | `petId` | `Pets` | RESTRICT | 1:N (Pet → Appointments) |
| `Appointments` | `veterinarianId` | `Users` | RESTRICT | 1:N (User → Appointments) |
| `MedicalRecords` | `petId` | `Pets` | RESTRICT | 1:N (Pet → Records) |
| `MedicalRecords` | `veterinarianId` | `Users` | RESTRICT | 1:N (User → Records) |
| `MedicalRecords` | `appointmentId` | `Appointments` | SET NULL | 1:1 (Appointment → Record) |
| `Vaccinations` | `petId` | `Pets` | RESTRICT | 1:N (Pet → Vaccinations) |
| `Vaccinations` | `veterinarianId` | `Users` | RESTRICT | 1:N (User → Vaccinations) |
| `InventoryBatches` | `inventoryId` | `InventoryItems` | RESTRICT | 1:N (Item → Batches) |
| `InventoryTransactions` | `batchId` | `InventoryBatches` | RESTRICT | 1:N (Batch → Transactions) |
| `InventoryTransactions` | `performedBy` | `Users` | RESTRICT | 1:N (User → Transactions) |
| `Prescriptions` | `medicalRecordId` | `MedicalRecords` | RESTRICT | 1:N (Record → Prescriptions) |
| `Prescriptions` | `petId` | `Pets` | RESTRICT | 1:N (Pet → Prescriptions) |
| `QueueEntries` | `appointmentId` | `Appointments` | RESTRICT | 1:1 (Appointment → Queue) |
| `Notifications` | `userId` | `Users` | RESTRICT | 1:N (User → Notifications) |
| `ScanRecords` | `confirmedBy` | `Users` | SET NULL | 1:N (User → Scans) |
| `AuditLogs` | `userId` | `Users` | SET NULL | 1:N (User → AuditLogs) |

### 4.2 Cardinality Summary

```
User (1) ────< (N) Pet
User (1) ────< (N) Appointment (as vet)
Pet (1) ──────< (N) Appointment
Appointment (1) ──< (N) MedicalRecord (optional)
Pet (1) ──────< (N) MedicalRecord
User (1) ────< (N) MedicalRecord (as vet)
Pet (1) ──────< (N) Vaccination
User (1) ────< (N) Vaccination (as vet)
InventoryItem (1) ──< (N) InventoryBatch
InventoryBatch (1) ──< (N) InventoryTransaction
User (1) ────< (N) InventoryTransaction (as performer)
MedicalRecord (1) ──< (N) Prescription
Pet (1) ──────< (N) Prescription
Appointment (1) ──< (1) QueueEntry
User (1) ────< (N) Notification
User (1) ────< (N) ScanRecord (as confirmer)
User (1) ────< (N) AuditLog
```

---

## 5. Data Access Object (DAO) Layer

### 5.1 DAO Architecture

Each DAO extends `DatabaseAccessor<CarePawDatabase>` and mixes in generated `*Mixin`:

```dart
@DriftAccessor(tables: [Users, Pets])
class UsersDao extends DatabaseAccessor<CarePawDatabase> 
    with _$UsersDaoMixin {
  UsersDao(super.db);
  // Queries and mutations...
}
```

### 5.2 Users DAO

**File:** `lib/core/database/dao/users_dao.dart`

**Queries:**
- `getById(int)` - Fetch user by primary key
- `findByEmail(String)` - Lookup by unique email (login)
- `getAll()` - List all users (admin)
- `getByRole(UserRole)` - Filter by role
- `getActive()` - List active users only
- `search(String)` - Fuzzy search by name/email
- `watchAll()` - Real-time stream of all users

**Mutations:**
- `create(UsersCompanion)` - Insert new user (registration)
- `update(UsersCompanion)` - Update profile (replace pattern)
- `deactivate(int)` - Soft-deactivate (set isActive=false)
- `setRole(int, String)` - Admin role change

**Design Notes:**
- No hard delete (preserves references)
- Password hash never exposed in queries
- Role filtering via string enum

---

### 5.3 Pets DAO

**File:** `lib/core/database/dao/pets_dao.dart`

**Queries:**
- `getById(int)` - Fetch pet by PK
- `getByOwner(int)` - All pets for an owner
- `getAll()` - List all pets (vet/staff)
- `search(String)` - Search by name/breed/species
- `watchByOwner(int)` - Real-time stream for owner's pets

**Mutations:**
- `create(PetsCompanion)` - Add new pet
- `update(PetsCompanion)` - Update pet info
- `deactivate(int)` - Soft-delete (preserves medical history)

**Design Notes:**
- Ownership enforced at query level (ownerId filter)
- No cross-owner data leakage

---

### 5.4 Appointments DAO

**File:** `lib/core/database/dao/appointments_dao.dart`

**Queries:**
- `getById(int)` - Fetch appointment
- `getByPet(int)` - Pet's appointment history
- `getByVeterinarian(int)` - Vet's schedule
- `getByStatus(String)` - Filter by status
- `getUpcomingForPet(int)` - Future appointments
- `getTodaysAppointments(int)` - Today's schedule for vet
- `getWithDetails(int)` - **JOIN**: appointment + pet + vet
- `watchByPet(int)` - Real-time stream

**Mutations:**
- `create(AppointmentsCompanion)` - New appointment request
- `updateStatus(int, String, {...})` - Status workflow transition
- `checkIn(int)` - Mark CHECKED_IN
- `start(int)` - Mark IN_PROGRESS
- `complete(int)` - Mark COMPLETED
- `cancel(int, String)` - Mark CANCELLED + reason

**Join Example:**
```dart
final query = select(appointments).join([
  innerJoin(pets, pets.id.equalsExp(appointments.petId)),
  innerJoin(users, users.id.equalsExp(appointments.veterinarianId)),
]);
```

**Design Notes:**
- Status transitions validated at application layer
- Timestamp columns updated conditionally (only when provided)
- Join queries eliminate N+1 problems

---

### 5.5 Medical Records DAO

**File:** `lib/core/database/dao/medical_records_dao.dart`

**Queries:**
- `getById(int)` - Fetch record
- `getByPet(int)` - Chronological pet history
- `getByType(int, String)` - Filter by record type
- `getByAppointment(int)` - Records for visit
- `getWithDetails(int)` - **JOIN**: record + pet + vet + appointment
- `getRecent({limit})` - Cross-pet recent records (vet dashboard)
- `watchByPet(int)` - Real-time stream

**Mutations:**
- `createRecord(MedicalRecordsCompanion)` - **Append only**
- `createVisitRecord({...})` - Typed helper
- `createVaccinationRecord({...})` - Typed helper
- `createAllergyRecord({...})` - Typed helper
- `createLabResultRecord({...})` - Typed helper

**Design Notes:**
- **No update/delete methods** (immutable by design)
- Corrections create new records (superseding pattern)
- Typed helpers enforce required fields per type

---

### 5.6 Vaccinations DAO

**File:** `lib/core/database/dao/vaccinations_dao.dart`

**Queries:**
- `getById(int)` - Fetch vaccination
- `getByPet(int)` - Pet's vaccination history
- `getDueSoon({days})` - Upcoming due dates
- `getOverdue()` - Past due dates
- `watchByPet(int)` - Real-time stream

**Mutations:**
- `create(VaccinationsCompanion)` - New vaccination
- `update(VaccinationsCompanion)` - Update (rare)

**Design Notes:**
- Separate from MedicalRecords for due-date queries
- `nextDueAt` enables proactive reminders

---

### 5.7 Inventory Items DAO

**File:** `lib/core/database/dao/inventory_dao.dart`

**Queries:**
- `getItemById(int)` - Fetch item
- `getAllItems()` - Catalog
- `getItemsByCategory(String)` - Filter by category
- `getLowStockItems()` - Below minStock threshold
- `searchItems(String)` - Search by name
- `watchAllItems()` - Real-time stream

**Mutations:**
- `createItem(InventoryItemsCompanion)` - New catalog item
- `updateItem(InventoryItemsCompanion)` - Update metadata
- `updateStock(int, double)` - Set stock level (atomic)
- `adjustStock(int, double)` - **Transaction**: delta adjustment
- `createBatch(InventoryBatchesCompanion)` - New batch
- `updateBatch(InventoryBatchesCompanion)` - Update batch
- `consumeFromBatches(int, double)` - **FIFO consumption**

**Transaction Example:**
```dart
Future<double> consumeFromBatches(int itemId, double quantity) async {
  return transaction(() async {
    double remaining = quantity;
    final batches = await getBatchesForItem(itemId); // Ordered by expiresAt ASC
    
    for (final batch in batches) {
      if (remaining <= 0) break;
      final available = batch.quantity;
      final toConsume = remaining < available ? remaining : available;
      
      await (update(inventoryBatches)..where((b) => b.id.equals(batch.id)))
          .write(InventoryBatchesCompanion(quantity: Value(available - toConsume)));
      
      remaining -= toConsume;
    }
    
    final item = await getItemById(itemId);
    if (item != null) {
      await updateStock(itemId, item.currentStock - (quantity - remaining));
    }
    
    return quantity - remaining; // Actual consumed
  });
}
```

**Design Notes:**
- **FIFO**: Batches consumed in expiry order (reduces waste)
- `adjustStock` wraps in transaction (atomic)
- Stock level derived from batch quantities
- No direct stock overwrite (always via transaction)

---

### 5.8 Inventory Transactions DAO

**File:** `lib/core/database/dao/inventory_transactions_dao.dart`

**Queries:**
- `getById(int)` - Fetch transaction
- `getByBatch(int)` - Batch history
- `getByReference(String, int)` - Source-linked transactions
- `getByDateRange(DateTime, DateTime)` - Time-filtered
- `getRecent({limit})` - Recent activity

**Mutations:**
- `create(InventoryTransactionsCompanion)` - **Append only**

**Design Notes:**
- **Immutable**: No UPDATE/DELETE
- Full state snapshot (before/after)
- Links to source via referenceType/referenceId

---

### 5.9 Prescriptions DAO

**File:** `lib/core/database/dao/prescriptions_dao.dart`

**Queries:**
- `getById(int)` - Fetch prescription
- `getByPet(int)` - Pet's prescriptions
- `getByMedicalRecord(int)` - Visit prescriptions
- `getActive()` - Currently active
- `getExpiringSoon({days})` - Upcoming expiry
- `watchByPet(int)` - Real-time stream

**Mutations:**
- `create(PrescriptionsCompanion)` - New prescription
- `updateStatus(int, String)` - Status transition
- `decrementRefill(int)` - Refill consumed

**Design Notes:**
- Linked to medical record (visit context)
- Refill tracking without new prescription
- Status: ACTIVE → COMPLETED/CANCELLED/EXPIRED

---

### 5.10 Queue DAO

**File:** `lib/core/database/dao/queue_dao.dart`

**Queries:**
- `getById(int)` - Fetch queue entry
- `getByAppointment(int)` - Queue for appointment
- `getCurrentQueue()` - **JOIN**: all active entries + details
- `watchCurrentQueue()` - **Real-time stream** of queue
- `getNextPosition()` - Calculate next position

**Mutations:**
- `addToQueue(QueueEntriesCompanion)` - Check-in
- `updateQueueEntry(QueueEntriesCompanion)` - Update status
- `callNext()` - Mark next WAITING as CALLED
- `moveToRoom(int)` - Mark IN_ROOM
- `complete(int)` - Mark COMPLETED
- `skip(int)` - Mark SKIPPED
- `repositionQueue()` - Reorder after skip/complete

**Join Example:**
```dart
final query = select(queueEntries).join([
  innerJoin(appointments, appointments.id.equalsExp(queueEntries.appointmentId)),
  innerJoin(pets, pets.id.equalsExp(appointments.petId)),
  innerJoin(users, users.id.equalsExp(appointments.veterinarianId)),
])..where(queueEntries.status.isIn(['WAITING', 'CALLED', 'IN_ROOM']));
```

**Design Notes:**
- **Database is authoritative** (not UI state)
- Real-time updates via Drift streams
- Position recalculated on skip/complete
- FIFO queue ordering

---

### 5.11 Notifications DAO

**File:** `lib/core/database/dao/notifications_dao.dart`

**Queries:**
- `getById(int)` - Fetch notification
- `getByUser(int)` - User's notifications
- `getUnread(int)` - Unread only
- `getByType(String)` - Filter by type
- `watchByUser(int)` - Real-time stream

**Mutations:**
- `create(NotificationsCompanion)` - New notification
- `markRead(int)` - Set isRead=true
- `markAllRead(int)` - Bulk read
- `delete(int)` - Hard delete (retention policy)

**Design Notes:**
- Private to user (userId filter)
- No sensitive data in message body
- Retention: Old notifications pruned

---

### 5.12 Scan Records DAO

**File:** `lib/core/database/dao/scan_records_dao.dart`

**Queries:**
- `getById(int)` - Fetch scan
- `getByStatus(String)` - Filter by status
- `getPending()` - Awaiting review
- `getByType(String)` - Filter by scan type
- `getByUser(int)` - Scans confirmed by user

**Mutations:**
- `create(ScanRecordsCompanion)` - New scan (PENDING)
- `confirm(int, int)` - Mark CONFIRMED + confirmer
- `reject(int, int)` - Mark REJECTED + reviewer
- `updateCorrections(int, String)` - Store user edits

**Design Notes:**
- **OCR never trusted** (status starts PENDING)
- Human verification required before inventory update
- Corrections tracked for accuracy metrics

---

### 5.13 Audit Logs DAO

**File:** `lib/core/database/dao/audit_logs_dao.dart`

**Queries:**
- `getById(int)` - Fetch log entry
- `getByEntity(String, int)` - Entity-specific history
- `getByUser(int)` - User action history
- `getByAction(String)` - Filter by action type
- `getRecent({limit})` - Recent activity
- `getInRange(DateTime, DateTime)` - Date-filtered

**Mutations:**
- `create(AuditLogsCompanion)` - **Append only**
- `log({...})` - Typed helper with auto-timestamp

**Design Notes:**
- **Immutable**: No UPDATE/DELETE
- Automatic timestamp on creation
- JSON snapshots for full state change record

---

## 6. Design Decisions & Rationale

### 6.1 Local-First Offline Architecture

**Decision:** Use embedded SQLite (Drift) instead of remote database.

**Rationale:**
1. **Thesis Demonstration**: Full functionality without backend dependency
2. **Offline Resilience**: Clinic continues during network outage
3. **Data Privacy**: Medical data never leaves device by default
4. **Performance**: Sub-millisecond local queries
5. **Simplicity**: No server infrastructure to maintain

**Trade-off:** Multi-clinic sync requires additional layer (future work).

---

### 6.2 Append-Only Medical Records

**Decision:** Medical records cannot be updated or deleted.

**Rationale:**
1. **Legal Compliance**: Medical history must be preserved
2. **Audit Integrity**: No silent modifications
3. **Patient Safety**: Historical context always available
4. **Liability Protection**: Full record trail

**Implementation:**
- DAO provides only `createRecord()` methods
- Corrections create new records (superseding pattern)
- Application layer enforces no-update rule

---

### 6.3 FIFO Inventory Batches

**Decision:** Consume batches in expiry-date order.

**Rationale:**
1. **Waste Reduction**: Expiring stock used first
2. **Regulatory Compliance**: Pharmaceutical FIFO requirement
3. **Cost Optimization**: Minimize expired inventory loss
4. **Traceability**: Batch-level tracking for recalls

**Implementation:**
```dart
// In consumeFromBatches():
final batches = await getBatchesForItem(itemId); 
// Ordered by expiresAt ASC (see getBatchesForItem query)
```

---

### 6.4 Immutable Transaction Logs

**Decision:** Inventory transactions and audit logs are append-only.

**Rationale:**
1. **Financial Integrity**: Stock movements fully traceable
2. **Security**: No tampering with audit trail
3. **Debugging**: Full history for incident analysis
4. **Compliance**: Regulatory retention requirements

**Implementation:**
- Separate `InventoryTransactions` table
- `quantityBefore` / `quantityAfter` snapshots
- No UPDATE/DELETE at DAO level

---

### 6.5 Database-Authoritative Queue

**Decision:** Queue state stored in database, not UI state.

**Rationale:**
1. **Consistency**: Multiple clients see same state
2. **Real-time**: Drift streams push updates
3. **Recovery**: Queue survives app restart
4. **Auditability**: Position changes tracked

**Implementation:**
- `QueueEntries` table with position + status
- `repositionQueue()` recalculates on changes
- `watchCurrentQueue()` provides live updates

---

### 6.6 JSON for Flexible Fields

**Decision:** Store `medications`, `attachments`, `extractedData` as JSON text.

**Rationale:**
1. **Schema Flexibility**: Avoid EAV table explosion
2. **Performance**: Single column read vs. joins
3. **Type Safety**: Dart serialization at application layer
4. **Evolution**: Add fields without migration

**Trade-off:** Cannot query inside JSON (acceptable for these use cases).

---

### 6.7 Soft Deletion Pattern

**Decision:** Use `isActive` flag instead of hard delete for Users/Pets.

**Rationale:**
1. **Referential Integrity**: No orphaned records
2. **Historical Preservation**: Medical history retained
3. **Recovery**: Accidental deletion reversible
4. **Audit**: Deletion reason tracked

**Implementation:**
- `isActive` column (default true)
- Queries filter `WHERE isActive = 1`
- Deactivation via UPDATE (not DELETE)

---

### 6.8 Foreign Key Enforcement

**Decision:** Enable `PRAGMA foreign_keys = ON` in migrations.

**Rationale:**
1. **Data Integrity**: No orphaned references
2. **Cascade Control**: Explicit ON DELETE behavior
3. **Validation**: Database-level constraint (not just app)
4. **Debugging**: Clear error on violation

**Implementation:**
```dart
MigrationStrategy(
  onCreate: (m) async {
    await m.createAll();
    await customStatement('PRAGMA foreign_keys = ON');
  },
  beforeOpen: (details) async {
    await customStatement('PRAGMA foreign_keys = ON');
  },
);
```

---

## 7. Migration Strategy

### 7.1 Current State

- **Schema Version**: 1
- **Status**: Initial schema (no migrations yet)

### 7.2 Migration Hooks

```dart
@override
MigrationStrategy get migration {
  return MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await customStatement('PRAGMA foreign_keys = ON');
    },
    onUpgrade: (Migrator m, int from, int to) async {
      // Future migrations added here
      // Example:
      // if (from < 2) {
      //   await m.addColumn(users, users.deletedAt);
      // }
    },
    beforeOpen: (OpeningDetails details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
```

### 7.3 Future Migration Example

```dart
// Version 2: Add soft-delete to users
onUpgrade: (m, from, to) async {
  if (from < 2) {
    await m.addColumn(users, users.deletedAt);
  }
  if (from < 3) {
    await m.createTable(clinics);
  }
}
```

### 7.4 Migration Best Practices

1. **Backward Compatible**: New columns nullable or defaulted
2. **Tested**: Run on sample data before production
3. **Reversible**: Document down-migration (manual if needed)
4. **Incremental**: One change per version
5. **Backup**: Automatic before migration (future work)

---

## 8. Data Integrity & Constraints

### 8.1 Database-Level Constraints

| Constraint Type | Example | Enforcement |
|-----------------|---------|-------------|
| PRIMARY KEY | `id` in all tables | Unique, NOT NULL, auto-increment |
| FOREIGN KEY | `petId` → Pets(id) | RESTRICT/SET NULL |
| UNIQUE | `email` in Users | No duplicates |
| NOT NULL | `name` in Pets | Required field |
| DEFAULT | `role = 'PET_OWNER'` | Automatic value |
| CHECK (implicit) | Length constraints | Enforced by column type |
| ENUM (string) | `status` in Appointments | Validated at app layer |

### 8.2 Application-Level Validations

| Validation | Location | Example |
|------------|----------|---------|
| Email format | `validators.dart` | Regex check |
| Password strength | `validators.dart` | Min length, complexity |
| Role permission | Repository layer | Owner can't access other's pets |
| Status transition | Appointment DAO | REQUESTED → CONFIRMED (not SKIPPED) |
| Quantity non-negative | Inventory DAO | `quantity >= 0` check |
| Date logic | Appointment DAO | `scheduledAt > now` for new |

### 8.3 Transaction Boundaries

**Inventory Stock Update:**
```
BEGIN TRANSACTION
  ├── Update InventoryBatch.quantity
  ├── Create InventoryTransaction (before/after snapshot)
  └── Update InventoryItem.currentStock
COMMIT
```

**Appointment Creation:**
```
BEGIN TRANSACTION
  ├── Insert Appointment
  ├── Create QueueEntry (if walk-in)
  └── Create Notification (confirmation)
COMMIT
```

**Medical Record Creation:**
```
BEGIN TRANSACTION
  ├── Insert MedicalRecord
  ├── Insert Vaccination (if applicable)
  ├── Insert Prescription (if applicable)
  ├── Create InventoryTransaction (if dispensing)
  └── Create AuditLog
COMMIT
```

---

## 9. Performance Considerations

### 9.1 Index Strategy

**Indexes created for:**
1. All foreign keys (automatic + explicit)
2. Frequently filtered columns (status, type, date)
3. Common composite queries (reference_type + reference_id)

**Index Count:** 35 indexes across 13 tables

### 9.2 Query Optimization

| Technique | Example | Benefit |
|-----------|---------|---------|
| Join queries | `getWithDetails()` | Eliminates N+1 |
| Stream queries | `watchByPet()` | Real-time without polling |
| Limit clauses | `getRecent(limit: 20)` | Bounded result sets |
| Prepared statements | Drift generated | SQL injection safe |
| Batch operations | `transaction()` | Atomic multi-row updates |

### 9.3 Storage Efficiency

| Strategy | Implementation | Savings |
|----------|----------------|---------|
| Image paths (not BLOBs) | `ScanRecords.imagePath` | DB size minimal |
| JSON for flexible data | `medications`, `attachments` | No EAV tables |
| Nullable columns | Optional fields | Space efficient |
| Timestamp defaults | `CURRENT_TIMESTAMP` | No app overhead |

---

## 10. Security Implications

### 10.1 Data Protection

| Measure | Implementation |
|---------|----------------|
| Password hashing | `passwordHash` column (bcrypt/argon2 at app layer) |
| Encryption at rest | Device-level (future: SQLCipher) |
| Audit trail | `AuditLogs` table (immutable) |
| Access control | Role-based queries (DAO filters by userId) |
| OCR safety | `ScanRecords.status = PENDING` (human verification) |
| Privacy | Notifications avoid sensitive data |

### 10.2 Sensitive Operations Logged

| Operation | Audit Action |
|-----------|--------------|
| Login | `LOGIN` |
| Logout | `LOGOUT` |
| User creation | `CREATE_USER` |
| Role change | `CHANGE_ROLE` |
| Medical record | `CREATE_RECORD` |
| Inventory adjustment | `ADJUST_STOCK` |
| Prescription | `CREATE_PRESCRIPTION` |
| Scan confirmation | `CONFIRM_SCAN` |

---

## 11. Testing Strategy

### 11.1 Unit Tests (DAO Level)

```dart
group('InventoryDao', () {
  test('consumeFromBatches uses FIFO order', () async {
    // Insert 2 batches (different expiry)
    // Consume quantity
    // Verify earliest-expiry batch reduced first
  });
  
  test('adjustStock is atomic', () async {
    // Start transaction
    // Simulate failure
    // Verify rollback
  });
});
```

### 11.2 Integration Tests

```dart
group('Appointment Flow', () {
  test('create → check-in → complete', () async {
    final appt = await appointmentsDao.create(...);
    await appointmentsDao.checkIn(appt);
    await appointmentsDao.complete(appt);
    final result = await appointmentsDao.getById(appt);
    expect(result.status, 'COMPLETED');
  });
});
```

### 11.3 Migration Tests

```dart
test('migration v1 → v2 preserves data', () async {
  // Insert data in v1
  // Run migration to v2
  // Verify data intact
});
```

---

## 12. Conclusion

The CarePaw database design demonstrates:

1. **Local-first architecture** suitable for clinic environments
2. **Strong data integrity** via constraints and transactions
3. **Auditability** through immutable logs
4. **Performance** via strategic indexing and streaming
5. **Security** via role-based access and OCR verification
6. **Extensibility** via JSON columns and enum patterns
7. **Thesis-value** through clear, documented design decisions

The schema supports all 10 core modules (Authentication, Pets, Appointments, Queue, Medical Records, Vaccinations, Inventory, Scanning, Notifications, Audit) with room for future expansion (multi-clinic sync, cloud backup, analytics).

---

**Document Version:** 1.0  
**Last Updated:** August 19, 2026  
**Schema Version:** 1  
**Status:** Complete (Phase 2)
