import 'package:bloc_test/bloc_test.dart';
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
    currentStock: 4,
    createdAt: now,
    updatedAt: now,
  );

  late _MockItems items;
  late _MockBatches batches;
  late _MockTransactions transactions;

  setUpAll(() {
    registerFallbackValue(
      InventoryBatch(
        inventoryId: 0,
        batchNumber: '',
        quantity: 0,
        receivedAt: now,
        createdAt: now,
      ),
    );
    registerFallbackValue(
      InventoryTransaction(
        batchId: 0,
        type: TransactionType.in_,
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
    when(() => batches.create(any())).thenAnswer(
      (inv) async =>
          (inv.positionalArguments.first as InventoryBatch).copyWith(id: 31),
    );
    when(() => transactions.create(any())).thenAnswer(
      (inv) async => inv.positionalArguments.first as InventoryTransaction,
    );
    when(() => items.findById(7)).thenAnswer((_) async => item);
    when(() => items.updateStock(any(), any())).thenAnswer((_) async => item);
    when(() => batches.findByItem(7)).thenAnswer((_) async => []);
  });

  InventoryBloc build() => InventoryBloc(
    itemRepository: items,
    batchRepository: batches,
    transactionRepository: transactions,
  );

  group('CreateBatch', () {
    blocTest<InventoryBloc, InventoryState>(
      'logs an opening stock-in linked to the scan, and adds to stock',
      build: build,
      act: (bloc) => bloc.add(
        CreateBatch(
          inventoryId: 7,
          batchNumber: 'AMX2291',
          quantity: 12,
          receivedAt: now,
          performedBy: 3,
          referenceType: 'SCAN',
          referenceId: 55,
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
        expect(tx.batchId, 31);
        expect(tx.type, TransactionType.in_);
        expect(tx.quantityBefore, 0);
        expect(tx.quantityAfter, 12);
        expect(tx.performedBy, 3);
        expect(tx.referenceType, 'SCAN');
        expect(tx.referenceId, 55);
        verify(() => items.updateStock(7, 16)).called(1);
      },
    );

    blocTest<InventoryBloc, InventoryState>(
      'a manual batch has no scan reference',
      build: build,
      act: (bloc) => bloc.add(
        CreateBatch(
          inventoryId: 7,
          batchNumber: 'B-002',
          quantity: 5,
          receivedAt: now,
          performedBy: 3,
        ),
      ),
      verify: (_) {
        final tx =
            verify(() => transactions.create(captureAny())).captured.single
                as InventoryTransaction;
        expect(tx.referenceType, isNull);
        expect(tx.reason, 'New batch received');
      },
    );
  });
}
