import 'package:drift/drift.dart' show Value;
import 'package:carepaw/core/database/database.dart';
import 'package:carepaw/core/database/dao/inventory_dao.dart';
import 'package:carepaw/core/sync/sync_repository.dart';
import 'package:carepaw/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:carepaw/features/inventory/domain/entities/inventory.dart' as domain;
import 'package:carepaw/core/repositories/base_repository.dart';
import 'package:carepaw/core/database/entities.dart';

/// Inventory item repository implementation - data layer
/// Converts between Drift entities and domain entities
class InventoryItemRepositoryImpl implements InventoryItemRepository {
  final InventoryDao _dao;
  final SyncRepository _syncRepo;

  InventoryItemRepositoryImpl(CarePawDatabase database, {required SyncRepository syncRepo})
      : _dao = InventoryDao(database),
        _syncRepo = syncRepo;

  @override
  Future<domain.InventoryItem?> findById(int id) async {
    final entity = await _dao.getItemById(id);
    return entity != null ? _toDomain(entity) : null;
  }

  @override
  Future<List<domain.InventoryItem>> findAll() async {
    final entities = await _dao.getAllItems();
    return entities.map(_toDomain).toList();
  }

  @override
  Future<domain.InventoryItem> save(domain.InventoryItem entity) async {
    final companion = _toCompanion(entity);
    if (entity.id == null) {
      final id = await _dao.createItem(companion);
      return entity.copyWith(id: id);
    } else {
      await _dao.updateItem(companion);
      return entity;
    }
  }

  @override
  Future<void> delete(int id) async {
    await _dao.softDeleteItem(id);
  }

  @override
  Future<bool> exists(int id) async {
    final entity = await _dao.getItemById(id);
    return entity != null;
  }

  @override
  Future<void> softDelete(int id) async {
    await _dao.softDeleteItem(id);
  }

  @override
  Future<void> restore(int id) async {
    // Inventory items don't have soft delete implemented in DAO yet
    // For now, we just return - a proper implementation would need an isActive column
    return;
  }

  @override
  Future<List<domain.InventoryItem>> findAllIncludingDeleted() async {
    return findAll();
  }

  @override
  Stream<domain.InventoryItem?> watchById(int id) {
    return _dao.watchItemById(id).map((entity) => entity != null ? _toDomain(entity) : null);
  }

  @override
  Stream<List<domain.InventoryItem>> watchAll() {
    return _dao.watchAllItems().map((entities) => entities.map(_toDomain).toList());
  }

  @override
  Future<List<domain.InventoryItem>> findByCategory(domain.InventoryCategory category) async {
    final entities = await _dao.getItemsByCategory(category.value);
    return entities.map(_toDomain).toList();
  }

  @override
  Future<List<domain.InventoryItem>> findLowStock() async {
    final entities = await _dao.getLowStockItems();
    return entities.map(_toDomain).toList();
  }

  @override
  Future<List<domain.InventoryItem>> search(String query) async {
    final entities = await _dao.searchItems(query);
    return entities.map(_toDomain).toList();
  }

  @override
  Future<domain.InventoryItem> updateStock(int id, double newStock) async {
    await _dao.updateStock(id, newStock);
    final entity = await _dao.getItemById(id);
    if (entity == null) {
      throw Exception('Inventory item not found');
    }
    return _toDomain(entity);
  }

  @override
  Future<domain.InventoryItem> adjustStock(int id, double delta) async {
    await _dao.adjustStock(id, delta);
    final entity = await _dao.getItemById(id);
    if (entity == null) {
      throw Exception('Inventory item not found');
    }
    return _toDomain(entity);
  }

  @override
  Future<PaginatedResult<domain.InventoryItem>> findPaginated(PaginationParams params) async {
    final allItems = await findAll();
    final start = params.offset;
    final end = (start + params.pageSize).clamp(0, allItems.length);
    final items = allItems.sublist(start, end);
    return PaginatedResult(
      items: items,
      totalCount: allItems.length,
      page: params.page,
      pageSize: params.pageSize,
    );
  }

  // Private mapping methods

  domain.InventoryItem _toDomain(InventoryItem entity) {
    return domain.InventoryItem(
      id: entity.id,
      name: entity.name,
      category: domain.InventoryCategory.fromString(entity.category),
      unit: entity.unit,
      currentStock: entity.currentStock,
      minStock: entity.minStock,
      maxStock: entity.maxStock,
      unitCost: entity.unitCost,
      supplier: entity.supplier,
      location: entity.location,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  InventoryItemsCompanion _toCompanion(domain.InventoryItem entity) {
    return InventoryItemsCompanion(
      id: entity.id != null ? Value(entity.id!) : const Value.absent(),
      name: Value(entity.name),
      category: Value(entity.category.value),
      unit: Value(entity.unit),
      currentStock: Value(entity.currentStock),
      minStock: Value(entity.minStock),
      maxStock: Value(entity.maxStock),
      unitCost: Value(entity.unitCost),
      supplier: Value(entity.supplier),
      location: Value(entity.location),
      createdAt: entity.id == null ? Value(entity.createdAt) : const Value.absent(),
      updatedAt: Value(entity.updatedAt),
    );
  }

  @override
  Future<domain.InventoryItem> createWithSync(domain.InventoryItem entity, String tableName) async {
    final saved = await save(entity);
    if (saved.id != null) {
      final payload = {
        'id': saved.id,
        'name': entity.name,
        'category': entity.category.value,
        'unit': entity.unit,
        'currentStock': entity.currentStock,
        'minStock': entity.minStock,
        'maxStock': entity.maxStock,
        'unitCost': entity.unitCost,
        'supplier': entity.supplier,
        'location': entity.location,
        'createdAt': entity.createdAt.toIso8601String(),
        'updatedAt': entity.updatedAt.toIso8601String(),
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
  Future<domain.InventoryItem> updateWithSync(domain.InventoryItem entity, String tableName) async {
    final saved = await save(entity);
    if (saved.id != null) {
      final payload = {
        'id': saved.id,
        'name': entity.name,
        'category': entity.category.value,
        'unit': entity.unit,
        'currentStock': entity.currentStock,
        'minStock': entity.minStock,
        'maxStock': entity.maxStock,
        'unitCost': entity.unitCost,
        'supplier': entity.supplier,
        'location': entity.location,
        'createdAt': entity.createdAt.toIso8601String(),
        'updatedAt': entity.updatedAt.toIso8601String(),
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
    await _dao.softDeleteItem(id);
    await _syncRepo.queueForSync(
      tableName: tableName,
      recordId: id,
      operation: SyncOperation.delete,
    );
  }
}