import 'package:carepaw/core/database/database.dart' as db;

/// Generic JSON serialization helpers
class JsonHelpers {
  /// Safely parse a DateTime from various formats
  static DateTime? parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    // Timestamp is not available in this context, use DateTime instead
    return null;
  }

  /// Safely parse a double from various formats
  static double? parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Safely parse an int from various formats
  static int? parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// Safely parse a bool from various formats
  static bool? parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    if (value is int) return value != 0;
    return null;
  }

  /// Non-nullable int parser with default
  static int intFrom(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  /// Non-nullable double parser with default
  static double doubleFrom(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  /// Non-nullable string parser with default
  static String stringFrom(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  /// Non-nullable bool parser with default
  static bool boolFrom(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) return value.toLowerCase() == 'true';
    return false;
  }

  /// Non-nullable DateTime parser with default
  static DateTime dateTimeFrom(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  /// Nullable DateTime parser
  static DateTime? nullableDateTimeFrom(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  /// Nullable string parser
  static String? nullableStringFrom(dynamic value) {
    if (value == null) return null;
    return value.toString();
  }

  /// Nullable int parser
  static int? nullableIntFrom(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString());
  }

  /// Nullable double parser
  static double? nullableDoubleFrom(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString());
  }
}

/// Extension methods for Drift data classes (used by sync infrastructure)
/// These provide toJson/fromJson for Firestore sync directly on Drift table rows

extension UserJsonSync on db.User {
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'passwordHash': passwordHash,
      'fullName': fullName,
      'phone': phone,
      'role': role,
      'avatarUrl': avatarUrl,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static db.User fromJson(Map<String, dynamic> json) {
    return db.User(
      id: JsonHelpers.intFrom(json['id']),
      email: JsonHelpers.stringFrom(json['email']),
      passwordHash: JsonHelpers.stringFrom(json['passwordHash']),
      fullName: JsonHelpers.stringFrom(json['fullName']),
      phone: JsonHelpers.nullableStringFrom(json['phone']),
      role: JsonHelpers.stringFrom(json['role']),
      avatarUrl: JsonHelpers.nullableStringFrom(json['avatarUrl']),
      isActive: JsonHelpers.boolFrom(json['isActive']),
      createdAt: JsonHelpers.dateTimeFrom(json['createdAt']),
      updatedAt: JsonHelpers.dateTimeFrom(json['updatedAt']),
    );
  }
}

extension PetJsonSync on db.Pet {
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerId': ownerId,
      'name': name,
      'species': species,
      'breed': breed,
      'birthDate': birthDate?.toIso8601String(),
      'weightKg': weightKg,
      'color': color,
      'microchipId': microchipId,
      'avatarUrl': avatarUrl,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static db.Pet fromJson(Map<String, dynamic> json) {
    return db.Pet(
      id: JsonHelpers.intFrom(json['id']),
      ownerId: JsonHelpers.intFrom(json['ownerId']),
      name: JsonHelpers.stringFrom(json['name']),
      species: JsonHelpers.stringFrom(json['species']),
      breed: JsonHelpers.nullableStringFrom(json['breed']),
      birthDate: JsonHelpers.nullableDateTimeFrom(json['birthDate']),
      weightKg: JsonHelpers.nullableDoubleFrom(json['weightKg']),
      color: JsonHelpers.nullableStringFrom(json['color']),
      microchipId: JsonHelpers.nullableStringFrom(json['microchipId']),
      avatarUrl: JsonHelpers.nullableStringFrom(json['avatarUrl']),
      isActive: JsonHelpers.boolFrom(json['isActive']),
      createdAt: JsonHelpers.dateTimeFrom(json['createdAt']),
      updatedAt: JsonHelpers.dateTimeFrom(json['updatedAt']),
    );
  }
}

extension AppointmentJsonSync on db.Appointment {
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'petId': petId,
      'veterinarianId': veterinarianId,
      'scheduledAt': scheduledAt.toIso8601String(),
      'durationMinutes': durationMinutes,
      'status': status,
      'reason': reason,
      'notes': notes,
      'checkInAt': checkInAt?.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'cancelledAt': cancelledAt?.toIso8601String(),
      'cancellationReason': cancellationReason,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static db.Appointment fromJson(Map<String, dynamic> json) {
    return db.Appointment(
      id: JsonHelpers.intFrom(json['id']),
      petId: JsonHelpers.intFrom(json['petId']),
      veterinarianId: JsonHelpers.intFrom(json['veterinarianId']),
      scheduledAt: JsonHelpers.dateTimeFrom(json['scheduledAt']),
      durationMinutes: JsonHelpers.intFrom(json['durationMinutes']),
      status: JsonHelpers.stringFrom(json['status']),
      reason: JsonHelpers.nullableStringFrom(json['reason']),
      notes: JsonHelpers.nullableStringFrom(json['notes']),
      checkInAt: JsonHelpers.nullableDateTimeFrom(json['checkInAt']),
      startedAt: JsonHelpers.nullableDateTimeFrom(json['startedAt']),
      completedAt: JsonHelpers.nullableDateTimeFrom(json['completedAt']),
      cancelledAt: JsonHelpers.nullableDateTimeFrom(json['cancelledAt']),
      cancellationReason: JsonHelpers.nullableStringFrom(json['cancellationReason']),
      createdAt: JsonHelpers.dateTimeFrom(json['createdAt']),
      updatedAt: JsonHelpers.dateTimeFrom(json['updatedAt']),
    );
  }
}

extension MedicalRecordJsonSync on db.MedicalRecord {
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'petId': petId,
      'veterinarianId': veterinarianId,
      'appointmentId': appointmentId,
      'recordType': recordType,
      'title': title,
      'description': description,
      'diagnosis': diagnosis,
      'treatment': treatment,
      'medications': medications,
      'attachments': attachments,
      'recordedAt': recordedAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static db.MedicalRecord fromJson(Map<String, dynamic> json) {
    return db.MedicalRecord(
      id: JsonHelpers.intFrom(json['id']),
      petId: JsonHelpers.intFrom(json['petId']),
      veterinarianId: JsonHelpers.intFrom(json['veterinarianId']),
      appointmentId: JsonHelpers.nullableIntFrom(json['appointmentId']),
      recordType: JsonHelpers.stringFrom(json['recordType']),
      title: JsonHelpers.stringFrom(json['title']),
      description: JsonHelpers.nullableStringFrom(json['description']),
      diagnosis: JsonHelpers.nullableStringFrom(json['diagnosis']),
      treatment: JsonHelpers.nullableStringFrom(json['treatment']),
      medications: JsonHelpers.nullableStringFrom(json['medications']),
      attachments: JsonHelpers.nullableStringFrom(json['attachments']),
      recordedAt: JsonHelpers.dateTimeFrom(json['recordedAt']),
      createdAt: JsonHelpers.dateTimeFrom(json['createdAt']),
    );
  }
}

extension VaccinationJsonSync on db.Vaccination {
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'petId': petId,
      'veterinarianId': veterinarianId,
      'vaccineName': vaccineName,
      'manufacturer': manufacturer,
      'batchNumber': batchNumber,
      'administeredAt': administeredAt.toIso8601String(),
      'nextDueAt': nextDueAt?.toIso8601String(),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static db.Vaccination fromJson(Map<String, dynamic> json) {
    return db.Vaccination(
      id: JsonHelpers.intFrom(json['id']),
      petId: JsonHelpers.intFrom(json['petId']),
      veterinarianId: JsonHelpers.intFrom(json['veterinarianId']),
      vaccineName: JsonHelpers.stringFrom(json['vaccineName']),
      manufacturer: JsonHelpers.nullableStringFrom(json['manufacturer']),
      batchNumber: JsonHelpers.nullableStringFrom(json['batchNumber']),
      administeredAt: JsonHelpers.dateTimeFrom(json['administeredAt']),
      nextDueAt: JsonHelpers.nullableDateTimeFrom(json['nextDueAt']),
      notes: JsonHelpers.nullableStringFrom(json['notes']),
      createdAt: JsonHelpers.dateTimeFrom(json['createdAt']),
    );
  }
}

extension InventoryItemJsonSync on db.InventoryItem {
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'unit': unit,
      'currentStock': currentStock,
      'minStock': minStock,
      'maxStock': maxStock,
      'unitCost': unitCost,
      'supplier': supplier,
      'location': location,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static db.InventoryItem fromJson(Map<String, dynamic> json) {
    return db.InventoryItem(
      id: JsonHelpers.intFrom(json['id']),
      name: JsonHelpers.stringFrom(json['name']),
      category: JsonHelpers.stringFrom(json['category']),
      unit: JsonHelpers.stringFrom(json['unit']),
      currentStock: JsonHelpers.doubleFrom(json['currentStock']),
      minStock: JsonHelpers.doubleFrom(json['minStock']),
      maxStock: JsonHelpers.nullableDoubleFrom(json['maxStock']),
      unitCost: JsonHelpers.nullableDoubleFrom(json['unitCost']),
      supplier: JsonHelpers.nullableStringFrom(json['supplier']),
      location: JsonHelpers.nullableStringFrom(json['location']),
      createdAt: JsonHelpers.dateTimeFrom(json['createdAt']),
      updatedAt: JsonHelpers.dateTimeFrom(json['updatedAt']),
    );
  }
}

extension InventoryBatchJsonSync on db.InventoryBatche {
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'inventoryId': inventoryId,
      'batchNumber': batchNumber,
      'quantity': quantity,
      'receivedAt': receivedAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'costPerUnit': costPerUnit,
      'supplier': supplier,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static db.InventoryBatche fromJson(Map<String, dynamic> json) {
    return db.InventoryBatche(
      id: JsonHelpers.intFrom(json['id']),
      inventoryId: JsonHelpers.intFrom(json['inventoryId']),
      batchNumber: JsonHelpers.stringFrom(json['batchNumber']),
      quantity: JsonHelpers.doubleFrom(json['quantity']),
      receivedAt: JsonHelpers.dateTimeFrom(json['receivedAt']),
      expiresAt: JsonHelpers.nullableDateTimeFrom(json['expiresAt']),
      costPerUnit: JsonHelpers.nullableDoubleFrom(json['costPerUnit']),
      supplier: JsonHelpers.nullableStringFrom(json['supplier']),
      createdAt: JsonHelpers.dateTimeFrom(json['createdAt']),
    );
  }
}

extension PrescriptionJsonSync on db.Prescription {
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'medicalRecordId': medicalRecordId,
      'petId': petId,
      'medicationName': medicationName,
      'dosage': dosage,
      'frequency': frequency,
      'durationDays': durationDays,
      'quantity': quantity,
      'refillsRemaining': refillsRemaining,
      'instructions': instructions,
      'prescribedAt': prescribedAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static db.Prescription fromJson(Map<String, dynamic> json) {
    return db.Prescription(
      id: JsonHelpers.intFrom(json['id']),
      medicalRecordId: JsonHelpers.intFrom(json['medicalRecordId']),
      petId: JsonHelpers.intFrom(json['petId']),
      medicationName: JsonHelpers.stringFrom(json['medicationName']),
      dosage: JsonHelpers.stringFrom(json['dosage']),
      frequency: JsonHelpers.stringFrom(json['frequency']),
      durationDays: JsonHelpers.intFrom(json['durationDays']),
      quantity: JsonHelpers.doubleFrom(json['quantity']),
      refillsRemaining: JsonHelpers.intFrom(json['refillsRemaining']),
      instructions: JsonHelpers.nullableStringFrom(json['instructions']),
      prescribedAt: JsonHelpers.dateTimeFrom(json['prescribedAt']),
      expiresAt: JsonHelpers.nullableDateTimeFrom(json['expiresAt']),
      status: JsonHelpers.stringFrom(json['status']),
      createdAt: JsonHelpers.dateTimeFrom(json['createdAt']),
    );
  }
}

extension QueueEntryJsonSync on db.QueueEntry {
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'appointmentId': appointmentId,
      'position': position,
      'status': status,
      'checkedInAt': checkedInAt.toIso8601String(),
      'calledAt': calledAt?.toIso8601String(),
      'roomEnteredAt': roomEnteredAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'room': room,
      'estimatedWaitMinutes': estimatedWaitMinutes,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  static db.QueueEntry fromJson(Map<String, dynamic> json) {
    return db.QueueEntry(
      id: JsonHelpers.intFrom(json['id']),
      appointmentId: JsonHelpers.intFrom(json['appointmentId']),
      position: JsonHelpers.intFrom(json['position']),
      status: JsonHelpers.stringFrom(json['status']),
      checkedInAt: JsonHelpers.dateTimeFrom(json['checkedInAt']),
      calledAt: JsonHelpers.nullableDateTimeFrom(json['calledAt']),
      roomEnteredAt: JsonHelpers.nullableDateTimeFrom(json['roomEnteredAt']),
      completedAt: JsonHelpers.nullableDateTimeFrom(json['completedAt']),
      room: JsonHelpers.nullableStringFrom(json['room']),
      estimatedWaitMinutes: JsonHelpers.nullableIntFrom(json['estimatedWaitMinutes']),
      notes: JsonHelpers.nullableStringFrom(json['notes']),
      createdAt: JsonHelpers.dateTimeFrom(json['createdAt']),
      updatedAt: JsonHelpers.nullableDateTimeFrom(json['updatedAt']),
    );
  }
}

extension NotificationJsonSync on db.Notification {
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'title': title,
      'message': message,
      'referenceId': referenceId,
      'referenceType': referenceType,
      'isRead': isRead,
      'readAt': readAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static db.Notification fromJson(Map<String, dynamic> json) {
    return db.Notification(
      id: JsonHelpers.intFrom(json['id']),
      userId: JsonHelpers.intFrom(json['userId']),
      type: JsonHelpers.stringFrom(json['type']),
      title: JsonHelpers.stringFrom(json['title']),
      message: JsonHelpers.stringFrom(json['message']),
      referenceId: JsonHelpers.nullableIntFrom(json['referenceId']),
      referenceType: JsonHelpers.nullableStringFrom(json['referenceType']),
      isRead: JsonHelpers.boolFrom(json['isRead']),
      readAt: JsonHelpers.nullableDateTimeFrom(json['readAt']),
      createdAt: JsonHelpers.dateTimeFrom(json['createdAt']),
    );
  }
}

extension InventoryTransactionJsonSync on db.InventoryTransaction {
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'batchId': batchId,
      'type': type,
      'quantityChange': quantityChange,
      'quantityBefore': quantityBefore,
      'quantityAfter': quantityAfter,
      'reason': reason,
      'referenceType': referenceType,
      'referenceId': referenceId,
      'performedBy': performedBy,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static db.InventoryTransaction fromJson(Map<String, dynamic> json) {
    return db.InventoryTransaction(
      id: JsonHelpers.intFrom(json['id']),
      batchId: JsonHelpers.intFrom(json['batchId']),
      type: JsonHelpers.stringFrom(json['type']),
      quantityChange: JsonHelpers.doubleFrom(json['quantityChange']),
      quantityBefore: JsonHelpers.doubleFrom(json['quantityBefore']),
      quantityAfter: JsonHelpers.doubleFrom(json['quantityAfter']),
      reason: JsonHelpers.stringFrom(json['reason']),
      referenceType: JsonHelpers.nullableStringFrom(json['referenceType']),
      referenceId: JsonHelpers.nullableIntFrom(json['referenceId']),
      performedBy: JsonHelpers.intFrom(json['performedBy']),
      notes: JsonHelpers.nullableStringFrom(json['notes']),
      createdAt: JsonHelpers.dateTimeFrom(json['createdAt']),
    );
  }
}

extension ScanRecordJsonSync on db.ScanRecord {
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'scanType': scanType,
      'imagePath': imagePath,
      'rawOcrText': rawOcrText,
      'extractedData': extractedData,
      'confidenceScore': confidenceScore,
      'status': status,
      'confirmedBy': confirmedBy,
      'confirmedAt': confirmedAt?.toIso8601String(),
      'corrections': corrections,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static db.ScanRecord fromJson(Map<String, dynamic> json) {
    return db.ScanRecord(
      id: JsonHelpers.intFrom(json['id']),
      scanType: JsonHelpers.stringFrom(json['scanType']),
      imagePath: JsonHelpers.stringFrom(json['imagePath']),
      rawOcrText: JsonHelpers.nullableStringFrom(json['rawOcrText']),
      extractedData: JsonHelpers.nullableStringFrom(json['extractedData']),
      confidenceScore: JsonHelpers.nullableDoubleFrom(json['confidenceScore']),
      status: JsonHelpers.stringFrom(json['status']),
      confirmedBy: JsonHelpers.nullableIntFrom(json['confirmedBy']),
      confirmedAt: JsonHelpers.nullableDateTimeFrom(json['confirmedAt']),
      corrections: JsonHelpers.nullableStringFrom(json['corrections']),
      createdAt: JsonHelpers.dateTimeFrom(json['createdAt']),
    );
  }
}

extension AuditLogJsonSync on db.AuditLog {
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'action': action,
      'entityType': entityType,
      'entityId': entityId,
      'oldValues': oldValues,
      'newValues': newValues,
      'ipAddress': ipAddress,
      'userAgent': userAgent,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static db.AuditLog fromJson(Map<String, dynamic> json) {
    return db.AuditLog(
      id: JsonHelpers.intFrom(json['id']),
      userId: JsonHelpers.nullableIntFrom(json['userId']),
      action: JsonHelpers.stringFrom(json['action']),
      entityType: JsonHelpers.stringFrom(json['entityType']),
      entityId: JsonHelpers.nullableIntFrom(json['entityId']),
      oldValues: JsonHelpers.nullableStringFrom(json['oldValues']),
      newValues: JsonHelpers.nullableStringFrom(json['newValues']),
      ipAddress: JsonHelpers.nullableStringFrom(json['ipAddress']),
      userAgent: JsonHelpers.nullableStringFrom(json['userAgent']),
      createdAt: JsonHelpers.dateTimeFrom(json['createdAt']),
    );
  }
}

extension SyncMetadataDataJson on db.SyncMetadataData {
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tableNameCol': tableNameCol,
      'recordId': recordId,
      'operation': operation,
      'payload': payload,
      'version': version,
      'createdAt': createdAt.toIso8601String(),
      'syncedAt': syncedAt?.toIso8601String(),
      'retryCount': retryCount,
      'lastError': lastError,
      'deviceId': deviceId,
    };
  }

  static db.SyncMetadataData fromJson(Map<String, dynamic> json) {
    return db.SyncMetadataData(
      id: JsonHelpers.stringFrom(json['id']),
      tableNameCol: JsonHelpers.stringFrom(json['tableNameCol']),
      recordId: JsonHelpers.intFrom(json['recordId']),
      operation: JsonHelpers.stringFrom(json['operation']),
      payload: JsonHelpers.nullableStringFrom(json['payload']),
      version: JsonHelpers.intFrom(json['version']),
      createdAt: JsonHelpers.dateTimeFrom(json['createdAt']),
      syncedAt: JsonHelpers.nullableDateTimeFrom(json['syncedAt']),
      retryCount: JsonHelpers.intFrom(json['retryCount']),
      lastError: JsonHelpers.nullableStringFrom(json['lastError']),
      deviceId: JsonHelpers.stringFrom(json['deviceId']),
    );
  }
}

extension DeviceInfoDataJson on db.DeviceInfoData {
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fcmToken': fcmToken,
      'firebaseUid': firebaseUid,
      'createdAt': createdAt.toIso8601String(),
      'lastSyncAt': lastSyncAt?.toIso8601String(),
      'platform': platform,
      'appVersion': appVersion,
    };
  }

  static db.DeviceInfoData fromJson(Map<String, dynamic> json) {
    return db.DeviceInfoData(
      id: JsonHelpers.stringFrom(json['id']),
      fcmToken: JsonHelpers.nullableStringFrom(json['fcmToken']),
      firebaseUid: JsonHelpers.nullableStringFrom(json['firebaseUid']),
      createdAt: JsonHelpers.dateTimeFrom(json['createdAt']),
      lastSyncAt: JsonHelpers.nullableDateTimeFrom(json['lastSyncAt']),
      platform: JsonHelpers.stringFrom(json['platform']),
      appVersion: JsonHelpers.stringFrom(json['appVersion']),
    );
  }
}