import 'package:drift/drift.dart';
import 'package:carepaw/core/database/database.dart';
import 'package:carepaw/core/database/tables.dart';

part 'audit_logs_dao.g.dart';

@DriftAccessor(tables: [AuditLogs, Users])
class AuditLogsDao extends DatabaseAccessor<CarePawDatabase> with _$AuditLogsDaoMixin {
  AuditLogsDao(super.db);

  // ============ Queries ============

  /// Get audit log by ID
  Future<AuditLog?> getById(int id) {
    return (select(auditLogs)..where((a) => a.id.equals(id))).getSingleOrNull();
  }

  /// Get audit logs for an entity
  Future<List<AuditLog>> getByEntity(String entityType, int entityId) {
    return (select(auditLogs)
          ..where((a) => a.entityType.equals(entityType) & a.entityId.equals(entityId))
          ..orderBy([(a) => OrderingTerm.desc(a.createdAt)]))
        .get();
  }

  /// Get audit logs by user
  Future<List<AuditLog>> getByUser(int userId, {int limit = 100}) {
    return (select(auditLogs)
          ..where((a) => a.userId.equals(userId))
          ..orderBy([(a) => OrderingTerm.desc(a.createdAt)])
          ..limit(limit))
        .get();
  }

  /// Get audit logs by action
  Future<List<AuditLog>> getByAction(String action, {int limit = 100}) {
    return (select(auditLogs)
          ..where((a) => a.action.equals(action))
          ..orderBy([(a) => OrderingTerm.desc(a.createdAt)])
          ..limit(limit))
        .get();
  }

  /// Get recent audit logs
  Future<List<AuditLogWithUser>> getRecent({int limit = 100}) {
    final query = select(auditLogs).join([
      leftOuterJoin(users, users.id.equalsExp(auditLogs.userId)),
    ])..orderBy([OrderingTerm.desc(auditLogs.createdAt)])..limit(limit);

    return query.map((row) {
      return AuditLogWithUser(
        auditLog: row.readTable(auditLogs),
        user: row.readTableOrNull(users),
      );
    }).get();
  }

  /// Get audit logs in date range
  Future<List<AuditLog>> getInRange(DateTime start, DateTime end) {
    return (select(auditLogs)
          ..where((a) =>
              a.createdAt.isBiggerOrEqualValue(start) &
              a.createdAt.isSmallerOrEqualValue(end))
          ..orderBy([(a) => OrderingTerm.desc(a.createdAt)]))
        .get();
  }

  // ============ Mutations ============

  /// Create audit log entry
  Future<int> createAuditLog(AuditLogsCompanion log) {
    return into(auditLogs).insert(log);
  }

  /// Create audit log with automatic timestamp
  Future<int> log({
    required String action,
    required String entityType,
    int? entityId,
    int? userId,
    String? oldValues,
    String? newValues,
    String? ipAddress,
    String? userAgent,
  }) {
    return createAuditLog(AuditLogsCompanion(
      action: Value(action),
      entityType: Value(entityType),
      entityId: entityId != null ? Value(entityId) : const Value.absent(),
      userId: userId != null ? Value(userId) : const Value.absent(),
      oldValues: oldValues != null ? Value(oldValues) : const Value.absent(),
      newValues: newValues != null ? Value(newValues) : const Value.absent(),
      ipAddress: ipAddress != null ? Value(ipAddress) : const Value.absent(),
      userAgent: userAgent != null ? Value(userAgent) : const Value.absent(),
      createdAt: Value(DateTime.now()),
    ));
  }

  /// Cleanup old audit logs (retention policy)
  Future<int> deleteOlderThan(DateTime cutoff) {
    return (delete(auditLogs)
          ..where((a) => a.createdAt.isSmallerThanValue(cutoff)))
        .go();
  }
}

/// Audit log with user info
class AuditLogWithUser {
  final AuditLog auditLog;
  final User? user;

  AuditLogWithUser({
    required this.auditLog,
    this.user,
  });
}