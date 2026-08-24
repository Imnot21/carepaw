# CarePaw — API / Data Access Contracts

This document describes the repository interfaces and data access contracts
used by CarePaw features. The "API" here refers to the **internal contract
between the domain layer and data layer** (repository interfaces), not a
remote HTTP API. The remote API layer (if added) will follow the same
contracts.

---

## 1. Repository Pattern

All data access goes through **repository interfaces** defined in each
feature's `domain/` folder. Implementations live in `data/`.

```dart
// Domain layer (contract)
abstract class PetRepository {
  Future<Pet?> findById(int id);
  Future<List<Pet>> findByOwner(int ownerId);
  Future<Pet> save(Pet pet);
  Future<void> delete(int id);
  Stream<Pet?> watchById(int id);
  Future<PaginatedResult<Pet>> findPaginated(PaginationParams params);
}

// Data layer (implementation)
class PetRepositoryImpl implements PetRepository {
  final CarePawDatabase _db;
  PetRepositoryImpl(this._db);
  // ... uses PetDao
}
```

---

## 2. Common Base Contracts

### 2.1 `BaseRepository<T, ID>` (`core/repositories/base_repository.dart`)

```dart
abstract class BaseRepository<T, ID> {
  Future<T?> findById(ID id);
  Future<List<T>> findAll();
  Future<T> save(T entity);
  Future<void> delete(ID id);
  Future<bool> exists(ID id);
}
```

### 2.2 `SoftDeleteRepository<T, ID>`

```dart
abstract class SoftDeleteRepository<T, ID> implements BaseRepository<T, ID> {
  Future<void> softDelete(ID id);
  Future<void> restore(ID id);
  Future<List<T>> findAllIncludingDeleted();
}
```

### 2.3 `StreamRepository<T, ID>`

```dart
abstract class StreamRepository<T, ID> implements BaseRepository<T, ID> {
  Stream<T?> watchById(ID id);
  Stream<List<T>> watchAll();
}
```

### 2.4 `PaginatedRepository<T, ID>`

```dart
abstract class PaginatedRepository<T, ID> implements BaseRepository<T, ID> {
  Future<PaginatedResult<T>> findPaginated(PaginationParams params);
}
```

### 2.5 Pagination Helpers

```dart
class PaginationParams {
  final int page;          // 1-based
  final int pageSize;      // default 20
  final String? orderBy;
  final bool ascending;    // default true

  const PaginationParams({
    this.page = 1,
    this.pageSize = 20,
    this.orderBy,
    this.ascending = true,
  });

  int get offset => (page - 1) * pageSize;
}

class PaginatedResult<T> {
  final List<T> items;
  final int totalCount;
  final int page;
  final int pageSize;
  final int totalPages;

  PaginatedResult({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  }) : totalPages = (totalCount / pageSize).ceil();

  bool get hasNextPage => page < totalPages;
  bool get hasPreviousPage => page > 1;
}
```

---

## 3. Feature Repository Contracts

### 3.1 Authentication / Users

**Entity:** `User` (`features/authentication/domain/entities/user.dart`)

```dart
enum UserRole { petOwner, veterinarian, staff, admin }

class User extends Equatable {
  final int? id;
  final String email;
  final String fullName;
  final String? phone;
  final UserRole role;
  final String? avatarUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  // ... copyWith, getters (isVeterinarian, isStaff, isAdmin, isPetOwner)
}

class AuthResult {
  final User user;
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
}
```

**Repository:** `features/users/domain/repositories/user_repository.dart`

```dart
abstract class UserRepository extends BaseRepository<User, int> {
  Future<User?> findByEmail(String email);
  Future<User?> findById(int id);
  Future<User> save(User user);
  Future<void> updateRole(int userId, UserRole role);
  Future<void> deactivate(int userId);
  Future<PaginatedResult<User>> findPaginated(PaginationParams params);
  Stream<User?> watchById(int id);
}
```

---

### 3.2 Pets

**Entity:** `Pet` (`features/pets/domain/entities/pet.dart`)

```dart
enum PetSpecies { dog, cat, bird, rabbit, reptile, other }

class Pet extends Equatable {
  final int? id;
  final int ownerId;
  final String name;
  final PetSpecies species;
  final String? breed;
  final DateTime? birthDate;
  final double? weightKg;
  final String? color;
  final String? microchipId;
  final String? avatarUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  // ageInYears getter, copyWith
}
```

**Repository:** `features/pets/domain/repositories/pet_repository.dart`

```dart
abstract class PetRepository
    implements SoftDeleteRepository<Pet, int>, StreamRepository<Pet, int>,
               PaginatedRepository<Pet, int> {
  Future<List<Pet>> findByOwner(int ownerId);
  Future<Pet?> findById(int id);
  Future<Pet> save(Pet pet);
  Future<void> softDelete(int id);
  Future<void> restore(int id);
  Future<PaginatedResult<Pet>> findPaginated(PaginationParams params);
  Stream<Pet?> watchById(int id);
  Stream<List<Pet>> watchByOwner(int ownerId);
}
```

---

### 3.3 Appointments

**Entity:** `Appointment` (`features/appointments/domain/entities/appointment.dart`)

```dart
enum AppointmentStatus {
  requested,
  confirmed,
  checkedIn,
  inProgress,
  completed,
  cancelled,
  noShow
}

class Appointment extends Equatable {
  final int? id;
  final int petId;
  final int veterinarianId;
  final DateTime scheduledAt;
  final int durationMinutes;
  final AppointmentStatus status;
  final String? reason;
  final String? notes;
  final DateTime? checkInAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final DateTime createdAt;
  final DateTime updatedAt;
  // ... copyWith
}
```

**Repository:** `features/appointments/domain/repositories/appointment_repository.dart`

```dart
abstract class AppointmentRepository
    implements BaseRepository<Appointment, int>,
               StreamRepository<Appointment, int>,
               PaginatedRepository<Appointment, int> {
  Future<List<Appointment>> findByPet(int petId, {AppointmentStatus? status});
  Future<List<Appointment>> findByVeterinarian(
    int veterinarianId,
    DateTime from,
    DateTime to,
  );
  Future<List<Appointment>> findByDateRange(DateTime from, DateTime to);
  Future<Appointment?> findById(int id);
  Future<Appointment> save(Appointment appointment);

  /// Validates and performs a status transition
  Future<void> transitionStatus(
    int appointmentId,
    AppointmentStatus newStatus, {
    String? reason,
  });

  Future<PaginatedResult<Appointment>> findPaginated(PaginationParams params);
  Stream<Appointment?> watchById(int id);
  Stream<List<Appointment>> watchByPet(int petId);
  Stream<List<Appointment>> watchByVeterinarian(int veterinarianId, DateTime from, DateTime to);
}
```

**Valid Status Transitions:**
```
REQUESTED → CONFIRMED, CANCELLED
CONFIRMED → CHECKED_IN, CANCELLED
CHECKED_IN → IN_PROGRESS, CANCELLED
IN_PROGRESS → COMPLETED
CONFIRMED/CHECKED_IN/IN_PROGRESS → NO_SHOW (after scheduled time)
* → CANCELLED (with reason)
```

---

### 3.4 Queue

**Entity:** `QueueEntry` (`features/queue/domain/entities/queue_entry.dart`)

```dart
enum QueueStatus { waiting, called, inRoom, completed, skipped }

class QueueEntry extends Equatable {
  final int? id;
  final int appointmentId;
  final int position;
  final QueueStatus status;
  final DateTime checkedInAt;
  final DateTime? calledAt;
  final DateTime? roomEnteredAt;
  final DateTime? completedAt;
  final String? room;
  final int? estimatedWaitMinutes;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;
}
```

**Repository:** `features/queue/domain/repositories/queue_repository.dart`

```dart
abstract class QueueRepository
    implements BaseRepository<QueueEntry, int>,
               StreamRepository<QueueEntry, int>,
               PaginatedRepository<QueueEntry, int> {
  Future<QueueEntry?> findByAppointment(int appointmentId);
  Future<QueueEntry?> findById(int id);
  Future<List<QueueEntry>> getWaitingQueue();
  Future<List<QueueEntry>> getQueueForRoom(String room);
  Future<QueueEntry> checkIn(int appointmentId);
  Future<void> callNext(int queueId, String room);
  Future<void> enterRoom(int queueId);
  Future<void> complete(int queueId);
  Future<void> skip(int queueId, String reason);
  Future<void> reorder(List<int> queueIdsInOrder);
  Future<PaginatedResult<QueueEntry>> findPaginated(PaginationParams params);
  Stream<QueueEntry?> watchByAppointment(int appointmentId);
  Stream<List<QueueEntry>> watchQueue();
}
```

---

### 3.5 Medical Records

**Entities:**
- `MedicalRecord` (`features/medical_records/domain/entities/medical_record.dart`)
- `Vaccination` (`features/medical_records/domain/entities/vaccination.dart`)

```dart
enum MedicalRecordType {
  visit, vaccination, surgery, labResult, prescription, note, allergy
}

class MedicalRecord extends Equatable {
  final int? id;
  final int petId;
  final int veterinarianId;
  final int? appointmentId;
  final MedicalRecordType recordType;
  final String title;
  final String? description;
  final String? diagnosis;
  final String? treatment;
  final String? medicationsJson;   // List<Map> serialized
  final String? attachmentsJson;   // List<Map> serialized
  final DateTime recordedAt;
  final DateTime createdAt;
}

class Vaccination extends Equatable {
  final int? id;
  final int petId;
  final int veterinarianId;
  final String vaccineName;
  final String? manufacturer;
  final String? batchNumber;
  final DateTime administeredAt;
  final DateTime? nextDueAt;
  final String? notes;
  final DateTime createdAt;
}
```

**Repositories:**

```dart
// MedicalRecordRepository
abstract class MedicalRecordRepository
    implements StreamRepository<MedicalRecord, int>,
               PaginatedRepository<MedicalRecord, int> {
  Future<List<MedicalRecord>> findByPet(int petId);
  Future<List<MedicalRecord>> findByVeterinarian(int vetId);
  Future<List<MedicalRecord>> findByType(int petId, MedicalRecordType type);
  Future<MedicalRecord?> findById(int id);
  Future<MedicalRecord> save(MedicalRecord record);
  // No delete — append only
  Future<PaginatedResult<MedicalRecord>> findPaginated(PaginationParams params);
  Stream<MedicalRecord?> watchById(int id);
  Stream<List<MedicalRecord>> watchByPet(int petId);
}

// VaccinationRepository
abstract class VaccinationRepository
    implements BaseRepository<Vaccination, int>,
               PaginatedRepository<Vaccination, int> {
  Future<List<Vaccination>> findByPet(int petId);
  Future<List<Vaccination>> findDue(DateTime before);
  Future<Vaccination?> findById(int id);
  Future<Vaccination> save(Vaccination vaccination);
  Future<PaginatedResult<Vaccination>> findPaginated(PaginationParams params);
  Stream<List<Vaccination>> watchByPet(int petId);
}
```

---

### 3.6 Inventory

**Entities:** `InventoryItem`, `InventoryBatch`, `InventoryTransaction`
(`features/inventory/domain/entities/inventory.dart`)

```dart
enum InventoryCategory { medicine, vaccine, supply, equipment, food }

class InventoryItem extends Equatable {
  final int? id;
  final String name;
  final InventoryCategory category;
  final String unit;
  final double currentStock;
  final double minStock;
  final double? maxStock;
  final double? unitCost;
  final String? supplier;
  final String? location;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class InventoryBatch extends Equatable {
  final int? id;
  final int inventoryId;
  final String batchNumber;
  final double quantity;
  final DateTime receivedAt;
  final DateTime? expiresAt;
  final double? costPerUnit;
  final String? supplier;
  final DateTime createdAt;
}

enum InventoryTransactionType { in_, out, adjustment }

class InventoryTransaction extends Equatable {
  final int? id;
  final int batchId;
  final InventoryTransactionType type;
  final double quantityChange;
  final double quantityBefore;
  final double quantityAfter;
  final String reason;
  final String? referenceType;
  final int? referenceId;
  final int performedBy;
  final String? notes;
  final DateTime createdAt;
}
```

**Repositories:**

```dart
// InventoryItemRepository
abstract class InventoryItemRepository
    implements PaginatedRepository<InventoryItem, int> {
  Future<List<InventoryItem>> findByCategory(InventoryCategory category);
  Future<List<InventoryItem>> findLowStock();
  Future<InventoryItem?> findById(int id);
  Future<InventoryItem> save(InventoryItem item);
  Future<PaginatedResult<InventoryItem>> findPaginated(PaginationParams params);
  Stream<InventoryItem?> watchById(int id);
}

// InventoryBatchRepository
abstract class InventoryBatchRepository
    implements BaseRepository<InventoryBatch, int>,
               PaginatedRepository<InventoryBatch, int> {
  Future<List<InventoryBatch>> findByItem(int inventoryId);
  Future<List<InventoryBatch>> findExpiring(DateTime before);
  Future<InventoryBatch?> findById(int id);
  Future<InventoryBatch> save(InventoryBatch batch);
  Future<PaginatedResult<InventoryBatch>> findPaginated(PaginationParams params);
  Stream<List<InventoryBatch>> watchByItem(int inventoryId);
}

// InventoryTransactionRepository
abstract class InventoryTransactionRepository
    implements BaseRepository<InventoryTransaction, int>,
               PaginatedRepository<InventoryTransaction, int> {
  Future<List<InventoryTransaction>> findByBatch(int batchId);
  Future<List<InventoryTransaction>> findByReference(
    String referenceType,
    int referenceId,
  );
  Future<InventoryTransaction> record(
    InventoryTransaction transaction,
  ); // wraps transaction logic
  Future<PaginatedResult<InventoryTransaction>> findPaginated(PaginationParams params);
  Stream<List<InventoryTransaction>> watchByBatch(int batchId);
}
```

---

### 3.7 Scanning / OCR

**Entity:** `ScanRecord` (`features/scanning/domain/entities/scan_record.dart`)

```dart
enum ScanType { receipt, medicineBox, prescription, labResult }
enum ScanStatus { pending, confirmed, rejected }

class ScanRecord extends Equatable {
  final int? id;
  final ScanType scanType;
  final String imagePath;
  final String? rawOcrText;
  final String? extractedData;      // JSON of extracted fields
  final double? confidenceScore;
  final ScanStatus status;
  final int? confirmedBy;
  final DateTime? confirmedAt;
  final String? corrections;        // JSON of user corrections
  final DateTime createdAt;
}
```

**Repository:** `features/scanning/domain/repositories/scan_repository.dart`

```dart
abstract class ScanRepository
    implements BaseRepository<ScanRecord, int>,
               PaginatedRepository<ScanRecord, int> {
  Future<ScanRecord?> findById(int id);
  Future<List<ScanRecord>> findByType(ScanType type);
  Future<List<ScanRecord>> findPending();
  Future<ScanRecord> save(ScanRecord record);
  Future<void> confirm(int id, int confirmedBy, String? corrections);
  Future<void> reject(int id, int confirmedBy, String reason);
  Future<PaginatedResult<ScanRecord>> findPaginated(PaginationParams params);
  Stream<ScanRecord?> watchById(int id);
  Stream<List<ScanRecord>> watchPending();
}
```

---

### 3.8 Notifications

**Entity:** `Notification` (`features/notifications/domain/entities/notification.dart`)

```dart
enum NotificationType {
  appointmentReminder,
  queueUpdate,
  prescriptionReady,
  inventoryLow,
  system
}

class Notification extends Equatable {
  final int? id;
  final int userId;
  final NotificationType type;
  final String title;
  final String message;
  final int? referenceId;
  final String? referenceType;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;
}
```

**Repository:** `features/notifications/domain/repositories/notification_repository.dart`

```dart
abstract class NotificationRepository
    implements BaseRepository<Notification, int>,
               PaginatedRepository<Notification, int> {
  Future<List<Notification>> findByUser(int userId, {bool? unreadOnly});
  Future<Notification?> findById(int id);
  Future<Notification> save(Notification notification);
  Future<void> markRead(int id);
  Future<void> markAllRead(int userId);
  Future<int> unreadCount(int userId);
  Future<PaginatedResult<Notification>> findPaginated(PaginationParams params);
  Stream<Notification?> watchById(int id);
  Stream<List<Notification>> watchByUser(int userId);
}
```

---

## 4. Error Contracts

All repositories throw or return `Failure` types from `core/errors/failures.dart`.
See [FAILURES.md](FAILURES.md) for the full hierarchy.

**Key Domain-Specific Failures:**

| Failure | When |
|---------|------|
| `AppointmentConflictFailure` | Overlapping appointment for same pet/vet |
| `InvalidStatusTransitionFailure` | Illegal appointment/queue status change |
| `InsufficientStockFailure` | Stock OUT > available |
| `MedicineExpiredFailure` | Attempt to use expired batch |
| `OcrProcessingFailure` | OCR engine error |
| `LowConfidenceOcrFailure` | Confidence below threshold |
| `InvalidScanResultFailure` | Extracted data missing required fields |
| `NotFoundFailure` | Entity not found |
| `AlreadyExistsFailure` | Duplicate email, pet name for owner, etc. |
| `UnauthorizedFailure` | Role check failed |

---

## 5. Future Remote API Contract (Planned)

If/when a backend is introduced, the repository implementations will swap
from local Drift to HTTP while keeping the same interfaces. The contract
will map to:

| Feature | REST-ish Endpoints |
|---------|-------------------|
| Auth | `POST /auth/login`, `POST /auth/register`, `POST /auth/refresh` |
| Users | `GET /users/:id`, `PATCH /users/:id`, `GET /users` |
| Pets | `GET /pets?owner=:id`, `POST /pets`, `PATCH /pets/:id` |
| Appointments | `GET /appointments?pet=:id`, `POST /appointments`, `PATCH /appointments/:id/status` |
| Queue | `GET /queue/waiting`, `POST /queue/check-in`, `POST /queue/:id/call`, `POST /queue/:id/complete` |
| Medical Records | `GET /medical-records?pet=:id`, `POST /medical-records` |
| Vaccinations | `GET /vaccinations?pet=:id`, `POST /vaccinations` |
| Inventory | `GET /inventory`, `GET /inventory/:id/batches`, `POST /inventory/:id/batches`, `POST /inventory/transactions` |
| Scanning | `POST /scans`, `PATCH /scans/:id/confirm`, `PATCH /scans/:id/reject` |
| Notifications | `GET /notifications?user=:id`, `PATCH /notifications/:id/read` |

Response envelope:
```json
{
  "data": {},
  "meta": { "page": 1, "pageSize": 20, "total": 100 }
}
```

Error envelope:
```json
{
  "error": { "code": "INVALID_CREDENTIALS", "message": "Invalid email or password." }
}
```

---

## 6. Testing Contracts

Each repository interface should have:
1. **Contract tests** — verify all implementations satisfy the interface.
2. **Fake/InMemory implementation** — for unit testing BLoCs without a DB.
3. **Drift implementation tests** — integration tests against a real SQLite.

See `docs/DEVELOPMENT.md` for testing workflow.