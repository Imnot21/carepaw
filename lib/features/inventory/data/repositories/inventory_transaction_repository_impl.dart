import 'package:drift/drift.dart';
import 'package:carepaw/core/database/database.dart';
import 'package:carepaw/core/sync/sync_repository.dart';
import 'package:carepaw/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:carepaw/features/inventory/domain/entities/inventory.dart' as domain;
import 'package:carepaw/core/repositories/base_repository.dart';

/// Inventory transaction repository implementation - data layer
/// Converts between Drift entities and domain entities
class InventoryTransactionRepositoryImpl implements InventoryTransactionRepository {
  final CarePawDatabase _database;
  final SyncRepository syncRepo;

  InventoryTransactionRepositoryImpl(this._database, {required this.syncRepo});

  @override
  Future<domain.InventoryTransaction?> findById(int id) async {
    final entity = await (_database.select(_database.inventoryTransactions)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return entity != null ? _toDomain(entity) : null;
  }

  @override
  Future<List<domain.InventoryTransaction>> findAll() async {
    final entities = await (_database.select(_database.inventoryTransactions)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
    return entities.map(_toDomain).toList();
  }

  @override
  Future<domain.InventoryTransaction> save(domain.InventoryTransaction entity) async {
    final companion = _toCompanion(entity);
    if (entity.id == null) {
      final id = await _database.into(_database.inventoryTransactions).insert(companion);
      return entity.copyWith(id: id);
    } else {
      await _database.update(_database.inventoryTransactions).replace(companion);
      return entity;
    }
  }

  @override
  Future<void> delete(int id) async {
    // Inventory transactions should not be deleted - use adjustment instead
    throw UnsupportedError('Inventory transactions cannot be deleted - use adjustment instead');
  }

  @override
  Future<bool> exists(int id) async {
    final entity = await findById(id);
    return entity != null;
  }

  @override
  Stream<domain.InventoryTransaction?> watchById(int id) {
    return (_database.select(_database.inventoryTransactions)
          ..where((t) => t.id.equals(id)))
        .watchSingleOrNull()
        .map((entity) => entity != null ? _toDomain(entity) : null);
  }

  @override
  Stream<List<domain.InventoryTransaction>> watchAll() {
    return (_database.select(_database.inventoryTransactions)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch()
        .map((entities) => entities.map(_toDomain).toList());
  }

  @override
  Future<List<domain.InventoryTransaction>> findByBatch(int batchId) async {
    final entities = await (_database.select(_database.inventoryTransactions)
          ..where((t) => t.batchId.equals(batchId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
    return entities.map(_toDomain).toList();
  }

  @override
  Future<List<domain.InventoryTransaction>> findByReference(String referenceType, int referenceId) async {
    final entities = await (_database.select(_database.inventoryTransactions)
          ..where((t) => (t.referenceType.equals(referenceType) & t.referenceId.equals(referenceId)))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
    return entities.map(_toDomain).toList();
  }

  @override
  Future<domain.InventoryTransaction> create(domain.InventoryTransaction transaction) async {
    final companion = _toCompanion(transaction);
    final id = await _database.into(_database.inventoryTransactions).insert(companion);
    return transaction.copyWith(id: id);
  }

  @override
  Future<PaginatedResult<domain.InventoryTransaction>> findPaginated(PaginationParams params) async {
    final allTransactions = await findAll();
    final start = params.offset;
    final end = (start + params.pageSize).clamp(0, allTransactions.length);
    final items = allTransactions.sublist(start, end);
    return PaginatedResult(
      items: items,
      totalCount: allTransactions.length,
      page: params.page,
      pageSize: params.pageSize,
    );
  }

  // Private mapping methods

  domain.InventoryTransaction _toDomain(InventoryTransaction entity) {
    return domain.InventoryTransaction(
      id: entity.id,
      batchId: entity.batchId,
      type: domain.TransactionType.fromString(entity.type),
      quantityChange: entity.quantityChange,
      quantityBefore: entity.quantityBefore,
      quantityAfter: entity.quantityAfter,
      reason: entity.reason,
      referenceType: entity.referenceType,
      referenceId: entity.referenceId,
      performedBy: entity.performedBy,
      notes: entity.notes,
      createdAt: entity.createdAt,
    );
  }

  InventoryTransactionsCompanion _toCompanion(domain.InventoryTransaction entity) {
    return InventoryTransactionsCompanion(
      id: entity.id != null ? Value(entity.id!) : const Value.absent(),
      batchId: Value(entity.batchId),
      type: Value(entity.type.value),
      quantityChange: Value(entity.quantityChange),
      quantityBefore: Value(entity.quantityBefore),
      quantityAfter: Value(entity.quantityAfter),
      reason: Value(entity.reason),
      referenceType: Value(entity.referenceType),
      referenceId: Value(entity.referenceId),
      performedBy: Value(entity.performedBy),
      notes: Value(entity.notes),
      createdAt: entity.id == null ? Value(entity.createdAt) : const Value.absent(),
    );
  }

  @override
  Future<domain.InventoryTransaction> createWithSync(domain.InventoryTransaction entity, String tableName) async {
    final saved = await create(entity);
    if (saved.id != null) {
      final payload = {
        'id': saved.id,
        'batchId': entity.batchId,
        'type': entity.type.value,
        'quantityChange': entity.quantityChange,
        'quantityBefore': entity.quantityBefore,
        'quantityAfter': entity.quantityAfter,
        'reason': entity.reason,
        'referenceType': entity.referenceType,
        'referenceId': entity.referenceId,
        'performedBy': entity.performedBy,
        'notes': entity.notes,
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
  Future<domain.InventoryTransaction> updateWithSync(domain.InventoryTransaction entity, String tableName) async {
    final saved = await save(entity);
    if (saved.id != null) {
      final payload = {
        'id': saved.id,
        'batchId': entity.batchId,
        'type': entity.type.value,
        'quantityChange': entity.quantityChange,
        'quantityBefore': entity.quantityBefore,
        'quantityAfter': entity.quantityAfter,
        'reason': entity.reason,
        'referenceType': entity.referenceType,
        'referenceId': entity.referenceId,
        'performedBy': entity.performedBy,
        'notes': entity.notes,
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
    // Inventory transactions cannot be deleted
    await syncRepo.queueForSync(
      tableName: tableName,
      recordId: id,
      operation: SyncOperation.delete,
    );
  }
}