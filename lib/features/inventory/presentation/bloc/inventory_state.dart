import 'package:equatable/equatable.dart';
import 'package:carepaw/features/inventory/domain/entities/inventory.dart';
import 'package:carepaw/core/errors/failures.dart';

/// Base class for all inventory states.
abstract class InventoryState extends Equatable {
  const InventoryState();

  @override
  List<Object?> get props => [];
}

/// Initial state.
class InventoryInitial extends InventoryState {
  const InventoryInitial();
}

/// Loading state.
class InventoryLoading extends InventoryState {
  const InventoryLoading();
}

/// Inventory items loaded state.
class InventoryItemsLoaded extends InventoryState {
  final List<InventoryItem> items;

  const InventoryItemsLoaded(this.items);

  @override
  List<Object?> get props => [items];
}

/// Inventory items by category loaded state.
class InventoryItemsByCategoryLoaded extends InventoryState {
  final List<InventoryItem> items;
  final InventoryCategory category;

  const InventoryItemsByCategoryLoaded(this.items, this.category);

  @override
  List<Object?> get props => [items, category];
}

/// Low stock items loaded state.
class LowStockItemsLoaded extends InventoryState {
  final List<InventoryItem> items;

  const LowStockItemsLoaded(this.items);

  @override
  List<Object?> get props => [items];
}

/// Search results loaded state.
class InventorySearchResultsLoaded extends InventoryState {
  final List<InventoryItem> items;
  final String query;

  const InventorySearchResultsLoaded(this.items, this.query);

  @override
  List<Object?> get props => [items, query];
}

/// Inventory item details loaded state.
class InventoryItemDetailLoaded extends InventoryState {
  final InventoryItem item;

  const InventoryItemDetailLoaded(this.item);

  @override
  List<Object?> get props => [item];
}

/// Item batches loaded state.
class ItemBatchesLoaded extends InventoryState {
  final List<InventoryBatch> batches;
  final int itemId;

  const ItemBatchesLoaded(this.batches, this.itemId);

  @override
  List<Object?> get props => [batches, itemId];
}

/// Expiring batches loaded state.
class ExpiringBatchesLoaded extends InventoryState {
  final List<InventoryBatch> batches;
  final int days;

  const ExpiringBatchesLoaded(this.batches, this.days);

  @override
  List<Object?> get props => [batches, days];
}

/// Expired batches loaded state.
class ExpiredBatchesLoaded extends InventoryState {
  final List<InventoryBatch> batches;

  const ExpiredBatchesLoaded(this.batches);

  @override
  List<Object?> get props => [batches];
}

/// Batch transactions loaded state.
class BatchTransactionsLoaded extends InventoryState {
  final List<InventoryTransaction> transactions;
  final int batchId;

  const BatchTransactionsLoaded(this.transactions, this.batchId);

  @override
  List<Object?> get props => [transactions, batchId];
}

/// Operation success state.
class InventoryOperationSuccess extends InventoryState {
  final String message;

  const InventoryOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

/// Error state.
class InventoryError extends InventoryState {
  final Failure failure;

  const InventoryError(this.failure);

  @override
  List<Object?> get props => [failure];
}