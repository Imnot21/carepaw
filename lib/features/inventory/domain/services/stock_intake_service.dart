import 'package:carepaw/core/errors/failures.dart';
import 'package:carepaw/features/inventory/domain/entities/inventory.dart';
import 'package:carepaw/features/inventory/domain/repositories/inventory_repository.dart';

/// One medicine to receive, as checked by a person on the scan review.
class StockLine {
  final String name;
  final double quantity;
  final String unit;
  final String? lot;
  final DateTime? expiresAt;

  const StockLine({
    required this.name,
    required this.quantity,
    required this.unit,
    this.lot,
    this.expiresAt,
  });
}

/// Moves stock in and out so every unit traces to a transaction.
///
/// Receiving adds a batch with an opening stock-in to a matching medicine,
/// or to a new one. Taking out draws from the batches that expire first,
/// with one stock-out per batch touched. The item's stock is kept equal to
/// the sum of its batches. Writes run one after another, like the rest of
/// the inventory code, not in a single Firestore transaction.
class StockIntakeService {
  final InventoryItemRepository _itemRepository;
  final InventoryBatchRepository _batchRepository;
  final InventoryTransactionRepository _transactionRepository;

  StockIntakeService({
    required this._itemRepository,
    required this._batchRepository,
    required this._transactionRepository,
  });

  /// Name used for matching: lower case, letters and digits only, so
  /// "Amoxicillin 250 mg" and "AMOXICILLIN 250MG" are the same medicine
  /// but "Amoxicillin 500mg" is not.
  static String normalize(String name) =>
      name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  /// The stocked medicine with the same name as [name], or null.
  static InventoryItem? match(Iterable<InventoryItem> items, String name) {
    final key = normalize(name);
    if (key.isEmpty) return null;
    for (final item in items) {
      if (normalize(item.name) == key) return item;
    }
    return null;
  }

  /// Adds every line to stock and returns how many were added.
  ///
  /// [referenceType] and [referenceId] name what the stock came from, for
  /// example `SCAN` and the scan record's id.
  Future<int> receive({
    required List<StockLine> lines,
    required int performedBy,
    String? supplier,
    String? referenceType,
    int? referenceId,
  }) async {
    if (lines.isEmpty) {
      throw const RequiredFieldFailure(message: 'Add at least one medicine.');
    }
    for (final line in lines) {
      if (line.name.trim().isEmpty) {
        throw const RequiredFieldFailure(message: 'Every medicine needs a name.');
      }
      if (line.quantity <= 0) {
        throw OutOfRangeFailure(
          message: 'Quantity for ${line.name.trim()} must be more than 0.',
        );
      }
    }

    final known = [...await _itemRepository.findAll()];
    final now = DateTime.now();
    final from = supplier?.trim();

    for (final line in lines) {
      var item = match(known, line.name);
      if (item == null) {
        item = await _itemRepository.save(
          InventoryItem(
            name: line.name.trim(),
            category: InventoryCategory.medicine,
            unit: line.unit.trim().isEmpty ? 'pcs' : line.unit.trim(),
            supplier: from == null || from.isEmpty ? null : from,
            createdAt: now,
            updatedAt: now,
          ),
        );
        known.add(item);
      }

      final lot = line.lot?.trim();
      final batch = await _batchRepository.create(
        InventoryBatch(
          inventoryId: item.id!,
          batchNumber: lot == null || lot.isEmpty ? 'No lot' : lot,
          quantity: line.quantity,
          receivedAt: now,
          expiresAt: line.expiresAt,
          supplier: from == null || from.isEmpty ? null : from,
          createdAt: now,
        ),
      );
      await _transactionRepository.create(
        InventoryTransaction(
          batchId: batch.id!,
          type: TransactionType.in_,
          quantityChange: line.quantity,
          quantityBefore: 0,
          quantityAfter: line.quantity,
          reason: referenceType == 'SCAN'
              ? 'Received from scan'
              : 'Received',
          referenceType: referenceType,
          referenceId: referenceId,
          performedBy: performedBy,
          notes: from == null || from.isEmpty ? null : 'Supplier: $from',
          createdAt: now,
        ),
      );
      final updated = await _itemRepository.updateStock(
        item.id!,
        item.currentStock + line.quantity,
      );
      known[known.indexOf(item)] = updated;
    }
    return lines.length;
  }

  /// Takes [quantity] out of [item], earliest expiry first.
  Future<void> takeOut({
    required InventoryItem item,
    required double quantity,
    required int performedBy,
    String reason = 'Taken out',
  }) async {
    if (quantity <= 0) {
      throw const OutOfRangeFailure(message: 'Take out more than 0.');
    }
    final batches = await _stockedBatches(item.id!);
    final available = batches.fold<double>(0, (sum, b) => sum + b.quantity);
    if (quantity > available) {
      throw InsufficientStockFailure(
        message: 'Only ${_amount(available)} ${item.unit} in stock.',
      );
    }

    var remaining = quantity;
    final now = DateTime.now();
    for (final batch in batches) {
      if (remaining <= 0) break;
      final take = remaining < batch.quantity ? remaining : batch.quantity;
      await _transactionRepository.create(
        InventoryTransaction(
          batchId: batch.id!,
          type: TransactionType.out,
          quantityChange: -take,
          quantityBefore: batch.quantity,
          quantityAfter: batch.quantity - take,
          reason: reason,
          referenceType: 'MANUAL',
          performedBy: performedBy,
          createdAt: now,
        ),
      );
      await _batchRepository.update(
        batch.copyWith(quantity: batch.quantity - take),
      );
      remaining -= take;
    }

    final current = (await _itemRepository.findById(item.id!)) ?? item;
    final left = current.currentStock - quantity;
    await _itemRepository.updateStock(item.id!, left < 0 ? 0 : left);
  }

  /// Takes everything left out of [item] and sets its stock to zero.
  Future<void> markOutOfStock({
    required InventoryItem item,
    required int performedBy,
  }) async {
    final batches = await _stockedBatches(item.id!);
    final available = batches.fold<double>(0, (sum, b) => sum + b.quantity);
    if (available > 0) {
      await takeOut(
        item: item,
        quantity: available,
        performedBy: performedBy,
        reason: 'Ran out',
      );
    }
    await _itemRepository.updateStock(item.id!, 0);
  }

  /// Batches that still hold stock, the one expiring soonest first.
  /// Batches without an expiry go last, oldest received first.
  Future<List<InventoryBatch>> _stockedBatches(int itemId) async {
    final batches = (await _batchRepository.findByItem(
      itemId,
    )).where((b) => b.quantity > 0).toList();
    batches.sort((a, b) {
      final ea = a.expiresAt, eb = b.expiresAt;
      if (ea != null && eb != null && ea != eb) return ea.compareTo(eb);
      if (ea == null && eb != null) return 1;
      if (ea != null && eb == null) return -1;
      return a.receivedAt.compareTo(b.receivedAt);
    });
    return batches;
  }

  static String _amount(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(2);
}
