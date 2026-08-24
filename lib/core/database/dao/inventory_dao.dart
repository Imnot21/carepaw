import 'package:drift/drift.dart';
import 'package:carepaw/core/database/database.dart';
import 'package:carepaw/core/database/tables.dart';

part 'inventory_dao.g.dart';

@DriftAccessor(tables: [InventoryItems, InventoryBatches])
class InventoryDao extends DatabaseAccessor<CarePawDatabase> with _$InventoryDaoMixin {
  InventoryDao(super.db);

  // ============ Items Queries ============

  /// Get item by ID
  Future<InventoryItem?> getItemById(int id) {
    return (select(inventoryItems)..where((i) => i.id.equals(id))).getSingleOrNull();
  }

  /// Get all items
  Future<List<InventoryItem>> getAllItems() {
    return (select(inventoryItems)..orderBy([(i) => OrderingTerm.asc(i.name)])).get();
  }

  /// Get items by category
  Future<List<InventoryItem>> getItemsByCategory(String category) {
    return (select(inventoryItems)
          ..where((i) => i.category.equals(category))
          ..orderBy([(i) => OrderingTerm.asc(i.name)]))
        .get();
  }

  /// Get low stock items
  Future<List<InventoryItem>> getLowStockItems() {
    return (select(inventoryItems)
          ..where((i) => i.currentStock.isSmallerOrEqual(i.minStock))
          ..orderBy([(i) => OrderingTerm.asc(i.currentStock)]))
        .get();
  }

  /// Search items by name
  Future<List<InventoryItem>> searchItems(String query) {
    return (select(inventoryItems)
          ..where((i) => i.name.like('%$query%')))
        .get();
  }

  /// Stream all items
  Stream<List<InventoryItem>> watchAllItems() {
    return (select(inventoryItems)..orderBy([(i) => OrderingTerm.asc(i.name)])).watch();
  }

  /// Stream item by ID
  Stream<InventoryItem?> watchItemById(int id) {
    return (select(inventoryItems)..where((i) => i.id.equals(id))).watchSingleOrNull();
  }

  // ============ Batches Queries ============

  /// Get batches for an item
  Future<List<InventoryBatche>> getBatchesForItem(int itemId) {
    return (select(inventoryBatches)
          ..where((b) => b.inventoryId.equals(itemId))
          ..orderBy([(b) => OrderingTerm.asc(b.expiresAt)]))
        .get();
  }

  /// Stream batches for an item
  Stream<List<InventoryBatche>> watchBatchesForItem(int itemId) {
    return (select(inventoryBatches)
          ..where((b) => b.inventoryId.equals(itemId))
          ..orderBy([(b) => OrderingTerm.asc(b.expiresAt)]))
        .watch();
  }

  /// Get batch by ID
  Future<InventoryBatche?> getBatchById(int id) {
    return (select(inventoryBatches)..where((b) => b.id.equals(id))).getSingleOrNull();
  }

  /// Get all batches
  Future<List<InventoryBatche>> getAllBatches() {
    return (select(inventoryBatches)
          ..orderBy([(b) => OrderingTerm.asc(b.expiresAt)]))
        .get();
  }

  /// Delete batch by ID
  Future<int> deleteBatch(int id) {
    return (delete(inventoryBatches)..where((b) => b.id.equals(id))).go();
  }

  /// Count batches for an item
  Future<int> countBatchesForItem(int itemId) async {
    final query = selectOnly(inventoryBatches)
      ..addColumns([inventoryBatches.id.count()])
      ..where(inventoryBatches.inventoryId.equals(itemId));
    final row = await query.getSingle();
    return row.read(inventoryBatches.id.count()) ?? 0;
  }

  /// Stream batch by ID
  Stream<InventoryBatche?> watchBatchById(int id) {
    return (select(inventoryBatches)..where((b) => b.id.equals(id))).watchSingleOrNull();
  }

  /// Stream all batches
  Stream<List<InventoryBatche>> watchAllBatches() {
    return (select(inventoryBatches)
          ..orderBy([(b) => OrderingTerm.asc(b.expiresAt)]))
        .watch();
  }

  /// Get expiring batches
  Future<List<InventoryBatche>> getExpiringBatches({int days = 30}) {
    final now = DateTime.now();
    final future = now.add(Duration(days: days));
    return (select(inventoryBatches)
          ..where((b) =>
              b.expiresAt.isNotNull() &
              b.expiresAt.isBiggerOrEqualValue(now) &
              b.expiresAt.isSmallerOrEqualValue(future))
          ..orderBy([(b) => OrderingTerm.asc(b.expiresAt)]))
        .get();
  }

  /// Get expired batches
  Future<List<InventoryBatche>> getExpiredBatches() {
    final now = DateTime.now();
    return (select(inventoryBatches)
          ..where((b) =>
              b.expiresAt.isNotNull() &
              b.expiresAt.isSmallerThanValue(now))
          ..orderBy([(b) => OrderingTerm.asc(b.expiresAt)]))
        .get();
  }

  // ============ Mutations ============

  /// Create inventory item
  Future<int> createItem(InventoryItemsCompanion item) {
    return into(inventoryItems).insert(item);
  }

  /// Update inventory item
  Future<bool> updateItem(InventoryItemsCompanion item) {
    return update(inventoryItems).replace(item);
  }

  /// Update stock level
  Future<int> updateStock(int id, double newStock) {
    return (update(inventoryItems)..where((i) => i.id.equals(id)))
        .write(InventoryItemsCompanion(
          currentStock: Value(newStock),
          updatedAt: Value(DateTime.now()),
        ));
  }

  /// Adjust stock (increment/decrement)
  Future<int> adjustStock(int id, double delta) {
    return transaction(() async {
      final item = await getItemById(id);
      if (item == null) return 0;
      final newStock = item.currentStock + delta;
      return updateStock(id, newStock);
    });
  }

  /// Create batch
  Future<int> createBatch(InventoryBatchesCompanion batch) {
    return into(inventoryBatches).insert(batch);
  }

  /// Update batch
  Future<bool> updateBatch(InventoryBatchesCompanion batch) {
    return update(inventoryBatches).replace(batch);
  }

  /// Consume from batch (FIFO - use earliest expiring first)
  Future<double> consumeFromBatches(int itemId, double quantity) async {
    return transaction(() async {
      double remaining = quantity;
      final batches = await getBatchesForItem(itemId);

      for (final batch in batches) {
        if (remaining <= 0) break;

        final available = batch.quantity;
        final toConsume = remaining < available ? remaining : available;

        await (update(inventoryBatches)..where((b) => b.id.equals(batch.id)))
            .write(InventoryBatchesCompanion(quantity: Value(available - toConsume)));

        remaining -= toConsume;
      }

      // Update item stock
      final item = await getItemById(itemId);
      if (item != null) {
        await updateStock(itemId, item.currentStock - (quantity - remaining));
      }

      return quantity - remaining; // Return actual consumed
    });
  }

  /// Soft delete inventory item (mark as inactive - we'll use a workaround since there's no isActive column)
  Future<int> softDeleteItem(int id) {
    // For inventory items, we could add an isActive column or just return 0
    // For now, return 0 to indicate not implemented
    return Future.value(0);
  }
}