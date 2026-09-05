import 'package:cloud_firestore/cloud_firestore.dart';

/// Strategy for resolving sync conflicts
enum ConflictStrategy {
  /// Last write wins based on updatedAt timestamp
  lastWriteWins,
  /// Server (Firestore) always wins
  serverWins,
  /// Local (device) always wins
  localWins,
  /// Flag for manual review - don't auto-resolve
  manual,
}

/// Conflict resolver for sync operations.
///
/// Determines how to handle conflicts when the same record
/// is modified on multiple devices before syncing.
class ConflictResolver {
  ConflictResolver._();

  /// Default strategy per table (collection)
  static final Map<String, ConflictStrategy> _tableStrategies = {
    // Critical data - manual review
    'users': ConflictStrategy.manual,
    'medicalRecords': ConflictStrategy.manual,
    'scanRecords': ConflictStrategy.manual,

    // Inventory managed centrally - server wins
    'inventoryItems': ConflictStrategy.serverWins,
    'inventoryBatches': ConflictStrategy.serverWins,
    'inventoryTransactions': ConflictStrategy.serverWins,

    // Queue is real-time local - local wins
    'queueEntries': ConflictStrategy.localWins,

    // Audit logs append-only - server wins (has more complete history)
    'auditLogs': ConflictStrategy.serverWins,

    // Default: last write wins
    'pets': ConflictStrategy.lastWriteWins,
    'appointments': ConflictStrategy.lastWriteWins,
    'vaccinations': ConflictStrategy.lastWriteWins,
    'prescriptions': ConflictStrategy.lastWriteWins,
    'notifications': ConflictStrategy.lastWriteWins,
  };

  /// Get strategy for a table
  static ConflictStrategy getStrategy(String tableName) {
    return _tableStrategies[tableName] ?? ConflictStrategy.lastWriteWins;
  }

  /// Set custom strategy for a table (for testing or configuration)
  static void setStrategy(String tableName, ConflictStrategy strategy) {
    _tableStrategies[tableName] = strategy;
  }

  /// Resolve conflict between local and remote versions.
  ///
  /// Returns the winning data map, or null if manual resolution needed.
  static Map<String, dynamic>? resolve(
    String tableName,
    Map<String, dynamic> localData,
    Map<String, dynamic> remoteData,
  ) {
    final strategy = getStrategy(tableName);

    switch (strategy) {
      case ConflictStrategy.lastWriteWins:
        return _lastWriteWins(localData, remoteData);
      case ConflictStrategy.serverWins:
        return remoteData;
      case ConflictStrategy.localWins:
        return localData;
      case ConflictStrategy.manual:
        // Return null to indicate manual resolution needed
        return null;
    }
  }

  /// Last write wins based on updatedAt timestamp
  static Map<String, dynamic> _lastWriteWins(
    Map<String, dynamic> local,
    Map<String, dynamic> remote,
  ) {
    final localTime = _parseTimestamp(local['updatedAt']);
    final remoteTime = _parseTimestamp(remote['updatedAt']);

    if (localTime == null && remoteTime == null) {
      // No timestamps, prefer remote (has server timestamp)
      return remote;
    }
    if (localTime == null) return remote;
    if (remoteTime == null) return local;

    return localTime.isAfter(remoteTime) ? local : remote;
  }

  /// Parse timestamp from various formats
  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }

  /// Check if a conflict requires manual resolution
  static bool requiresManualResolution(String tableName) {
    return getStrategy(tableName) == ConflictStrategy.manual;
  }

  /// Create a conflict record for manual review
  static Map<String, dynamic> createConflictRecord({
    required String tableName,
    required String recordId,
    required Map<String, dynamic> localData,
    required Map<String, dynamic> remoteData,
    required String deviceId,
  }) {
    return {
      'id': '$tableName:$recordId:${DateTime.now().millisecondsSinceEpoch}',
      'tableName': tableName,
      'recordId': recordId,
      'localData': localData,
      'remoteData': remoteData,
      'deviceId': deviceId,
      'createdAt': FieldValue.serverTimestamp(),
      'resolved': false,
      'resolution': null,
    };
  }
}

/// Conflict data for UI display
class SyncConflict {
  final String id;
  final String tableName;
  final String recordId;
  final Map<String, dynamic> localData;
  final Map<String, dynamic> remoteData;
  final String deviceId;
  final DateTime createdAt;
  final bool resolved;
  final Map<String, dynamic>? resolution;

  const SyncConflict({
    required this.id,
    required this.tableName,
    required this.recordId,
    required this.localData,
    required this.remoteData,
    required this.deviceId,
    required this.createdAt,
    this.resolved = false,
    this.resolution,
  });

  factory SyncConflict.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return SyncConflict(
      id: doc.id,
      tableName: data['tableName'] as String,
      recordId: data['recordId'] as String,
      localData: Map<String, dynamic>.from(data['localData'] as Map),
      remoteData: Map<String, dynamic>.from(data['remoteData'] as Map),
      deviceId: data['deviceId'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      resolved: data['resolved'] as bool? ?? false,
      resolution: data['resolution'] != null
          ? Map<String, dynamic>.from(data['resolution'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'tableName': tableName,
      'recordId': recordId,
      'localData': localData,
      'remoteData': remoteData,
      'deviceId': deviceId,
      'createdAt': Timestamp.fromDate(createdAt),
      'resolved': resolved,
      'resolution': resolution,
    };
  }
}