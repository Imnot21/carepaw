import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carepaw/core/firebase/firestore_id_sequence.dart';
import 'package:carepaw/core/firebase/firestore_schema.dart';
import 'package:carepaw/core/repositories/base_repository.dart';
import 'package:carepaw/features/inventory/data/mappers/inventory_transaction_doc_mapper.dart';
import 'package:carepaw/features/inventory/domain/entities/inventory.dart';
import 'package:carepaw/features/inventory/domain/repositories/inventory_repository.dart';

/// Inventory transaction repository implementation - data layer
/// (Firestore-backed).
///
/// Implements [InventoryTransactionRepository] with Cloud Firestore's
/// `inventoryTransactions` collection as the source of truth. Documents are
/// keyed by the app-facing integer `id` (string form). Transactions are
/// append-only audit records of every inventory movement.
///
/// The former Drift repository is intentionally set aside and no longer wired.
class FirestoreInventoryTransactionRepository
    implements InventoryTransactionRepository {
  FirestoreInventoryTransactionRepository({
    required FirebaseFirestore firestore,
    required FirestoreIdSequence inventoryTransactionIdSequence,
  }) : _firestore = firestore,
       _idSequence = inventoryTransactionIdSequence;

  final FirebaseFirestore _firestore;
  final FirestoreIdSequence _idSequence;

  CollectionReference<Map<String, dynamic>> get _transactions =>
      _firestore.collection(FirestoreSchema.inventoryTransactions);

  // ============ BaseRepository<InventoryTransaction, int> ============

  @override
  Future<InventoryTransaction?> findById(int id) async {
    final doc = await _findDocByIntId(id);
    return doc == null
        ? null
        : InventoryTransactionDocMapper.fromData(doc.data() ?? const {});
  }

  @override
  Future<List<InventoryTransaction>> findAll() async {
    final snapshot = await _transactions.get();
    return snapshot.docs
        .map((doc) => InventoryTransactionDocMapper.fromData(doc.data()))
        .toList();
  }

  @override
  Future<InventoryTransaction> save(InventoryTransaction entity) async {
    var toWrite = entity;
    if (toWrite.id == null) {
      toWrite = toWrite.copyWith(id: await _idSequence.next());
    }
    await _transactions
        .doc('${toWrite.id}')
        .set(InventoryTransactionDocMapper.toData(toWrite));
    return toWrite;
  }

  @override
  Future<void> delete(int id) async {
    final doc = await _findDocByIntId(id);
    await doc?.reference.delete();
  }

  @override
  Future<bool> exists(int id) async => await findById(id) != null;

  // ============ StreamRepository<InventoryTransaction, int> ============

  @override
  Stream<InventoryTransaction?> watchById(int id) {
    return _transactions
        .where(FirestoreSchema.id, isEqualTo: id)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return InventoryTransactionDocMapper.fromData(
            snapshot.docs.first.data(),
          );
        });
  }

  @override
  Stream<List<InventoryTransaction>> watchAll() {
    return _transactions.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => InventoryTransactionDocMapper.fromData(doc.data()))
          .toList(),
    );
  }

  // ============ PaginatedRepository<InventoryTransaction, int> ============

  @override
  Future<PaginatedResult<InventoryTransaction>> findPaginated(
    PaginationParams params,
  ) async {
    final all = await findAll();
    return _paginate(all, params);
  }

  // ============ InventoryTransactionRepository ============

  @override
  Future<List<InventoryTransaction>> findByBatch(int batchId) async {
    final snapshot = await _transactions
        .where(FirestoreSchema.batchId, isEqualTo: batchId)
        .get();
    final transactions =
        snapshot.docs
            .map((doc) => InventoryTransactionDocMapper.fromData(doc.data()))
            .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return transactions;
  }

  @override
  Future<List<InventoryTransaction>> findByReference(
    String referenceType,
    int referenceId,
  ) async {
    final snapshot = await _transactions
        .where(FirestoreSchema.referenceType, isEqualTo: referenceType)
        .where(FirestoreSchema.referenceId, isEqualTo: referenceId)
        .get();
    return snapshot.docs
        .map((doc) => InventoryTransactionDocMapper.fromData(doc.data()))
        .toList();
  }

  @override
  Future<InventoryTransaction> create(InventoryTransaction transaction) =>
      save(transaction);

  // ============ Sync-aware operations (Firestore is the store) ============

  @override
  Future<InventoryTransaction> createWithSync(
    InventoryTransaction entity,
    String tableName,
  ) async => save(entity);

  @override
  Future<InventoryTransaction> updateWithSync(
    InventoryTransaction entity,
    String tableName,
  ) async => save(entity);

  @override
  Future<void> deleteWithSync(int id, String tableName) async => delete(id);

  // ============ Private helpers ============

  Future<DocumentSnapshot<Map<String, dynamic>>?> _findDocByIntId(
    int id,
  ) async {
    final snapshot = await _transactions
        .where(FirestoreSchema.id, isEqualTo: id)
        .limit(1)
        .get();
    return snapshot.docs.isEmpty ? null : snapshot.docs.first;
  }

  PaginatedResult<T> _paginate<T>(List<T> all, PaginationParams params) {
    final offset = params.offset;
    final end = (offset + params.pageSize).clamp(0, all.length);
    final items = offset < all.length ? all.sublist(offset, end) : <T>[];
    return PaginatedResult<T>(
      items: items,
      totalCount: all.length,
      page: params.page,
      pageSize: params.pageSize,
    );
  }
}
