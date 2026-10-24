import 'package:bloc_test/bloc_test.dart';
import 'package:carepaw/core/errors/failures.dart';
import 'package:carepaw/features/inventory/domain/entities/inventory.dart';
import 'package:carepaw/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:carepaw/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:carepaw/features/inventory/presentation/bloc/inventory_event.dart';
import 'package:carepaw/features/inventory/presentation/bloc/inventory_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockItems extends Mock implements InventoryItemRepository {}

class _MockBatches extends Mock implements InventoryBatchRepository {}

class _MockTransactions extends Mock
    implements InventoryTransactionRepository {}

void main() {
  final now = DateTime(2026, 10, 25);
  final item = InventoryItem(
    id: 7,
    name: 'Amoxicillin 250mg',
    category: InventoryCategory.medicine,
    unit: 'bottles',
    currentStock: 10,
    createdAt: now,
    updatedAt: now,
  );
  final batch = InventoryBatch(
    id: 31,
    inventoryId: 7,
    batchNumber: 'AMX2291',
    quantity: 10,
    receivedAt: now,
    createdAt: now,
  );

  late _MockItems items;
  late _MockBatches batches;
  late _MockTransactions transactions;

  setUpAll(() {
    registerFallbackValue(batch);
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
    when(() => batches.findById(31)).thenAnswer((_) async => batch);
    when(() => batches.update(any())).thenAnswer(
      (inv) async => inv.positionalArguments.first as InventoryBatch,
    );
    when(() => batches.findByItem(7)).thenAnswer((_) async => [batch]);
    when(() => transactions.create(any())).thenAnswer(
      (inv) async => inv.positionalArguments.first as InventoryTransaction,
    );
    when(() => items.findById(7)).thenAnswer((_) async => item);
    when(() => items.updateStock(any(), any())).thenAnswer((_) async => item);
  });

  InventoryBloc build() => InventoryBloc(
    itemRepository: items,
    batchRepository: batches,
    transactionRepository: transactions,
  );

  group('CreateStockOutTransaction', () {
    blocTest<InventoryBloc, InventoryState>(
      'taking more than the batch holds is refused and nothing is written',
      build: build,
      act: (bloc) => bloc.add(
        const CreateStockOutTransaction(
          batchId: 31,
          quantity: 11,
          reason: 'Dispensed',
          performedBy: 3,
        ),
      ),
      expect: () => [
        isA<InventoryLoading>(),
        isA<InventoryError>().having(
          (s) => s.failure,
          'failure',
          isA<InsufficientStockFailure>(),
        ),
      ],
      verify: (_) {
        verifyNever(() => transactions.create(any()));
        verifyNever(() => batches.update(any()));
        verifyNever(() => items.updateStock(any(), any()));
      },
    );

    blocTest<InventoryBloc, InventoryState>(
      'a valid stock-out logs before and after, then lowers the batch',
      build: build,
      act: (bloc) => bloc.add(
        const CreateStockOutTransaction(
          batchId: 31,
          quantity: 4,
          reason: 'Dispensed',
          performedBy: 3,
        ),
      ),
      expect: () => [
        isA<InventoryLoading>(),
        isA<InventoryOperationSuccess>(),
        isA<ItemBatchesLoaded>(),
      ],
      verify: (_) {
        final tx =
            verify(() => transactions.create(captureAny())).captured.single
                as InventoryTransaction;
        expect(tx.type, TransactionType.out);
        expect(tx.quantityChange, -4);
        expect(tx.quantityBefore, 10);
        expect(tx.quantityAfter, 6);
        expect(tx.performedBy, 3);
        final saved =
            verify(() => batches.update(captureAny())).captured.single
                as InventoryBatch;
        expect(saved.quantity, 6);
        verify(() => items.updateStock(7, 6)).called(1);
      },
    );
  });
}
