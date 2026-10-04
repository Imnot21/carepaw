import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore collection names and data models.
///
/// Mirrors the Drift database schema for bidirectional sync.
/// Each collection corresponds to a Drift table.
class FirestoreSchema {
  FirestoreSchema._();

  // ============ Collection Names ============
  static const String users = 'users';
  static const String pets = 'pets';
  static const String appointments = 'appointments';
  static const String medicalRecords = 'medicalRecords';
  static const String vaccinations = 'vaccinations';
  static const String inventoryItems = 'inventoryItems';
  static const String inventoryBatches = 'inventoryBatches';
  static const String inventoryTransactions = 'inventoryTransactions';
  static const String prescriptions = 'prescriptions';
  static const String queueEntries = 'queueEntries';
  static const String notifications = 'notifications';
  static const String notificationPreferences = 'notificationPreferences';
  static const String scanRecords = 'scanRecords';
  static const String auditLogs = 'auditLogs';

  // Sync metadata collections
  static const String syncMetadata = 'syncMetadata';
  static const String deviceInfo = 'deviceInfo';
  static const String syncConflicts = 'syncConflicts';

  // ============ Field Names (consistent with Drift) ============
  // Common fields
  static const String id = 'id';
  static const String createdAt = 'createdAt';
  static const String updatedAt = 'updatedAt';
  static const String version = 'version';
  static const String deviceId = 'deviceId';

  // Users fields
  static const String email = 'email';
  static const String passwordHash = 'passwordHash';
  static const String fullName = 'fullName';
  static const String phone = 'phone';
  static const String role = 'role';
  static const String avatarUrl = 'avatarUrl';
  static const String isActive = 'isActive';

  // Pets fields
  static const String ownerId = 'ownerId';
  static const String name = 'name';
  static const String species = 'species';
  static const String breed = 'breed';
  static const String birthDate = 'birthDate';
  static const String weightKg = 'weightKg';
  static const String color = 'color';
  static const String microchipId = 'microchipId';

  // Appointments fields
  static const String petId = 'petId';
  static const String veterinarianId = 'veterinarianId';
  static const String scheduledAt = 'scheduledAt';
  static const String durationMinutes = 'durationMinutes';
  static const String status = 'status';
  static const String reason = 'reason';
  static const String notes = 'notes';
  static const String checkInAt = 'checkInAt';
  static const String startedAt = 'startedAt';
  static const String completedAt = 'completedAt';
  static const String cancelledAt = 'cancelledAt';
  static const String cancellationReason = 'cancellationReason';

  // Medical Records fields
  static const String recordType = 'recordType';
  static const String title = 'title';
  static const String description = 'description';
  static const String diagnosis = 'diagnosis';
  static const String treatment = 'treatment';
  static const String medications = 'medications';
  static const String attachments = 'attachments';
  static const String recordedAt = 'recordedAt';

  // Vaccinations fields
  static const String vaccineName = 'vaccineName';
  static const String manufacturer = 'manufacturer';
  static const String batchNumber = 'batchNumber';
  static const String administeredAt = 'administeredAt';
  static const String nextDueAt = 'nextDueAt';

  // Inventory Items fields
  static const String category = 'category';
  static const String unit = 'unit';
  static const String currentStock = 'currentStock';
  static const String minStock = 'minStock';
  static const String maxStock = 'maxStock';
  static const String unitCost = 'unitCost';
  static const String supplier = 'supplier';
  static const String location = 'location';

  // Inventory Batches fields
  static const String inventoryId = 'inventoryId';
  static const String batchNumberInv = 'batchNumber';
  static const String quantity = 'quantity';
  static const String receivedAt = 'receivedAt';
  static const String expiresAt = 'expiresAt';
  static const String costPerUnit = 'costPerUnit';

  // Inventory Transactions fields
  static const String batchId = 'batchId';
  static const String type = 'type';
  static const String quantityChange = 'quantityChange';
  static const String quantityBefore = 'quantityBefore';
  static const String quantityAfter = 'quantityAfter';
  static const String reasonInv = 'reason';
  static const String referenceType = 'referenceType';
  static const String referenceId = 'referenceId';
  static const String performedBy = 'performedBy';
  static const String notesInv = 'notes';

  // Prescriptions fields
  static const String medicalRecordId = 'medicalRecordId';
  static const String medicationName = 'medicationName';
  static const String dosage = 'dosage';
  static const String frequency = 'frequency';
  static const String durationDays = 'durationDays';
  static const String quantityPrescribed = 'quantity';
  static const String refillsRemaining = 'refillsRemaining';
  static const String instructions = 'instructions';
  static const String prescribedAt = 'prescribedAt';
  static const String expiresAtPresc = 'expiresAt';
  static const String statusPresc = 'status';

  // Queue Entries fields
  static const String appointmentId = 'appointmentId';
  static const String position = 'position';
  static const String priority = 'priority';
  static const String statusQueue = 'status';
  static const String checkedInAt = 'checkedInAt';
  static const String calledAt = 'calledAt';
  static const String roomEnteredAt = 'roomEnteredAt';
  static const String completedAtQueue = 'completedAt';
  static const String room = 'room';
  static const String estimatedWaitMinutes = 'estimatedWaitMinutes';
  static const String notesQueue = 'notes';

  // Notifications fields
  static const String userId = 'userId';
  static const String typeNotif = 'type';
  static const String titleNotif = 'title';
  static const String message = 'message';
  static const String referenceIdNotif = 'referenceId';
  static const String referenceTypeNotif = 'referenceType';
  static const String isRead = 'isRead';
  static const String readAt = 'readAt';

  // Scan Records fields
  static const String scanType = 'scanType';
  static const String imagePath = 'imagePath';
  static const String rawOcrText = 'rawOcrText';
  static const String extractedData = 'extractedData';
  static const String confidenceScore = 'confidenceScore';
  static const String statusScan = 'status';
  static const String confirmedBy = 'confirmedBy';
  static const String confirmedAt = 'confirmedAt';
  static const String corrections = 'corrections';

  // Audit Logs fields
  static const String userIdAudit = 'userId';
  static const String action = 'action';
  static const String entityType = 'entityType';
  static const String entityId = 'entityId';
  static const String oldValues = 'oldValues';
  static const String newValues = 'newValues';
  static const String ipAddress = 'ipAddress';
  static const String userAgent = 'userAgent';

  // Sync Metadata fields
  static const String tableName = 'tableName';
  static const String recordId = 'recordId';
  static const String operation = 'operation';
  static const String payload = 'payload';
  static const String syncedAt = 'syncedAt';
  static const String retryCount = 'retryCount';
  static const String lastError = 'lastError';

  // Device Info fields
  static const String fcmToken = 'fcmToken';
  static const String firebaseUid = 'firebaseUid';
  static const String platform = 'platform';
  static const String appVersion = 'appVersion';
  static const String lastSyncAt = 'lastSyncAt';

  // ============ Helper Methods ============

  /// Get collection reference for a table name.
  static CollectionReference<Map<String, dynamic>> collection(
    String tableName,
  ) {
    return FirebaseFirestore.instance.collection(tableName);
  }

  /// Get document reference for a table and ID.
  static DocumentReference<Map<String, dynamic>> doc(
    String tableName,
    String docId,
  ) {
    return FirebaseFirestore.instance.collection(tableName).doc(docId);
  }

  /// Convert Drift table name to Firestore collection name.
  static String tableToCollection(String tableName) {
    // Drift uses snake_case, Firestore uses camelCase
    switch (tableName) {
      case 'users':
        return users;
      case 'pets':
        return pets;
      case 'appointments':
        return appointments;
      case 'medical_records':
        return medicalRecords;
      case 'vaccinations':
        return vaccinations;
      case 'inventory_items':
        return inventoryItems;
      case 'inventory_batches':
        return inventoryBatches;
      case 'inventory_transactions':
        return inventoryTransactions;
      case 'prescriptions':
        return prescriptions;
      case 'queue_entries':
        return queueEntries;
      case 'notifications':
        return notifications;
      case 'scan_records':
        return scanRecords;
      case 'audit_logs':
        return auditLogs;
      default:
        return tableName; // fallback
    }
  }

  /// Convert Firestore collection name to Drift table name.
  static String collectionToTable(String collection) {
    switch (collection) {
      case users:
        return 'users';
      case pets:
        return 'pets';
      case appointments:
        return 'appointments';
      case medicalRecords:
        return 'medical_records';
      case vaccinations:
        return 'vaccinations';
      case inventoryItems:
        return 'inventory_items';
      case inventoryBatches:
        return 'inventory_batches';
      case inventoryTransactions:
        return 'inventory_transactions';
      case prescriptions:
        return 'prescriptions';
      case queueEntries:
        return 'queue_entries';
      case notifications:
        return 'notifications';
      case scanRecords:
        return 'scan_records';
      case auditLogs:
        return 'audit_logs';
      default:
        return collection; // fallback
    }
  }

  /// Get all collections that should be synced.
  static List<String> get syncableCollections => [
    users,
    pets,
    appointments,
    medicalRecords,
    vaccinations,
    inventoryItems,
    inventoryBatches,
    inventoryTransactions,
    prescriptions,
    queueEntries,
    notifications,
    scanRecords,
    auditLogs,
  ];

  /// Get collections that require manual conflict resolution.
  static List<String> get manualConflictCollections => [
    users,
    medicalRecords,
    scanRecords,
  ];
}
