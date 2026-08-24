import 'package:drift/drift.dart';

/// Users table - Pet owners, veterinarians, staff, admins
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get email => text().withLength(min: 3, max: 254).unique()();
  TextColumn get passwordHash => text()();
  TextColumn get fullName => text().withLength(min: 1, max: 100)();
  TextColumn get phone => text().nullable().withLength(min: 5, max: 15)();

  // Role enum stored as string
  TextColumn get role =>
      text().withDefault(const Constant('PET_OWNER'))(); // PET_OWNER, VETERINARIAN, STAFF, ADMIN

  TextColumn get avatarUrl => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Pets table - Patient records
class Pets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get ownerId => integer().references(Users, #id)();

  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get species =>
      text().withDefault(const Constant('DOG'))(); // DOG, CAT, BIRD, RABBIT, REPTILE, OTHER
  TextColumn get breed => text().nullable().withLength(min: 1, max: 50)();
  DateTimeColumn get birthDate => dateTime().nullable()();
  RealColumn get weightKg => real().nullable()();
  TextColumn get color => text().nullable().withLength(min: 1, max: 30)();
  TextColumn get microchipId => text().nullable().withLength(min: 1, max: 20)();
  TextColumn get avatarUrl => text().nullable()();

  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  // Index for owner lookups
  List<Index> get indexes => [
        Index('idx_pets_owner_id', 'owner_id'),
      ];
}

/// Appointments table - Scheduling
class Appointments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get petId => integer().references(Pets, #id)();
  IntColumn get veterinarianId => integer().references(Users, #id)();

  DateTimeColumn get scheduledAt => dateTime()();
  IntColumn get durationMinutes => integer().withDefault(const Constant(30))();

  // Status enum
  TextColumn get status =>
      text().withDefault(const Constant('REQUESTED'))(); // REQUESTED, CONFIRMED, CHECKED_IN, IN_PROGRESS, COMPLETED, CANCELLED, NO_SHOW

  TextColumn get reason => text().nullable().withLength(min: 1, max: 200)();
  TextColumn get notes => text().nullable().withLength(min: 1, max: 2000)();

  DateTimeColumn get checkInAt => dateTime().nullable()();
  DateTimeColumn get startedAt => dateTime().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get cancelledAt => dateTime().nullable()();
  TextColumn get cancellationReason => text().nullable().withLength(min: 1, max: 200)();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  List<Index> get indexes => [
        Index('idx_appointments_pet_id', 'pet_id'),
        Index('idx_appointments_veterinarian_id', 'veterinarian_id'),
        Index('idx_appointments_scheduled_at', 'scheduled_at'),
        Index('idx_appointments_status', 'status'),
      ];
}

/// Medical Records table - Append-only health history
class MedicalRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get petId => integer().references(Pets, #id)();
  IntColumn get veterinarianId => integer().references(Users, #id)();
  IntColumn get appointmentId => integer().nullable().references(Appointments, #id)();

  // Record type enum
  TextColumn get recordType =>
      text().withDefault(const Constant('VISIT'))(); // VISIT, VACCINATION, SURGERY, LAB_RESULT, PRESCRIPTION, NOTE, ALLERGY

  TextColumn get title => text().withLength(min: 1, max: 100)();
  TextColumn get description => text().nullable().withLength(min: 1, max: 2000)();
  TextColumn get diagnosis => text().nullable().withLength(min: 1, max: 1000)();
  TextColumn get treatment => text().nullable().withLength(min: 1, max: 1000)();

  // Medications stored as JSON
  TextColumn get medications => text().nullable()();

  // Attachments stored as JSON
  TextColumn get attachments => text().nullable()();

  DateTimeColumn get recordedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  List<Index> get indexes => [
        Index('idx_medical_records_pet_id', 'pet_id'),
        Index('idx_medical_records_veterinarian_id', 'veterinarian_id'),
        Index('idx_medical_records_record_type', 'record_type'),
        Index('idx_medical_records_recorded_at', 'recorded_at'),
      ];
}

/// Vaccinations table - Specific tracking
class Vaccinations extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get petId => integer().references(Pets, #id)();
  IntColumn get veterinarianId => integer().references(Users, #id)();

  TextColumn get vaccineName => text().withLength(min: 1, max: 100)();
  TextColumn get manufacturer => text().nullable().withLength(min: 1, max: 100)();
  TextColumn get batchNumber => text().nullable().withLength(min: 1, max: 50)();

  DateTimeColumn get administeredAt => dateTime()();
  DateTimeColumn get nextDueAt => dateTime().nullable()();

  TextColumn get notes => text().nullable().withLength(min: 1, max: 500)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  List<Index> get indexes => [
        Index('idx_vaccinations_pet_id', 'pet_id'),
        Index('idx_vaccinations_next_due_at', 'next_due_at'),
      ];
}

/// Inventory table - Medicine/supplies stock
class InventoryItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();

  // Category enum
  TextColumn get category =>
      text().withDefault(const Constant('MEDICINE'))(); // MEDICINE, VACCINE, SUPPLY, EQUIPMENT, FOOD

  TextColumn get unit => text().withLength(min: 1, max: 20)();

  RealColumn get currentStock => real().withDefault(const Constant(0.0))();
  RealColumn get minStock => real().withDefault(const Constant(0.0))();
  RealColumn get maxStock => real().nullable()();

  RealColumn get unitCost => real().nullable()();
  TextColumn get supplier => text().nullable().withLength(min: 1, max: 100)();
  TextColumn get location => text().nullable().withLength(min: 1, max: 50)();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  List<Index> get indexes => [
        Index('idx_inventory_category', 'category'),
        Index('idx_inventory_current_stock', 'current_stock'),
      ];
}

/// Inventory Batches - Expiration tracking
class InventoryBatches extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get inventoryId => integer().references(InventoryItems, #id)();

  TextColumn get batchNumber => text().withLength(min: 1, max: 50)();
  RealColumn get quantity => real()();
  DateTimeColumn get receivedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get expiresAt => dateTime().nullable()();

  RealColumn get costPerUnit => real().nullable()();
  TextColumn get supplier => text().nullable().withLength(min: 1, max: 100)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  List<Index> get indexes => [
        Index('idx_inventory_batches_inventory_id', 'inventory_id'),
        Index('idx_inventory_batches_expires_at', 'expires_at'),
      ];
}

/// Prescriptions table - Medication orders
class Prescriptions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get medicalRecordId => integer().references(MedicalRecords, #id)();
  IntColumn get petId => integer().references(Pets, #id)();

  TextColumn get medicationName => text().withLength(min: 1, max: 100)();
  TextColumn get dosage => text().withLength(min: 1, max: 50)();
  TextColumn get frequency => text().withLength(min: 1, max: 50)();
  IntColumn get durationDays => integer()();
  RealColumn get quantity => real()();
  IntColumn get refillsRemaining => integer().withDefault(const Constant(0))();

  TextColumn get instructions => text().nullable().withLength(min: 1, max: 500)();
  DateTimeColumn get prescribedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get expiresAt => dateTime().nullable()();

  // Status enum
  TextColumn get status =>
      text().withDefault(const Constant('ACTIVE'))(); // ACTIVE, COMPLETED, CANCELLED, EXPIRED

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  List<Index> get indexes => [
        Index('idx_prescriptions_pet_id', 'pet_id'),
        Index('idx_prescriptions_status', 'status'),
        Index('idx_prescriptions_expires_at', 'expires_at'),
      ];
}

/// Queue table - Real-time check-in
class QueueEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get appointmentId => integer().references(Appointments, #id)();

  IntColumn get position => integer()();

  // Status enum
  TextColumn get status =>
      text().withDefault(const Constant('WAITING'))(); // WAITING, CALLED, IN_ROOM, COMPLETED, SKIPPED

  DateTimeColumn get checkedInAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get calledAt => dateTime().nullable()();
  DateTimeColumn get roomEnteredAt => dateTime().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  TextColumn get room => text().nullable()();
  IntColumn get estimatedWaitMinutes => integer().nullable()();
  TextColumn get notes => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  List<Index> get indexes => [
        Index('idx_queue_appointment_id', 'appointment_id'),
        Index('idx_queue_status', 'status'),
        Index('idx_queue_position', 'position'),
        Index('idx_queue_room', 'room'),
      ];
}

/// Notifications table - User alerts
class Notifications extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();

  // Type enum
  TextColumn get type =>
      text().withDefault(const Constant('SYSTEM'))(); // APPOINTMENT_REMINDER, QUEUE_UPDATE, PRESCRIPTION_READY, INVENTORY_LOW, SYSTEM

  TextColumn get title => text().withLength(min: 1, max: 100)();
  TextColumn get message => text().withLength(min: 1, max: 500)();

  IntColumn get referenceId => integer().nullable()();
  TextColumn get referenceType => text().nullable().withLength(min: 1, max: 50)();

  BoolColumn get isRead => boolean().withDefault(const Constant(false))();
  DateTimeColumn get readAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  List<Index> get indexes => [
        Index('idx_notifications_user_id', 'user_id'),
        Index('idx_notifications_type', 'type'),
        Index('idx_notifications_is_read', 'is_read'),
      ];
}

/// Inventory Transactions table - Stock movement tracking
class InventoryTransactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get batchId => integer().references(InventoryBatches, #id)();

  // Transaction type enum
  TextColumn get type =>
      text().withDefault(const Constant('ADJUSTMENT'))(); // IN, OUT, ADJUSTMENT

  RealColumn get quantityChange => real()();
  RealColumn get quantityBefore => real()();
  RealColumn get quantityAfter => real()();

  TextColumn get reason => text().withLength(min: 1, max: 200)();
  TextColumn get referenceType => text().nullable().withLength(min: 1, max: 50)();
  IntColumn get referenceId => integer().nullable()();
  IntColumn get performedBy => integer().references(Users, #id)();
  TextColumn get notes => text().nullable().withLength(min: 1, max: 500)();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  List<Index> get indexes => [
        Index('idx_inventory_transactions_batch_id', 'batch_id'),
        Index('idx_inventory_transactions_reference', 'reference_type, reference_id'),
        Index('idx_inventory_transactions_created_at', 'created_at'),
      ];
}

/// Scan Records table - OCR scanning with human verification
class ScanRecords extends Table {
  IntColumn get id => integer().autoIncrement()();

  // Scan type enum
  TextColumn get scanType =>
      text().withDefault(const Constant('RECEIPT'))(); // RECEIPT, MEDICINE_BOX, PRESCRIPTION, LAB_RESULT

  TextColumn get imagePath => text().withLength(min: 1, max: 500)();
  TextColumn get rawOcrText => text().nullable()();
  TextColumn get extractedData => text().nullable()();
  RealColumn get confidenceScore => real().nullable()();

  // Status enum
  TextColumn get status =>
      text().withDefault(const Constant('PENDING'))(); // PENDING, CONFIRMED, REJECTED

  IntColumn get confirmedBy => integer().nullable().references(Users, #id)();
  DateTimeColumn get confirmedAt => dateTime().nullable()();
  TextColumn get corrections => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  List<Index> get indexes => [
        Index('idx_scan_records_type', 'scan_type'),
        Index('idx_scan_records_status', 'status'),
        Index('idx_scan_records_confirmed_by', 'confirmed_by'),
        Index('idx_scan_records_created_at', 'created_at'),
      ];
}

/// Audit Logs table - Security tracking
class AuditLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().nullable().references(Users, #id)();

  TextColumn get action => text().withLength(min: 1, max: 50)();
  TextColumn get entityType => text().withLength(min: 1, max: 50)();
  IntColumn get entityId => integer().nullable()();

  // JSON stored as text
  TextColumn get oldValues => text().nullable()();
  TextColumn get newValues => text().nullable()();

  TextColumn get ipAddress => text().nullable().withLength(min: 1, max: 45)();
  TextColumn get userAgent => text().nullable().withLength(min: 1, max: 200)();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  List<Index> get indexes => [
        Index('idx_audit_logs_user_id', 'user_id'),
        Index('idx_audit_logs_entity_type', 'entity_type'),
        Index('idx_audit_logs_created_at', 'created_at'),
      ];
}

/// Sync Metadata table - Tracks pending sync operations
class SyncMetadata extends Table {
  // Composite key: tableName:recordId:operation:timestamp
  TextColumn get id => text()();

  TextColumn get tableNameCol => text().withLength(min: 1, max: 50).named('table_name')();
  IntColumn get recordId => integer()();
  TextColumn get operation => text().withLength(min: 1, max: 10)(); // INSERT, UPDATE, DELETE
  TextColumn get payload => text().nullable()(); // JSON of changed fields
  IntColumn get version => integer().withDefault(const Constant(1))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get syncedAt => dateTime().nullable()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  TextColumn get deviceId => text().withLength(min: 1, max: 100)();

  @override
  Set<Column> get primaryKey => {id};

  List<Index> get indexes => [
        Index('idx_sync_table_record', 'table_name, recordId'),
        Index('idx_sync_unsynced', 'syncedAt'),
        Index('idx_sync_device', 'deviceId'),
        Index('idx_sync_created_at', 'createdAt'),
      ];
}

/// Notification Preferences table - User notification settings
class NotificationPreferences extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id).unique()();

  BoolColumn get appointmentReminders => boolean().withDefault(const Constant(true))();
  BoolColumn get queueUpdates => boolean().withDefault(const Constant(true))();
  BoolColumn get prescriptionReady => boolean().withDefault(const Constant(true))();
  BoolColumn get inventoryAlerts => boolean().withDefault(const Constant(true))();
  BoolColumn get systemAnnouncements => boolean().withDefault(const Constant(true))();

  BoolColumn get emailEnabled => boolean().withDefault(const Constant(true))();
  BoolColumn get pushEnabled => boolean().withDefault(const Constant(true))();
  BoolColumn get inAppEnabled => boolean().withDefault(const Constant(true))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Device Info table - One row per device installation
class DeviceInfo extends Table {
  TextColumn get id => text()(); // UUID generated on first run
  TextColumn get fcmToken => text().nullable()();
  TextColumn get firebaseUid => text().nullable()(); // If linked to Firebase Auth
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastSyncAt => dateTime().nullable()();
  TextColumn get platform => text().withLength(min: 1, max: 20)(); // android, ios, web, etc.
  TextColumn get appVersion => text().withLength(min: 1, max: 20)();

  @override
  Set<Column> get primaryKey => {id};
}
