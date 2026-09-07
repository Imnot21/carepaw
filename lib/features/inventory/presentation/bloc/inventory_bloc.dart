import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carepaw/features/inventory/domain/entities/inventory.dart';
import 'package:carepaw/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:carepaw/features/inventory/presentation/bloc/inventory_event.dart' as events;
import 'package:carepaw/features/inventory/presentation/bloc/inventory_state.dart' as states;
import 'package:carepaw/core/errors/failures.dart';

/// Inventory BLoC for managing inventory state.
///
/// Handles loading, creating, updating inventory items, batches, and transactions.
class InventoryBloc
    extends Bloc<events.InventoryEvent, states.InventoryState> {
  final InventoryItemRepository _itemRepository;
  final InventoryBatchRepository _batchRepository;
  final InventoryTransactionRepository _transactionRepository;

  InventoryBloc({
    required InventoryItemRepository itemRepository,
    required InventoryBatchRepository batchRepository,
    required InventoryTransactionRepository transactionRepository,
  })  : _itemRepository = itemRepository,
        _batchRepository = batchRepository,
        _transactionRepository = transactionRepository,
        super(const states.InventoryInitial()) {
    on<events.LoadInventoryItems>(_onLoadInventoryItems);
    on<events.LoadInventoryItemsByCategory>(_onLoadInventoryItemsByCategory);
    on<events.LoadLowStockItems>(_onLoadLowStockItems);
    on<events.SearchInventoryItems>(_onSearchInventoryItems);
    on<events.LoadInventoryItemDetails>(_onLoadInventoryItemDetails);
    on<events.LoadItemBatches>(_onLoadItemBatches);
    on<events.LoadExpiringBatches>(_onLoadExpiringBatches);
    on<events.LoadExpiredBatches>(_onLoadExpiredBatches);
    on<events.CreateInventoryItem>(_onCreateInventoryItem);
    on<events.UpdateInventoryItem>(_onUpdateInventoryItem);
    on<events.UpdateStock>(_onUpdateStock);
    on<events.AdjustStock>(_onAdjustStock);
    on<events.CreateBatch>(_onCreateBatch);
    on<events.CreateStockInTransaction>(_onCreateStockInTransaction);
    on<events.CreateStockOutTransaction>(_onCreateStockOutTransaction);
    on<events.CreateAdjustmentTransaction>(_onCreateAdjustmentTransaction);
    on<events.LoadBatchTransactions>(_onLoadBatchTransactions);
  }

  /// Load all inventory items
  Future<void> _onLoadInventoryItems(
    events.LoadInventoryItems event,
    Emitter<states.InventoryState> emit,
  ) async {
    emit(const states.InventoryLoading());
    try {
      final items = await _itemRepository.findAll();
      emit(states.InventoryItemsLoaded(items));
    } on Failure catch (failure) {
      emit(states.InventoryError(failure));
    } catch (e) {
      emit(states.InventoryError(UnexpectedFailure(message: e.toString())));
    }
  }

  /// Load inventory items by category
  Future<void> _onLoadInventoryItemsByCategory(
    events.LoadInventoryItemsByCategory event,
    Emitter<states.InventoryState> emit,
  ) async {
    emit(const states.InventoryLoading());
    try {
      final items = await _itemRepository.findByCategory(event.category);
      emit(states.InventoryItemsByCategoryLoaded(items, event.category));
    } on Failure catch (failure) {
      emit(states.InventoryError(failure));
    } catch (e) {
      emit(states.InventoryError(UnexpectedFailure(message: e.toString())));
    }
  }

  /// Load low stock items
  Future<void> _onLoadLowStockItems(
    events.LoadLowStockItems event,
    Emitter<states.InventoryState> emit,
  ) async {
    emit(const states.InventoryLoading());
    try {
      final items = await _itemRepository.findLowStock();
      emit(states.LowStockItemsLoaded(items));
    } on Failure catch (failure) {
      emit(states.InventoryError(failure));
    } catch (e) {
      emit(states.InventoryError(UnexpectedFailure(message: e.toString())));
    }
  }

  /// Search inventory items
  Future<void> _onSearchInventoryItems(
    events.SearchInventoryItems event,
    Emitter<states.InventoryState> emit,
  ) async {
    emit(const states.InventoryLoading());
    try {
      final items = await _itemRepository.search(event.query);
      emit(states.InventorySearchResultsLoaded(items, event.query));
    } on Failure catch (failure) {
      emit(states.InventoryError(failure));
    } catch (e) {
      emit(states.InventoryError(UnexpectedFailure(message: e.toString())));
    }
  }

  /// Load inventory item details
  Future<void> _onLoadInventoryItemDetails(
    events.LoadInventoryItemDetails event,
    Emitter<states.InventoryState> emit,
  ) async {
    emit(const states.InventoryLoading());
    try {
      final item = await _itemRepository.findById(event.itemId);
      if (item != null) {
        emit(states.InventoryItemDetailLoaded(item));
      } else {
        emit(const states.InventoryError(NotFoundFailure(
          message: 'Inventory item not found',
        )));
      }
    } on Failure catch (failure) {
      emit(states.InventoryError(failure));
    } catch (e) {
      emit(states.InventoryError(UnexpectedFailure(message: e.toString())));
    }
  }

  /// Load item batches
  Future<void> _onLoadItemBatches(
    events.LoadItemBatches event,
    Emitter<states.InventoryState> emit,
  ) async {
    emit(const states.InventoryLoading());
    try {
      final batches = await _batchRepository.findByItem(event.itemId);
      emit(states.ItemBatchesLoaded(batches, event.itemId));
    } on Failure catch (failure) {
      emit(states.InventoryError(failure));
    } catch (e) {
      emit(states.InventoryError(UnexpectedFailure(message: e.toString())));
    }
  }

  /// Load expiring batches
  Future<void> _onLoadExpiringBatches(
    events.LoadExpiringBatches event,
    Emitter<states.InventoryState> emit,
  ) async {
    emit(const states.InventoryLoading());
    try {
      final batches = await _batchRepository.findExpiring(days: event.days);
      emit(states.ExpiringBatchesLoaded(batches, event.days));
    } on Failure catch (failure) {
      emit(states.InventoryError(failure));
    } catch (e) {
      emit(states.InventoryError(UnexpectedFailure(message: e.toString())));
    }
  }

  /// Load expired batches
  Future<void> _onLoadExpiredBatches(
    events.LoadExpiredBatches event,
    Emitter<states.InventoryState> emit,
  ) async {
    emit(const states.InventoryLoading());
    try {
      final batches = await _batchRepository.findExpired();
      emit(states.ExpiredBatchesLoaded(batches));
    } on Failure catch (failure) {
      emit(states.InventoryError(failure));
    } catch (e) {
      emit(states.InventoryError(UnexpectedFailure(message: e.toString())));
    }
  }

  /// Create inventory item
  Future<void> _onCreateInventoryItem(
    events.CreateInventoryItem event,
    Emitter<states.InventoryState> emit,
  ) async {
    emit(const states.InventoryLoading());
    try {
      final item = InventoryItem(
        id: null,
        name: event.name,
        category: event.category,
        unit: event.unit,
        currentStock: 0.0,
        minStock: event.minStock,
        maxStock: event.maxStock,
        unitCost: event.unitCost,
        supplier: event.supplier,
        location: event.location,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _itemRepository.save(item);
      emit(const states.InventoryOperationSuccess('Inventory item created successfully'));
      // Reload items
      final items = await _itemRepository.findAll();
      emit(states.InventoryItemsLoaded(items));
    } on Failure catch (failure) {
      emit(states.InventoryError(failure));
    } catch (e) {
      emit(states.InventoryError(UnexpectedFailure(message: e.toString())));
    }
  }

  /// Update inventory item
  Future<void> _onUpdateInventoryItem(
    events.UpdateInventoryItem event,
    Emitter<states.InventoryState> emit,
  ) async {
    emit(const states.InventoryLoading());
    try {
      final existingItem = await _itemRepository.findById(event.id);
      if (existingItem == null) {
        emit(const states.InventoryError(NotFoundFailure(
          message: 'Inventory item not found',
        )));
        return;
      }
      final updatedItem = existingItem.copyWith(
        name: event.name,
        category: event.category,
        unit: event.unit,
        minStock: event.minStock,
        maxStock: event.maxStock,
        unitCost: event.unitCost,
        supplier: event.supplier,
        location: event.location,
        updatedAt: DateTime.now(),
      );
      await _itemRepository.save(updatedItem);
      emit(const states.InventoryOperationSuccess('Inventory item updated successfully'));
      final items = await _itemRepository.findAll();
      emit(states.InventoryItemsLoaded(items));
    } on Failure catch (failure) {
      emit(states.InventoryError(failure));
    } catch (e) {
      emit(states.InventoryError(UnexpectedFailure(message: e.toString())));
    }
  }

  /// Update stock level
  Future<void> _onUpdateStock(
    events.UpdateStock event,
    Emitter<states.InventoryState> emit,
  ) async {
    emit(const states.InventoryLoading());
    try {
      await _itemRepository.updateStock(event.id, event.newStock);
      emit(const states.InventoryOperationSuccess('Stock updated successfully'));
      final items = await _itemRepository.findAll();
      emit(states.InventoryItemsLoaded(items));
    } on Failure catch (failure) {
      emit(states.InventoryError(failure));
    } catch (e) {
      emit(states.InventoryError(UnexpectedFailure(message: e.toString())));
    }
  }

  /// Adjust stock
  Future<void> _onAdjustStock(
    events.AdjustStock event,
    Emitter<states.InventoryState> emit,
  ) async {
    emit(const states.InventoryLoading());
    try {
      await _itemRepository.adjustStock(event.id, event.delta);
      emit(const states.InventoryOperationSuccess('Stock adjusted successfully'));
      final items = await _itemRepository.findAll();
      emit(states.InventoryItemsLoaded(items));
    } on Failure catch (failure) {
      emit(states.InventoryError(failure));
    } catch (e) {
      emit(states.InventoryError(UnexpectedFailure(message: e.toString())));
    }
  }

  /// Create batch
  Future<void> _onCreateBatch(
    events.CreateBatch event,
    Emitter<states.InventoryState> emit,
  ) async {
    emit(const states.InventoryLoading());
    try {
      final batch = InventoryBatch(
        id: null,
        inventoryId: event.inventoryId,
        batchNumber: event.batchNumber,
        quantity: event.quantity,
        receivedAt: event.receivedAt,
        expiresAt: event.expiresAt,
        costPerUnit: event.costPerUnit,
        supplier: event.supplier,
        createdAt: DateTime.now(),
      );
      await _batchRepository.create(batch);
      emit(const states.InventoryOperationSuccess('Batch created successfully'));
      final batches = await _batchRepository.findByItem(event.inventoryId);
      emit(states.ItemBatchesLoaded(batches, event.inventoryId));
    } on Failure catch (failure) {
      emit(states.InventoryError(failure));
    } catch (e) {
      emit(states.InventoryError(UnexpectedFailure(message: e.toString())));
    }
  }

  /// Create stock in transaction
  Future<void> _onCreateStockInTransaction(
    events.CreateStockInTransaction event,
    Emitter<states.InventoryState> emit,
  ) async {
    emit(const states.InventoryLoading());
    try {
      // Get current batch quantity
      final batch = await _batchRepository.findById(event.batchId);
      if (batch == null) {
        emit(const states.InventoryError(NotFoundFailure(
          message: 'Batch not found',
        )));
        return;
      }

      final transaction = InventoryTransaction(
        id: null,
        batchId: event.batchId,
        type: TransactionType.in_,
        quantityChange: event.quantity,
        quantityBefore: batch.quantity,
        quantityAfter: batch.quantity + event.quantity,
        reason: event.reason,
        referenceType: event.referenceType,
        referenceId: event.referenceId,
        performedBy: event.performedBy,
        notes: event.notes,
        createdAt: DateTime.now(),
      );
      await _transactionRepository.create(transaction);
      // Update batch quantity
      await _batchRepository.update(batch.copyWith(
        quantity: batch.quantity + event.quantity,
      ));
      emit(const states.InventoryOperationSuccess('Stock in recorded successfully'));
      final batches = await _batchRepository.findByItem(batch.inventoryId);
      emit(states.ItemBatchesLoaded(batches, batch.inventoryId));
    } on Failure catch (failure) {
      emit(states.InventoryError(failure));
    } catch (e) {
      emit(states.InventoryError(UnexpectedFailure(message: e.toString())));
    }
  }

  /// Create stock out transaction
  Future<void> _onCreateStockOutTransaction(
    events.CreateStockOutTransaction event,
    Emitter<states.InventoryState> emit,
  ) async {
    emit(const states.InventoryLoading());
    try {
      final batch = await _batchRepository.findById(event.batchId);
      if (batch == null) {
        emit(const states.InventoryError(NotFoundFailure(
          message: 'Batch not found',
        )));
        return;
      }

      if (batch.quantity < event.quantity) {
        emit(states.InventoryError(InsufficientStockFailure(
          message: 'Insufficient stock in batch (available: ${batch.quantity}, requested: ${event.quantity})',
        )));
        return;
      }

      final transaction = InventoryTransaction(
        id: null,
        batchId: event.batchId,
        type: TransactionType.out,
        quantityChange: -event.quantity,
        quantityBefore: batch.quantity,
        quantityAfter: batch.quantity - event.quantity,
        reason: event.reason,
        referenceType: event.referenceType,
        referenceId: event.referenceId,
        performedBy: event.performedBy,
        notes: event.notes,
        createdAt: DateTime.now(),
      );
      await _transactionRepository.create(transaction);
      await _batchRepository.update(batch.copyWith(
        quantity: batch.quantity - event.quantity,
      ));
      emit(const states.InventoryOperationSuccess('Stock out recorded successfully'));
      final batches = await _batchRepository.findByItem(batch.inventoryId);
      emit(states.ItemBatchesLoaded(batches, batch.inventoryId));
    } on Failure catch (failure) {
      emit(states.InventoryError(failure));
    } catch (e) {
      emit(states.InventoryError(UnexpectedFailure(message: e.toString())));
    }
  }

  /// Create adjustment transaction
  Future<void> _onCreateAdjustmentTransaction(
    events.CreateAdjustmentTransaction event,
    Emitter<states.InventoryState> emit,
  ) async {
    emit(const states.InventoryLoading());
    try {
      final batch = await _batchRepository.findById(event.batchId);
      if (batch == null) {
        emit(const states.InventoryError(NotFoundFailure(
          message: 'Batch not found',
        )));
        return;
      }

      final newQuantity = batch.quantity + event.quantityChange;
      if (newQuantity < 0) {
        emit(states.InventoryError(OutOfRangeFailure(
          message: 'Adjustment would result in negative quantity',
        )));
        return;
      }

      final transaction = InventoryTransaction(
        id: null,
        batchId: event.batchId,
        type: TransactionType.adjustment,
        quantityChange: event.quantityChange,
        quantityBefore: batch.quantity,
        quantityAfter: newQuantity,
        reason: event.reason,
        referenceType: 'ADJUSTMENT',
        referenceId: null,
        performedBy: event.performedBy,
        notes: event.notes,
        createdAt: DateTime.now(),
      );
      await _transactionRepository.create(transaction);
      await _batchRepository.update(batch.copyWith(
        quantity: newQuantity,
      ));
      emit(const states.InventoryOperationSuccess('Adjustment recorded successfully'));
      final batches = await _batchRepository.findByItem(batch.inventoryId);
      emit(states.ItemBatchesLoaded(batches, batch.inventoryId));
    } on Failure catch (failure) {
      emit(states.InventoryError(failure));
    } catch (e) {
      emit(states.InventoryError(UnexpectedFailure(message: e.toString())));
    }
  }

  /// Load batch transactions
  Future<void> _onLoadBatchTransactions(
    events.LoadBatchTransactions event,
    Emitter<states.InventoryState> emit,
  ) async {
    emit(const states.InventoryLoading());
    try {
      final transactions = await _transactionRepository.findByBatch(event.batchId);
      emit(states.BatchTransactionsLoaded(transactions, event.batchId));
    } on Failure catch (failure) {
      emit(states.InventoryError(failure));
    } catch (e) {
      emit(states.InventoryError(UnexpectedFailure(message: e.toString())));
    }
  }
}