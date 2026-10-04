import 'package:equatable/equatable.dart';
import 'package:carepaw/features/inventory/domain/entities/inventory.dart';

/// Base class for all inventory events.
abstract class InventoryEvent extends Equatable {
  const InventoryEvent();

  @override
  List<Object?> get props => [];
}

/// Load all inventory items.
class LoadInventoryItems extends InventoryEvent {
  const LoadInventoryItems();

  @override
  List<Object?> get props => [];
}

/// Load inventory items by category.
class LoadInventoryItemsByCategory extends InventoryEvent {
  final InventoryCategory category;

  const LoadInventoryItemsByCategory(this.category);

  @override
  List<Object?> get props => [category];
}

/// Load low stock items.
class LoadLowStockItems extends InventoryEvent {
  const LoadLowStockItems();

  @override
  List<Object?> get props => [];
}

/// Search inventory items.
class SearchInventoryItems extends InventoryEvent {
  final String query;

  const SearchInventoryItems(this.query);

  @override
  List<Object?> get props => [query];
}

/// Load inventory item details.
class LoadInventoryItemDetails extends InventoryEvent {
  final int itemId;

  const LoadInventoryItemDetails(this.itemId);

  @override
  List<Object?> get props => [itemId];
}

/// Load batches for an item.
class LoadItemBatches extends InventoryEvent {
  final int itemId;

  const LoadItemBatches(this.itemId);

  @override
  List<Object?> get props => [itemId];
}

/// Load expiring batches.
class LoadExpiringBatches extends InventoryEvent {
  final int days;

  const LoadExpiringBatches({this.days = 30});

  @override
  List<Object?> get props => [days];
}

/// Load expired batches.
class LoadExpiredBatches extends InventoryEvent {
  const LoadExpiredBatches();

  @override
  List<Object?> get props => [];
}

/// Create a new inventory item.
class CreateInventoryItem extends InventoryEvent {
  final String name;
  final InventoryCategory category;
  final String unit;
  final double minStock;
  final double? maxStock;
  final double? unitCost;
  final String? supplier;
  final String? location;

  const CreateInventoryItem({
    required this.name,
    required this.category,
    required this.unit,
    this.minStock = 0.0,
    this.maxStock,
    this.unitCost,
    this.supplier,
    this.location,
  });

  @override
  List<Object?> get props => [
    name,
    category,
    unit,
    minStock,
    maxStock,
    unitCost,
    supplier,
    location,
  ];
}

/// Update an inventory item.
class UpdateInventoryItem extends InventoryEvent {
  final int id;
  final String? name;
  final InventoryCategory? category;
  final String? unit;
  final double? minStock;
  final double? maxStock;
  final double? unitCost;
  final String? supplier;
  final String? location;

  const UpdateInventoryItem({
    required this.id,
    this.name,
    this.category,
    this.unit,
    this.minStock,
    this.maxStock,
    this.unitCost,
    this.supplier,
    this.location,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    category,
    unit,
    minStock,
    maxStock,
    unitCost,
    supplier,
    location,
  ];
}

/// Update stock level.
class UpdateStock extends InventoryEvent {
  final int id;
  final double newStock;

  const UpdateStock(this.id, this.newStock);

  @override
  List<Object?> get props => [id, newStock];
}

/// Adjust stock (increment/decrement).
class AdjustStock extends InventoryEvent {
  final int id;
  final double delta;

  const AdjustStock(this.id, this.delta);

  @override
  List<Object?> get props => [id, delta];
}

/// Create a new batch.
class CreateBatch extends InventoryEvent {
  final int inventoryId;
  final String batchNumber;
  final double quantity;
  final DateTime receivedAt;
  final DateTime? expiresAt;
  final double? costPerUnit;
  final String? supplier;

  const CreateBatch({
    required this.inventoryId,
    required this.batchNumber,
    required this.quantity,
    required this.receivedAt,
    this.expiresAt,
    this.costPerUnit,
    this.supplier,
  });

  @override
  List<Object?> get props => [
    inventoryId,
    batchNumber,
    quantity,
    receivedAt,
    expiresAt,
    costPerUnit,
    supplier,
  ];
}

/// Create a stock in transaction.
class CreateStockInTransaction extends InventoryEvent {
  final int batchId;
  final double quantity;
  final String reason;
  final String? referenceType;
  final int? referenceId;
  final int performedBy;
  final String? notes;

  const CreateStockInTransaction({
    required this.batchId,
    required this.quantity,
    required this.reason,
    this.referenceType,
    this.referenceId,
    required this.performedBy,
    this.notes,
  });

  @override
  List<Object?> get props => [
    batchId,
    quantity,
    reason,
    referenceType,
    referenceId,
    performedBy,
    notes,
  ];
}

/// Create a stock out transaction.
class CreateStockOutTransaction extends InventoryEvent {
  final int batchId;
  final double quantity;
  final String reason;
  final String? referenceType;
  final int? referenceId;
  final int performedBy;
  final String? notes;

  const CreateStockOutTransaction({
    required this.batchId,
    required this.quantity,
    required this.reason,
    this.referenceType,
    this.referenceId,
    required this.performedBy,
    this.notes,
  });

  @override
  List<Object?> get props => [
    batchId,
    quantity,
    reason,
    referenceType,
    referenceId,
    performedBy,
    notes,
  ];
}

/// Create an adjustment transaction.
class CreateAdjustmentTransaction extends InventoryEvent {
  final int batchId;
  final double quantityChange;
  final String reason;
  final int performedBy;
  final String? notes;

  const CreateAdjustmentTransaction({
    required this.batchId,
    required this.quantityChange,
    required this.reason,
    required this.performedBy,
    this.notes,
  });

  @override
  List<Object?> get props => [
    batchId,
    quantityChange,
    reason,
    performedBy,
    notes,
  ];
}

/// Load transactions for a batch.
class LoadBatchTransactions extends InventoryEvent {
  final int batchId;

  const LoadBatchTransactions(this.batchId);

  @override
  List<Object?> get props => [batchId];
}
