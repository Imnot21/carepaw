import 'package:drift/drift.dart' show Value;
import 'package:carepaw/core/database/database.dart';
import 'package:carepaw/core/database/dao/inventory_dao.dart';
import 'package:carepaw/core/sync/sync_repository.dart';
import 'package:carepaw/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:carepaw/features/inventory/domain/entities/inventory.dart';
import 'package:carepaw/core/repositories/base_repository.dart';
import 'package:carepaw/core/database/entities.dart';

/// Inventory batch repository implementation - data layer
/// Converts between Drift entities and domain entities
class InventoryBatchRepositoryImpl implements InventoryBatchRepository {
  final InventoryDao _dao;
  final SyncRepository _syncRepo;

  InventoryBatchRepositoryImpl(CarePawDatabase database, {required SyncRepository syncRepo})
      : _dao = InventoryDao(database),
        _syncRepo = syncRepo;

  @override
  Future<InventoryBatch?> findById(int id) async {
    final entity = await _dao.getBatchById(id);
    return entity != null ? _toDomain(entity) : null;
  }

  @override
  Future<List<InventoryBatch>> findAll() async {
    final entities = await _dao.getAllBatches();
    return entities.map(_toDomain).toList();
  }

  @override
  Future<InventoryBatch> save(InventoryBatch entity) async {
    final companion = _toCompanion(entity);
    if (entity.id == null) {
      final id = await _dao.createBatch(companion);
      return entity.copyWith(id: id);
    } else {
      await _dao.updateBatch(companion);
      return entity;
    }
  }

  @override
  Future<void> delete(int id) async {
    await _dao.deleteBatch(id);
  }

  @override
  Future<bool> exists(int id) async {
    final entity = await _dao.getBatchById(id);
    return entity != null;
  }

  @override
  Future<void> softDelete(int id) async {
    await delete(id);
  }

  @override
  Future<void> restore(int id) async {
    throw UnsupportedError('Batches cannot be restored once deleted');
  }

  @override
  Future<List<InventoryBatch>> findAllIncludingDeleted() async {
    return findAll();
  }

  @override
  Stream<InventoryBatch?> watchById(int id) {
    return _dao.watchBatchById(id).map((entity) => entity != null ? _toDomain(entity) : null);
  }

  @override
  Stream<List<InventoryBatch>> watchAll() {
    return _dao.watchAllBatches().map((entities) => entities.map(_toDomain).toList());
  }

  @override
  Future<List<InventoryBatch>> findByItem(int itemId) async {
    final entities = await _dao.getBatchesForItem(itemId);
    return entities.map((e) => _toDomain(e)).toList();
  }

  @override
  Future<List<InventoryBatch>> findExpiring({int days = 30}) async {
    final entities = await _dao.getExpiringBatches(days: days);
    return entities.map((e) => _toDomain(e)).toList();
  }

  @override
  Future<List<InventoryBatch>> findExpired() async {
    final entities = await _dao.getExpiredBatches();
    return entities.map((e) => _toDomain(e)).toList();
  }

  @override
  Future<double> consumeFromBatches(int itemId, double quantity) async {
    return await _dao.consumeFromBatches(itemId, quantity);
  }

  @override
  Future<PaginatedResult<InventoryBatch>> findPaginated(PaginationParams params) async {
    final allBatches = await findAll();
    final start = params.offset;
    final end = (start + params.pageSize).clamp(0, allBatches.length);
    final items = allBatches.sublist(start, end);
    return PaginatedResult(
      items: items,
      totalCount: allBatches.length,
      page: params.page,
      pageSize: params.pageSize,
    );
  }

  @override
  Future<InventoryBatch> create(InventoryBatch batch) async {
    return save(batch);
  }

  @override
  Future<InventoryBatch> update(InventoryBatch batch) async {
    return save(batch);
  }

  // Private mapping methods

  InventoryBatch _toDomain(InventoryBatche entity) {
    return InventoryBatch(
      id: entity.id,
      inventoryId: entity.inventoryId,
      batchNumber: entity.batchNumber,
      quantity: entity.quantity,
      receivedAt: entity.receivedAt,
      expiresAt: entity.expiresAt,
      costPerUnit: entity.costPerUnit,
      supplier: entity.supplier,
      createdAt: entity.createdAt,
    );
  }

  InventoryBatchesCompanion _toCompanion(InventoryBatch entity) {
    return InventoryBatchesCompanion(
      id: entity.id != null ? Value(entity.id!) : const Value.absent(),
      inventoryId: Value(entity.inventoryId),
      batchNumber: Value(entity.batchNumber),
      quantity: Value(entity.quantity),
      receivedAt: Value(entity.receivedAt),
      expiresAt: Value(entity.expiresAt),
      costPerUnit: Value(entity.costPerUnit),
      supplier: Value(entity.supplier),
      createdAt: entity.id == null ? Value(entity.createdAt) : const Value.absent(),
    );
  }

  @override
  Future<InventoryBatch> createWithSync(InventoryBatch entity, String tableName) async {
    final saved = await create(entity);
    if (saved.id != null) {
      final payload = {
        'id': saved.id,
        'inventoryId': entity.inventoryId,
        'batchNumber': entity.batchNumber,
        'quantity': entity.quantity,
        'receivedAt': entity.receivedAt.toIso8601String(),
        'expiresAt': entity.expiresAt?.toIso8601String(),
        'costPerUnit': entity.costPerUnit,
        'supplier': entity.supplier,
        'createdAt': entity.createdAt.toIso8601String(),
      };
      await _syncRepo.queueForSync(
        tableName: tableName,
        recordId: saved.id!,
        operation: SyncOperation.insert,
        payload: payload,
      );
    }
    return saved;
  }

  @override
  Future<InventoryBatch> updateWithSync(InventoryBatch entity, String tableName) async {
    final saved = await save(entity);
    if (saved.id != null) {
      final payload = {
        'id': saved.id,
        'inventoryId': entity.inventoryId,
        'batchNumber': entity.batchNumber,
        'quantity': entity.quantity,
        'receivedAt': entity.receivedAt.toIso8601String(),
        'expiresAt': entity.expiresAt?.toIso8601String(),
        'costPerUnit': entity.costPerUnit,
        'supplier': entity.supplier,
        'createdAt': entity.createdAt.toIso8601String(),
      };
      await _syncRepo.queueForSync(
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
    // Would need a DAO method for delete
    await _syncRepo.queueForSync(
      tableName: tableName,
      recordId: id,
      operation: SyncOperation.delete,
    );
  }
}