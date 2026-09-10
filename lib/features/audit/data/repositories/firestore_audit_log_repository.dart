import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carepaw/core/firebase/firestore_id_sequence.dart';
import 'package:carepaw/core/firebase/firestore_schema.dart';
import 'package:carepaw/features/audit/data/mappers/audit_log_doc_mapper.dart';
import 'package:carepaw/features/audit/domain/entities/audit_log.dart';
import 'package:carepaw/features/audit/domain/repositories/audit_log_repository.dart';

/// Audit log repository implementation - data layer (Firestore-backed).
///
/// Implements [AuditLogRepository] with Cloud Firestore's `auditLogs`
/// collection as the source of truth. Documents are keyed by the app-facing
/// integer `id` (string form). Entries are append-only: [write] creates a
/// document and there is no update/delete path exposed.
///
/// Listing orders newest-first and nudges the Firestore query to a bounded
/// recent window so the collection does not need to be scanned wholesale as
/// the clinic operates.
class FirestoreAuditLogRepository implements AuditLogRepository {
  FirestoreAuditLogRepository({
    required FirebaseFirestore firestore,
    required FirestoreIdSequence auditLogIdSequence,
    this._maxQuery = 1000,
  })  : _firestore = firestore,
        _idSequence = auditLogIdSequence;

  final FirebaseFirestore _firestore;
  final FirestoreIdSequence _idSequence;

  /// Safety cap for list queries. Audit logs are append-only and grow forever,
  /// so reads are bounded rather than scanning the whole collection.
  final int _maxQuery;

  CollectionReference<Map<String, dynamic>> get _audit =>
      _firestore.collection(FirestoreSchema.auditLogs);

  // ============ BaseRepository<AuditLog, int> ============

  @override
  Future<AuditLog?> findById(int id) async {
    final doc = await _findDocByIntId(id);
    return doc == null ? null : AuditLogDocMapper.fromData(doc.data() ?? const {});
  }

  @override
  Future<List<AuditLog>> findAll() async =>
      _findOrderedByCreatedAtDesc(limit: _maxQuery);

  /// Append-only: a new entry is persisted and returned with its assigned id.
  @override
  Future<AuditLog> save(AuditLog entity) async {
    var toWrite = entity;
    if (toWrite.id == null) {
      toWrite = toWrite.copyWith(id: await _idSequence.next());
    }
    await _audit.doc('${toWrite.id}').set(AuditLogDocMapper.toData(toWrite));
    return toWrite;
  }

  @override
  Future<void> write(AuditLog log) async {
    await save(log);
  }

  @override
  Future<void> delete(int id) {
    // Append-only audit trail: entries are never removed.
    throw UnsupportedError('Audit log entries cannot be deleted');
  }

  @override
  Future<bool> exists(int id) async => await findById(id) != null;

  // ============ AuditLogRepository ============

  @override
  Future<List<AuditLog>> findByUser(int userId, {int limit = 100}) async {
    final all = await _findOrderedByCreatedAtDesc(limit: _maxQuery);
    return all.where((log) => log.userId == userId).take(limit).toList();
  }

  @override
  Future<List<AuditLog>> findByEntityType(String entityType, {int limit = 100}) async {
    final all = await _findOrderedByCreatedAtDesc(limit: _maxQuery);
    return all.where((log) => log.entityType == entityType).take(limit).toList();
  }

  @override
  Future<List<AuditLog>> findByAction(String action, {int limit = 100}) async {
    final all = await _findOrderedByCreatedAtDesc(limit: _maxQuery);
    return all.where((log) => log.action == action).take(limit).toList();
  }

  @override
  Stream<List<AuditLog>> watchRecent({int limit = 100}) {
    return _audit
        .orderBy(FirestoreSchema.createdAt, descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => AuditLogDocMapper.fromData(doc.data())).toList());
  }

  // ============ Sync-aware operations (not applicable; append-only) ============

  @override
  Future<AuditLog> createWithSync(AuditLog entity, String tableName) async => save(entity);

  @override
  Future<AuditLog> updateWithSync(AuditLog entity, String tableName) async {
    throw UnsupportedError('Audit log entries cannot be updated');
  }

  @override
  Future<void> deleteWithSync(int id, String tableName) async => delete(id);

  // ============ Private helpers ============

  Future<List<AuditLog>> _findOrderedByCreatedAtDesc({int limit = 100}) async {
    final snapshot = await _audit
        .orderBy(FirestoreSchema.createdAt, descending: true)
        .limit(limit)
        .get();
    return snapshot.docs.map((doc) => AuditLogDocMapper.fromData(doc.data())).toList();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> _findDocByIntId(int id) async {
    final snapshot = await _audit.where(FirestoreSchema.id, isEqualTo: id).limit(1).get();
    return snapshot.docs.isEmpty ? null : snapshot.docs.first;
  }
}