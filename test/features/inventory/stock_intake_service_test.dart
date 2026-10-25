import 'package:carepaw/core/errors/failures.dart';
import 'package:carepaw/features/inventory/domain/entities/inventory.dart';
import 'package:carepaw/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:carepaw/features/inventory/domain/services/stock_intake_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockItems extends Mock implements InventoryItemRepository {}

class _MockBatches extends Mock implements InventoryBatchRepository {}

class _MockTransactions extends Mock
    implements InventoryTransactionRepository {}

void main() {
  final now = DateTime(2026, 10, 25);
  InventoryItem itemOf(int id, String name, double stock) => InventoryItem(
    id: id,
    name: name,
    category: InventoryCategory.medicine,
    unit: 'box',
    currentStock: stock,
    createdAt: now,
    updatedAt: now,
  );
  InventoryBatch batchOf(int id, double qty, {DateTime? expires}) =>
      InventoryBatch(
        id: id,
        inventoryId: 7,
        batchNumber: 'B$id',
        quantity: qty,
        receivedAt: now,
        expiresAt: expires,
        createdAt: now,
      );

  final amox = itemOf(7, 'Amoxicillin 250mg', 10);

  late _MockItems items;
  late _MockBatches batches;
  late _MockTransactions transactions;
  late StockIntakeService service;

  setUpAll(() {
    registerFallbackValue(amox);
    registerFallbackValue(batchOf(0, 0));
    registerFallbackValue(
      InventoryTransaction(
        batchId: 0,
        type: TransactionType.out,
        quantityChange: 0,
        quantityBefore: 0,
        quantityAfter: 0,
        reason: '',
        performedBy: 0,
        createdAt: now,
      ),
    );
  });

  setUp(() {
    items = _MockItems();
    batches = _MockBatches();
    transactions = _MockTransactions();
    service = StockIntakeService(
      itemRepository: items,
      batchRepository: batches,
      transactionRepository: transactions,
    );
    var nextBatchId = 100;
    when(() => batches.create(any())).thenAnswer(
      (inv) async => (inv.positionalArguments.first as InventoryBatch)
          .copyWith(id: nextBatchId++),
    );
    when(() => batches.update(any())).thenAnswer(
      (inv) async => inv.positionalArguments.first as InventoryBatch,
    );
    when(() => transactions.create(any())).thenAnswer(
      (inv) async => inv.positionalArguments.first as InventoryTransaction,
    );
    when(() => items.save(any())).thenAnswer(
      (inv) async =>
          (inv.positionalArguments.first as InventoryItem).copyWith(id: 50),
    );
    when(() => items.updateStock(any(), any())).thenAnswer(
      (inv) async => amox.copyWith(
        id: inv.positionalArguments[0] as int,
        currentStock: inv.positionalArguments[1] as double,
      ),
    );
  });

  group('match', () {
    test('ignores case, spaces and punctuation', () {
      expect(
        StockIntakeService.match([amox], 'AMOXICILLIN 250 MG'),
        same(amox),
      );
    });

    test('a different strength is a different medicine', () {
      expect(StockIntakeService.match([amox], 'Amoxicillin 500mg'), isNull);
    });
  });

  group('receive', () {
    test('adds to a matching medicine and logs a stock-in', () async {
      when(() => items.findAll()).thenAnswer((_) async => [amox]);

      final added = await service.receive(
        lines: [
          StockLine(
            name: 'amoxicillin 250mg',
            quantity: 5,
            unit: 'box',
            lot: 'AMX2291',
            expiresAt: DateTime(2027, 12, 31),
          ),
        ],
        performedBy: 3,
        supplier: 'VetPharma',
        referenceType: 'SCAN',
        referenceId: 12,
      );

      expect(added, 1);
      verifyNever(() => items.save(any()));
      final batch =
          verify(() => batches.create(captureAny())).captured.single
              as InventoryBatch;
      expect(batch.inventoryId, 7);
      expect(batch.batchNumber, 'AMX2291');
      expect(batch.quantity, 5);
      expect(batch.supplier, 'VetPharma');
      final tx =
          verify(() => transactions.create(captureAny())).captured.single
              as InventoryTransaction;
      expect(tx.type, TransactionType.in_);
      expect(tx.quantityChange, 5);
      expect(tx.referenceType, 'SCAN');
      expect(tx.referenceId, 12);
      expect(tx.performedBy, 3);
      verify(() => items.updateStock(7, 15)).called(1);
    });

    test('creates a new medicine when none matches', () async {
      when(() => items.findAll()).thenAnswer((_) async => [amox]);

      await service.receive(
        lines: const [StockLine(name: 'Meloxicam 1.5mg', quantity: 2, unit: '')],
        performedBy: 3,
      );

      final created =
          verify(() => items.save(captureAny())).captured.single
              as InventoryItem;
      expect(created.name, 'Meloxicam 1.5mg');
      expect(created.unit, 'pcs');
      expect(created.category, InventoryCategory.medicine);
      verify(() => items.updateStock(50, 2)).called(1);
    });

    test('refuses a line with no quantity and writes nothing', () async {
      expect(
        service.receive(
          lines: const [StockLine(name: 'Amoxicillin', quantity: 0, unit: 'box')],
          performedBy: 3,
        ),
        throwsA(isA<OutOfRangeFailure>()),
      );
      verifyNever(() => batches.create(any()));
    });
  });

  group('takeOut', () {
    test('draws from the batch that expires first', () async {
      when(() => batches.findByItem(7)).thenAnswer(
        (_) async => [
          batchOf(1, 6, expires: DateTime(2028, 1, 1)),
          batchOf(2, 4, expires: DateTime(2027, 1, 1)),
        ],
      );
      when(() => items.findById(7)).thenAnswer((_) async => amox);

      await service.takeOut(item: amox, quantity: 7, performedBy: 3);

      final saved = verify(
        () => batches.update(captureAny()),
      ).captured.cast<InventoryBatch>();
      expect(saved.map((b) => b.id), [2, 1]);
      expect(saved.map((b) => b.quantity), [0, 3]);
      final txs = verify(
        () => transactions.create(captureAny()),
      ).captured.cast<InventoryTransaction>();
      expect(txs.map((t) => t.quantityChange), [-4, -3]);
      expect(txs.every((t) => t.type == TransactionType.out), isTrue);
      verify(() => items.updateStock(7, 3)).called(1);
    });

    test('refuses to take more than is in stock', () async {
      when(() => batches.findByItem(7)).thenAnswer((_) async => [batchOf(1, 2)]);

      expect(
        service.takeOut(item: amox, quantity: 3, performedBy: 3),
        throwsA(isA<InsufficientStockFailure>()),
      );
      verifyNever(() => transactions.create(any()));
    });

    test('out of stock empties every batch and sets stock to zero', () async {
      when(() => batches.findByItem(7)).thenAnswer(
        (_) async => [batchOf(1, 6), batchOf(2, 4)],
      );
      when(() => items.findById(7)).thenAnswer((_) async => amox);

      await service.markOutOfStock(item: amox, performedBy: 3);

      final saved = verify(
        () => batches.update(captureAny()),
      ).captured.cast<InventoryBatch>();
      expect(saved.every((b) => b.quantity == 0), isTrue);
      verify(() => items.updateStock(7, 0)).called(2);
    });
  });
}
