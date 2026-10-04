import 'package:carepaw/core/repositories/base_repository.dart';
import 'package:carepaw/features/inventory/domain/entities/inventory.dart';

/// Inventory item repository interface - domain layer contract
abstract class InventoryItemRepository
    extends SoftDeleteRepository<InventoryItem, int>
    implements
        StreamRepository<InventoryItem, int>,
        PaginatedRepository<InventoryItem, int> {
  /// Find all items
  @override
  Future<List<InventoryItem>> findAll();

  /// Find items by category
  Future<List<InventoryItem>> findByCategory(InventoryCategory category);

  /// Find low stock items
  Future<List<InventoryItem>> findLowStock();

  /// Search items by name
  Future<List<InventoryItem>> search(String query);

  /// Update stock level
  Future<InventoryItem> updateStock(int id, double newStock);

  /// Adjust stock (increment/decrement)
  Future<InventoryItem> adjustStock(int id, double delta);

  /// Sync-aware operations
  @override
  Future<InventoryItem> createWithSync(InventoryItem entity, String tableName);

  @override
  Future<InventoryItem> updateWithSync(InventoryItem entity, String tableName);

  @override
  Future<void> deleteWithSync(int id, String tableName);
}

/// Inventory batch repository interface - domain layer contract
abstract class InventoryBatchRepository
    extends SoftDeleteRepository<InventoryBatch, int>
    implements
        StreamRepository<InventoryBatch, int>,
        PaginatedRepository<InventoryBatch, int> {
  /// Find batches for an item
  Future<List<InventoryBatch>> findByItem(int itemId);

  /// Find expiring batches
  Future<List<InventoryBatch>> findExpiring({int days = 30});

  /// Find expired batches
  Future<List<InventoryBatch>> findExpired();

  /// Consume from batches (FIFO - use earliest expiring first)
  Future<double> consumeFromBatches(int itemId, double quantity);

  /// Create a new batch
  Future<InventoryBatch> create(InventoryBatch batch);

  /// Update an existing batch
  Future<InventoryBatch> update(InventoryBatch batch);

  /// Sync-aware operations
  @override
  Future<InventoryBatch> createWithSync(
    InventoryBatch entity,
    String tableName,
  );

  @override
  Future<InventoryBatch> updateWithSync(
    InventoryBatch entity,
    String tableName,
  );

  @override
  Future<void> deleteWithSync(int id, String tableName);
}

/// Inventory transaction repository interface - domain layer contract
abstract class InventoryTransactionRepository
    implements
        StreamRepository<InventoryTransaction, int>,
        PaginatedRepository<InventoryTransaction, int>,
        BaseRepository<InventoryTransaction, int> {
  /// Find transactions for a batch
  Future<List<InventoryTransaction>> findByBatch(int batchId);

  /// Find transactions by reference (e.g., prescription, appointment)
  Future<List<InventoryTransaction>> findByReference(
    String referenceType,
    int referenceId,
  );

  /// Create transaction
  Future<InventoryTransaction> create(InventoryTransaction transaction);

  /// Sync-aware operations
  @override
  Future<InventoryTransaction> createWithSync(
    InventoryTransaction entity,
    String tableName,
  );

  @override
  Future<InventoryTransaction> updateWithSync(
    InventoryTransaction entity,
    String tableName,
  );

  @override
  Future<void> deleteWithSync(int id, String tableName);
}
