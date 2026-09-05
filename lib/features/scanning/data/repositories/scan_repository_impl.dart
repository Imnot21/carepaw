import 'package:drift/drift.dart';
import 'package:carepaw/core/database/database.dart';
import 'package:carepaw/core/sync/sync_repository.dart';
import 'package:carepaw/features/scanning/domain/repositories/scan_repository.dart';
import 'package:carepaw/features/scanning/domain/entities/scan_record.dart' as domain;
import 'package:carepaw/core/repositories/base_repository.dart';

/// Scan record repository implementation - data layer
/// Converts between Drift entities and domain entities
class ScanRecordRepositoryImpl implements ScanRecordRepository {
  final CarePawDatabase _database;
  final SyncRepository syncRepo;

  ScanRecordRepositoryImpl(this._database, {required this.syncRepo});

  @override
  Future<domain.ScanRecord?> findById(int id) async {
    final entity = await (_database.select(_database.scanRecords)
          ..where((s) => s.id.equals(id)))
        .getSingleOrNull();
    return entity != null ? _toDomain(entity) : null;
  }

  @override
  Future<List<domain.ScanRecord>> findAll() async {
    final entities = await (_database.select(_database.scanRecords)
          ..orderBy([(s) => OrderingTerm.desc(s.createdAt)]))
        .get();
    return entities.map(_toDomain).toList();
  }

  @override
  Future<domain.ScanRecord> save(domain.ScanRecord entity) async {
    final companion = _toCompanion(entity);
    if (entity.id == null) {
      final id = await _database.into(_database.scanRecords).insert(companion);
      return entity.copyWith(id: id);
    } else {
      await _database.update(_database.scanRecords).replace(companion);
      return entity;
    }
  }

  @override
  Future<void> delete(int id) async {
    // Scan records can be deleted
    await (_database.delete(_database.scanRecords)..where((s) => s.id.equals(id))).go();
  }

  @override
  Future<bool> exists(int id) async {
    final entity = await findById(id);
    return entity != null;
  }

  @override
  Future<void> softDelete(int id) async {
    await delete(id);
  }

  @override
  Future<void> restore(int id) async {
    throw UnsupportedError('Scan records cannot be restored');
  }

  @override
  Future<List<domain.ScanRecord>> findAllIncludingDeleted() async {
    return findAll();
  }

  @override
  Stream<domain.ScanRecord?> watchById(int id) {
    return (_database.select(_database.scanRecords)
          ..where((s) => s.id.equals(id)))
        .watchSingleOrNull()
        .map((entity) => entity != null ? _toDomain(entity) : null);
  }

  @override
  Stream<List<domain.ScanRecord>> watchAll() {
    return (_database.select(_database.scanRecords)
          ..orderBy([(s) => OrderingTerm.desc(s.createdAt)]))
        .watch()
        .map((entities) => entities.map(_toDomain).toList());
  }

  @override
  Future<List<domain.ScanRecord>> findByType(domain.ScanType scanType) async {
    final entities = await (_database.select(_database.scanRecords)
          ..where((s) => s.scanType.equals(scanType.value))
          ..orderBy([(s) => OrderingTerm.desc(s.createdAt)]))
        .get();
    return entities.map(_toDomain).toList();
  }

  @override
  Future<List<domain.ScanRecord>> findByStatus(domain.ScanStatus status) async {
    final entities = await (_database.select(_database.scanRecords)
          ..where((s) => s.status.equals(status.value))
          ..orderBy([(s) => OrderingTerm.desc(s.createdAt)]))
        .get();
    return entities.map(_toDomain).toList();
  }

  @override
  Future<List<domain.ScanRecord>> findPending() async {
    return findByStatus(domain.ScanStatus.pending);
  }

  @override
  Future<domain.ScanRecord> confirm(int id, int confirmedBy, String? corrections) async {
    final entity = await findById(id);
    if (entity == null) {
      throw Exception('Scan record not found');
    }
    final updated = entity.copyWith(
      status: domain.ScanStatus.confirmed,
      confirmedBy: confirmedBy,
      confirmedAt: DateTime.now(),
      corrections: corrections,
    );
    return save(updated);
  }

  @override
  Future<domain.ScanRecord> reject(int id, int rejectedBy, String reason) async {
    final entity = await findById(id);
    if (entity == null) {
      throw Exception('Scan record not found');
    }
    final updated = entity.copyWith(
      status: domain.ScanStatus.rejected,
      confirmedBy: rejectedBy,
      confirmedAt: DateTime.now(),
      corrections: reason,
    );
    return save(updated);
  }

  @override
  Future<domain.ScanRecord> updateExtractedData(int id, String extractedData) async {
    final entity = await findById(id);
    if (entity == null) {
      throw Exception('Scan record not found');
    }
    final updated = entity.copyWith(extractedData: extractedData);
    return save(updated);
  }

  @override
  Future<domain.ScanRecord> updateConfidence(int id, double confidenceScore) async {
    final entity = await findById(id);
    if (entity == null) {
      throw Exception('Scan record not found');
    }
    final updated = entity.copyWith(confidenceScore: confidenceScore);
    return save(updated);
  }

  @override
  Future<int> countByStatus(domain.ScanStatus status) async {
    final entities = await findByStatus(status);
    return entities.length;
  }

  @override
  Future<PaginatedResult<domain.ScanRecord>> findPaginated(PaginationParams params) async {
    final allRecords = await findAll();
    final start = params.offset;
    final end = (start + params.pageSize).clamp(0, allRecords.length);
    final items = allRecords.sublist(start, end);
    return PaginatedResult(
      items: items,
      totalCount: allRecords.length,
      page: params.page,
      pageSize: params.pageSize,
    );
  }

  // Private mapping methods

  domain.ScanRecord _toDomain(ScanRecord entity) {
    return domain.ScanRecord(
      id: entity.id,
      scanType: domain.ScanType.fromString(entity.scanType),
      imagePath: entity.imagePath,
      rawOcrText: entity.rawOcrText,
      extractedData: entity.extractedData,
      confidenceScore: entity.confidenceScore,
      status: domain.ScanStatus.fromString(entity.status),
      confirmedBy: entity.confirmedBy,
      confirmedAt: entity.confirmedAt,
      corrections: entity.corrections,
      createdAt: entity.createdAt,
    );
  }

  ScanRecordsCompanion _toCompanion(domain.ScanRecord entity) {
    return ScanRecordsCompanion(
      id: entity.id != null ? Value(entity.id!) : const Value.absent(),
      scanType: Value(entity.scanType.value),
      imagePath: Value(entity.imagePath),
      rawOcrText: Value(entity.rawOcrText),
      extractedData: Value(entity.extractedData),
      confidenceScore: Value(entity.confidenceScore),
      status: Value(entity.status.value),
      confirmedBy: Value(entity.confirmedBy),
      confirmedAt: Value(entity.confirmedAt),
      corrections: Value(entity.corrections),
      createdAt: entity.id == null ? Value(entity.createdAt) : const Value.absent(),
    );
  }

  @override
  Future<domain.ScanRecord> createWithSync(domain.ScanRecord entity, String tableName) async {
    final saved = await save(entity);
    if (saved.id != null) {
      final payload = {
        'id': saved.id,
        'scanType': entity.scanType.value,
        'imagePath': entity.imagePath,
        'rawOcrText': entity.rawOcrText,
        'extractedData': entity.extractedData,
        'confidenceScore': entity.confidenceScore,
        'status': entity.status.value,
        'confirmedBy': entity.confirmedBy,
        'confirmedAt': entity.confirmedAt?.toIso8601String(),
        'corrections': entity.corrections,
        'createdAt': entity.createdAt.toIso8601String(),
      };
      await syncRepo.queueForSync(
        tableName: tableName,
        recordId: saved.id!,
        operation: SyncOperation.insert,
        payload: payload,
      );
    }
    return saved;
  }

  @override
  Future<domain.ScanRecord> updateWithSync(domain.ScanRecord entity, String tableName) async {
    final saved = await save(entity);
    if (saved.id != null) {
      final payload = {
        'id': saved.id,
        'scanType': entity.scanType.value,
        'imagePath': entity.imagePath,
        'rawOcrText': entity.rawOcrText,
        'extractedData': entity.extractedData,
        'confidenceScore': entity.confidenceScore,
        'status': entity.status.value,
        'confirmedBy': entity.confirmedBy,
        'confirmedAt': entity.confirmedAt?.toIso8601String(),
        'corrections': entity.corrections,
        'createdAt': entity.createdAt.toIso8601String(),
      };
      await syncRepo.queueForSync(
        tableName: tableName,
        recordId: saved.id!,
        operation: SyncOperation.update,
        payload: payload,
      );
    }
    return saved;
  }

  @override
  Future<void> deleteWithSync(int id, String tableName) async {
    await delete(id);
    await syncRepo.queueForSync(
      tableName: tableName,
      recordId: id,
      operation: SyncOperation.delete,
    );
  }
}