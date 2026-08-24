import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carepaw/core/database/database.dart' as db;
import 'package:carepaw/core/database/tables.dart';
import 'package:carepaw/core/sync/sync_repository.dart';
import 'package:carepaw/core/sync/sync_repository_impl.dart';
import 'package:carepaw/core/sync/conflict_resolver.dart';
import 'package:carepaw/core/sync/network_monitor.dart';
import 'package:carepaw/core/firebase/firestore_schema.dart';
import 'package:carepaw/features/authentication/domain/entities/user.dart' as auth_entities;
import 'package:carepaw/features/authentication/domain/repositories/auth_repository.dart';

/// Sync engine for bidirectional Firestore synchronization.
///
/// Handles:
/// - Push local changes to Firestore
/// - Pull remote changes from Firestore
/// - Conflict detection and resolution
/// - Incremental sync using timestamps
class SyncEngine {
  final SyncRepository _syncRepo;
  final FirebaseFirestore _firestore;
  final AuthRepository _authRepo;
  final NetworkMonitor _networkMonitor;

  bool _isSyncing = false;
  DateTime? _lastSyncStart;
  int _consecutiveFailures = 0;

  SyncEngine({
    required SyncRepository syncRepo,
    required FirebaseFirestore firestore,
    required AuthRepository authRepo,
    required NetworkMonitor networkMonitor,
  })  : _syncRepo = syncRepo,
        _firestore = firestore,
        _authRepo = authRepo,
        _networkMonitor = networkMonitor;

  /// Whether a sync is currently in progress
  bool get isSyncing => _isSyncing;

  /// Last sync start time
  DateTime? get lastSyncStart => _lastSyncStart;

  /// Perform a full bidirectional sync.
  ///
  /// Returns [SyncResult] with counts and any errors.
  Future<SyncResult> performSync() async {
    if (_isSyncing) {
      return SyncResult.failure(['Sync already in progress']);
    }

    if (!_networkMonitor.shouldSync) {
      return SyncResult.failure(['Not on WiFi - sync skipped']);
    }

    _isSyncing = true;
    _lastSyncStart = DateTime.now();
    final errors = <String>[];
    int syncedCount = 0;
    int failedCount = 0;

    try {
      // 1. Push local changes to Firestore
      final pushResult = await _pushChanges();
      syncedCount += pushResult.syncedCount;
      failedCount += pushResult.failedCount;
      errors.addAll(pushResult.errors);

      // 2. Pull remote changes from Firestore
      final pullResult = await _pullChanges();
      syncedCount += pullResult.syncedCount;
      failedCount += pullResult.failedCount;
      errors.addAll(pullResult.errors);

      // 3. Update last sync time on success
      if (failedCount == 0) {
        await _syncRepo.updateLastSyncTime(DateTime.now());
        _consecutiveFailures = 0;
      } else {
        _consecutiveFailures++;
      }

      return SyncResult.partial(
        synced: syncedCount,
        failed: failedCount,
        errors: errors,
      );
    } catch (e) {
      _consecutiveFailures++;
      errors.add('Sync engine error: $e');
      return SyncResult.failure(errors);
    } finally {
      _isSyncing = false;
    }
  }

  /// Push pending local operations to Firestore
  Future<SyncResult> _pushChanges() async {
    final pendingOps = await _syncRepo.getPendingOperations(limit: 100);
    if (pendingOps.isEmpty) {
      return SyncResult.success(0);
    }

    int synced = 0;
    int failed = 0;
    final errors = <String>[];

    // Group by table for batch writes
    final opsByTable = <String, List<SyncMetadataEntry>>{};
    for (final op in pendingOps) {
      opsByTable.putIfAbsent(op.tableName, () => []).add(op);
    }

    for (final entry in opsByTable.entries) {
      final tableName = entry.key;
      final ops = entry.value;
      final collectionName = FirestoreSchema.tableToCollection(tableName);
      final batch = _firestore.batch();

      for (final op in ops) {
        try {
          final docRef = _firestore.collection(collectionName).doc(op.recordId.toString());

          switch (op.operation) {
            case SyncOperation.insert:
              // Add deviceId and version to payload
              final insertData = {
                ...?op.payload,
                'id': op.recordId,
                'deviceId': op.deviceId,
                'version': op.version,
                'createdAt': FieldValue.serverTimestamp(),
                'updatedAt': FieldValue.serverTimestamp(),
              };
              batch.set(docRef, insertData);
              break;

            case SyncOperation.update:
              final updateData = {
                ...?op.payload,
                'version': FieldValue.increment(1),
                'updatedAt': FieldValue.serverTimestamp(),
              };
              batch.update(docRef, updateData);
              break;

            case SyncOperation.delete:
              batch.delete(docRef);
              break;
          }

          // Mark as synced locally (optimistic)
          await _syncRepo.markSynced(op.id);
          synced++;
        } catch (e) {
          await _syncRepo.markFailed(op.id, e.toString());
          failed++;
          errors.add('Failed to push ${op.tableName}:${op.recordId} - $e');
        }
      }

      // Commit batch
      try {
        await batch.commit();
      } catch (e) {
        // If batch fails, mark all in batch as failed
        for (final op in ops) {
          await _syncRepo.markFailed(op.id, 'Batch commit failed: $e');
        }
        failed += ops.length;
        synced -= ops.length; // Adjust since we optimistically marked them
        errors.add('Batch commit failed for $tableName: $e');
      }
    }

    return SyncResult.partial(synced: synced, failed: failed, errors: errors);
  }

  /// Pull remote changes from Firestore since last sync
  Future<SyncResult> _pullChanges() async {
    final lastSync = await _syncRepo.getLastSyncTime();
    final deviceId = await _syncRepo.getOrCreateDeviceId();

    int synced = 0;
    int failed = 0;
    final errors = <String>[];

    // Sync each table
    for (final collectionName in FirestoreSchema.syncableCollections) {
      try {
        final result = await _pullCollection(collectionName, lastSync, deviceId);
        synced += result.syncedCount;
        failed += result.failedCount;
        errors.addAll(result.errors);
      } catch (e) {
        failed++;
        errors.add('Failed to pull $collectionName: $e');
      }
    }

    return SyncResult.partial(synced: synced, failed: failed, errors: errors);
  }

  /// Pull changes for a single collection
  Future<SyncResult> _pullCollection(
    String collectionName,
    DateTime? lastSync,
    String deviceId,
  ) async {
    int synced = 0;
    int failed = 0;
    final errors = <String>[];

    Query<Map<String, dynamic>> query = _firestore
        .collection(collectionName)
        .orderBy('updatedAt')
        .limit(500);

    if (lastSync != null) {
      query = query.where('updatedAt', isGreaterThan: Timestamp.fromDate(lastSync));
    }

    // Exclude our own writes (by deviceId) to avoid loops
    // Note: This requires deviceId field in documents
    // query = query.where('deviceId', isNotEqualTo: deviceId); // Requires index

    final snapshot = await query.get();

    for (final doc in snapshot.docs) {
      try {
        await _applyRemoteDocument(collectionName, doc);
        synced++;
      } catch (e) {
        failed++;
        errors.add('Failed to apply $collectionName/${doc.id}: $e');
      }
    }

    return SyncResult.partial(synced: synced, failed: failed, errors: errors);
  }

  /// Apply a remote document to local database
  Future<void> _applyRemoteDocument(
    String collectionName,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final tableName = FirestoreSchema.collectionToTable(collectionName);
    final remoteData = doc.data();
    final recordId = int.tryParse(doc.id) ?? 0;

    // Get local version if exists
    final localData = await _getLocalRecord(tableName, recordId);

    // Check for conflict
    if (localData != null) {
      final strategy = ConflictResolver.getStrategy(collectionName);

      if (strategy == ConflictStrategy.manual) {
        // Check if actually different
        if (_dataDiffers(localData, remoteData)) {
          // Create conflict record for manual resolution
          await _createConflictRecord(collectionName, doc.id, localData, remoteData);
          return; // Don't auto-apply
        }
      } else {
        // Auto-resolve
        final resolved = ConflictResolver.resolve(collectionName, localData, remoteData);
        if (resolved != null) {
          await _writeLocalRecord(tableName, recordId, resolved);
        }
        return;
      }
    }

    // No conflict or local doesn't exist - apply remote
    await _writeLocalRecord(tableName, recordId, remoteData);
  }

  /// Get local record by table and ID
  Future<Map<String, dynamic>?> _getLocalRecord(String tableName, int recordId) async {
    // This would use the appropriate DAO based on tableName
    // For now, return null (implement per table)
    // TODO: Implement using DAOs
    return null;
  }

  /// Write record to local database
  Future<void> _writeLocalRecord(
    String tableName,
    int recordId,
    Map<String, dynamic> data,
  ) async {
    // This would use the appropriate DAO based on tableName
    // TODO: Implement using DAOs
  }

  /// Check if two data maps differ significantly
  bool _dataDiffers(Map<String, dynamic> a, Map<String, dynamic> b) {
    // Simple comparison - in practice, compare relevant fields only
    final aKeys = a.keys.toSet()..removeWhere((k) => k == 'updatedAt' || k == 'version' || k == 'deviceId');
    final bKeys = b.keys.toSet()..removeWhere((k) => k == 'updatedAt' || k == 'version' || k == 'deviceId');

    if (aKeys.length != bKeys.length) return true;

    for (final key in aKeys) {
      if (a[key] != b[key]) return true;
    }
    return false;
  }

  /// Create conflict record for manual review
  Future<void> _createConflictRecord(
    String collectionName,
    String recordId,
    Map<String, dynamic> localData,
    Map<String, dynamic> remoteData,
  ) async {
    final deviceId = await _syncRepo.getOrCreateDeviceId();
    final conflict = ConflictResolver.createConflictRecord(
      tableName: collectionName,
      recordId: recordId,
      localData: localData,
      remoteData: remoteData,
      deviceId: deviceId,
    );

    await _firestore
        .collection(FirestoreSchema.syncConflicts)
        .doc(conflict['id'] as String)
        .set(conflict);
  }

  /// Resolve a manual conflict (called from UI)
  Future<void> resolveConflict(String conflictId, Map<String, dynamic> resolution) async {
    await _firestore
        .collection(FirestoreSchema.syncConflicts)
        .doc(conflictId)
        .update({
      'resolved': true,
      'resolution': resolution,
      'resolvedAt': FieldValue.serverTimestamp(),
    });

    // Apply resolution locally
    final tableName = resolution['tableName'] as String;
    final recordId = int.tryParse(resolution['recordId'] as String) ?? 0;
    await _writeLocalRecord(tableName, recordId, resolution);
  }

  /// Get all unresolved conflicts
  Future<List<SyncConflict>> getUnresolvedConflicts() async {
    final snapshot = await _firestore
        .collection(FirestoreSchema.syncConflicts)
        .where('resolved', isEqualTo: false)
        .get();

    return snapshot.docs.map(SyncConflict.fromFirestore).toList();
  }
}