import 'package:drift/drift.dart';
import 'package:carepaw/core/database/database.dart';
import 'package:carepaw/core/database/tables.dart';

part 'sync_metadata_dao.g.dart';

@DriftAccessor(tables: [SyncMetadata])
class SyncMetadataDao extends DatabaseAccessor<CarePawDatabase> with _$SyncMetadataDaoMixin {
  SyncMetadataDao(super.db);

  // ============ Queries ============

  /// Get all unsynced operations
  Future<List<SyncMetadataData>> getUnsyncedOperations({int limit = 100}) {
    return (select(syncMetadata)
          ..where((s) => s.syncedAt.isNull())
          ..orderBy([
            (s) => OrderingTerm.asc(s.createdAt),
          ])
          ..limit(limit))
        .get();
  }

  /// Get unsynced operations for a specific table
  Future<List<SyncMetadataData>> getUnsyncedOperationsForTable(
    String tableName, {
    int limit = 50,
  }) {
    return (select(syncMetadata)
          ..where((s) => s.syncedAt.isNull() & s.tableNameCol.equals(tableName))
          ..orderBy([
            (s) => OrderingTerm.asc(s.createdAt),
          ])
          ..limit(limit))
        .get();
  }

  /// Find pending operation for a table/record
  Future<SyncMetadataData?> findPendingOperation(String tableName, int recordId) {
    return (select(syncMetadata)
          ..where((s) =>
              s.syncedAt.isNull() &
              s.tableNameCol.equals(tableName) &
              s.recordId.equals(recordId)))
        .getSingleOrNull();
  }

  /// Get failed operations
  Future<List<SyncMetadataData>> getFailedOperations({int limit = 50}) {
    return (select(syncMetadata)
          ..where((s) => s.syncedAt.isNull() & s.retryCount.isBiggerThanValue(0))
          ..orderBy([
            (s) => OrderingTerm.asc(s.createdAt),
          ])
          ..limit(limit))
        .get();
  }

  /// Get total pending count
  Future<int> getPendingCount() {
    return (select(syncMetadata)..where((s) => s.syncedAt.isNull())).get().then((list) => list.length);
  }

  // ============ Mutations ============

  /// Insert a new sync metadata entry
  Future<int> insertSyncMetadata(SyncMetadataCompanion entry) {
    return into(syncMetadata).insert(entry);
  }

  /// Mark operation as synced
  Future<int> markSynced(String id, DateTime syncedAt) {
    return (update(syncMetadata)..where((s) => s.id.equals(id)))
        .write(SyncMetadataCompanion(
      syncedAt: Value(syncedAt),
      retryCount: const Value(0),
      lastError: const Value(null),
    ));
  }

  /// Mark operation as failed
  Future<int> markFailed(String id, String error) {
    return transaction(() async {
      final existing = await (select(syncMetadata)..where((s) => s.id.equals(id))).getSingle();
      return (update(syncMetadata)..where((s) => s.id.equals(id)))
          .write(SyncMetadataCompanion(
        retryCount: Value(existing.retryCount + 1),
        lastError: Value(error),
      ));
    });
  }

  /// Update payload for an existing operation
  Future<int> updatePayload(String id, String? payloadJson) {
    return transaction(() async {
      final existing = await (select(syncMetadata)..where((s) => s.id.equals(id))).getSingle();
      return (update(syncMetadata)..where((s) => s.id.equals(id)))
          .write(SyncMetadataCompanion(
        payload: Value(payloadJson),
        version: Value(existing.version + 1),
      ));
    });
  }

  /// Delete pending operations for a table/record
  Future<int> deletePendingOperations(String tableName, int recordId) {
    return (delete(syncMetadata)..where((s) =>
        s.syncedAt.isNull() &
        s.tableNameCol.equals(tableName) &
        s.recordId.equals(recordId)))
      .go();
  }

  /// Delete old synced operations (cleanup)
  Future<int> deleteOldSyncedOperations(DateTime cutoff) {
    return (delete(syncMetadata)
          ..where((s) => s.syncedAt.isNotNull() & s.syncedAt.isSmallerThanValue(cutoff)))
      .go();
  }
}