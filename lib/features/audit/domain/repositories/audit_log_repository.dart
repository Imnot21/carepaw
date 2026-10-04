import 'package:carepaw/core/repositories/base_repository.dart';
import 'package:carepaw/features/audit/domain/entities/audit_log.dart';

/// Audit log repository interface - domain layer contract.
///
/// Reading surface for the admin Audit Logs page. Writing is intentionally
/// one-way (append): callers create entries via [write] and never edit or
/// delete them, matching the append-only audit-trail requirement.
abstract class AuditLogRepository extends BaseRepository<AuditLog, int> {
  /// Append a new audit entry (best-effort; the caller decides whether a
  /// failure is fatal).
  Future<void> write(AuditLog log);

  /// Find entries for a specific actor (user id), most recent first.
  Future<List<AuditLog>> findByUser(int userId, {int limit = 100});

  /// Find entries for a specific entity type, most recent first.
  Future<List<AuditLog>> findByEntityType(String entityType, {int limit = 100});

  /// Find entries for a specific action, most recent first.
  Future<List<AuditLog>> findByAction(String action, {int limit = 100});

  /// Stream the most recent entries (newest first).
  Stream<List<AuditLog>> watchRecent({int limit = 100});
}
