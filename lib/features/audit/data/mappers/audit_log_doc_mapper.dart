import 'package:carepaw/core/firebase/date_field_codec.dart';
import 'package:carepaw/core/firebase/firestore_schema.dart';
import 'package:carepaw/features/audit/domain/entities/audit_log.dart';

/// Maps between Firestore `auditLogs/{id}` documents and the domain [AuditLog].
///
/// Field names mirror the legacy Drift table via [FirestoreSchema]. The
/// document ID is the string form of [AuditLog.id].
///
/// Audit entries are append-only; there is deliberately no `toUpdate`/delete
/// path in the mapper or repository.
class AuditLogDocMapper {
  AuditLogDocMapper._();

  /// Build a domain [AuditLog] from Firestore document data.
  static AuditLog fromData(Map<String, dynamic> data) {
    return AuditLog(
      id: data[FirestoreSchema.id] as int?,
      userId: (data[FirestoreSchema.userIdAudit] as num?)?.toInt() ?? 0,
      action: (data[FirestoreSchema.action] as String?) ?? '',
      entityType: (data[FirestoreSchema.entityType] as String?) ?? '',
      entityId: (data[FirestoreSchema.entityId] as String?) ?? '',
      oldValues: (data[FirestoreSchema.oldValues] as Map?)?.cast<String, dynamic>(),
      newValues: (data[FirestoreSchema.newValues] as Map?)?.cast<String, dynamic>(),
      createdAt: DateFieldCodec.fromFirestoreDate(data[FirestoreSchema.createdAt]) ??
          DateTime.now(),
    );
  }

  /// Serialize a domain [AuditLog] to a Firestore document map.
  static Map<String, dynamic> toData(AuditLog log) {
    return {
      FirestoreSchema.id: log.id,
      FirestoreSchema.userIdAudit: log.userId,
      FirestoreSchema.action: log.action,
      FirestoreSchema.entityType: log.entityType,
      FirestoreSchema.entityId: log.entityId,
      FirestoreSchema.oldValues: log.oldValues,
      FirestoreSchema.newValues: log.newValues,
      FirestoreSchema.createdAt: DateFieldCodec.toFirestoreDate(log.createdAt),
    };
  }
}