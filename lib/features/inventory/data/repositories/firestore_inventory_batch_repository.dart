import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carepaw/core/firebase/firestore_id_sequence.dart';
import 'package:carepaw/core/firebase/firestore_schema.dart';
import 'package:carepaw/core/repositories/base_repository.dart';
import 'package:carepaw/features/inventory/data/mappers/inventory_batch_doc_mapper.dart';
import 'package:carepaw/features/inventory/domain/entities/inventory.dart';
import 'package:carepaw/features/inventory/domain/repositories/inventory_repository.dart';

/// Inventory batch repository implementation - data layer (Firestore-backed).
///
/// Implements [InventoryBatchRepository] with Cloud Firestore's
/// `inventoryBatches` collection as the source of truth. Documents are keyed by
/// the app-facing integer `id` (string form).
///
/// Batch consumption follows FIFO: the earliest-expiring batches are consumed
/// first. Deleting a batch is a hard delete (a consumed batch is removed).
///
/// The former Drift repository is intentionally set aside and no longer wired.
class FirestoreInventoryBatchRepository implements InventoryBatchRepository {
  FirestoreInventoryBatchRepository({
    required FirebaseFirestore firestore,
    required FirestoreIdSequence inventoryBatchIdSequence,
    required InventoryItemRepository itemRepository,
  }) : _firestore = firestore,
       _idSequence = inventoryBatchIdSequence,
       _itemRepository = itemRepository;

  final FirebaseFirestore _firestore;
  final FirestoreIdSequence _idSequence;
  final InventoryItemRepository _itemRepository;

  CollectionReference<Map<String, dynamic>> get _batches =>
      _firestore.collection(FirestoreSchema.inventoryBatches);

  // ============ BaseRepository<InventoryBatch, int> ============

  @override
  Future<InventoryBatch?> findById(int id) async {
    final doc = await _findDocByIntId(id);
    return doc == null
        ? null
        : InventoryBatchDocMapper.fromData(doc.data() ?? const {});
  }

  @override
  Future<List<InventoryBatch>> findAll() async {
    final snapshot = await _batches.get();
    return snapshot.docs
        .map((doc) => InventoryBatchDocMapper.fromData(doc.data()))
        .toList();
  }

  @override
  Future<InventoryBatch> save(InventoryBatch entity) async {
    var toWrite = entity;
    if (toWrite.id == null) {
      toWrite = toWrite.copyWith(id: await _idSequence.next());
    }
    await _batches
        .doc('${toWrite.id}')
        .set(InventoryBatchDocMapper.toData(toWrite));
    return toWrite;
  }

  @override
  Future<void> delete(int id) async {
    final doc = await _findDocByIntId(id);
    await doc?.reference.delete();
  }

  @override
  Future<bool> exists(int id) async => await findById(id) != null;

  // ============ SoftDeleteRepository<InventoryBatch, int> ============

  @override
  Future<void> softDelete(int id) => delete(id);

  @override
  Future<void> restore(int id) {
    throw UnsupportedError(
      'Inventory batches cannot be restored after deletion',
    );
  }

  @override
  Future<List<InventoryBatch>> findAllIncludingDeleted() => findAll();

  // ============ StreamRepository<InventoryBatch, int> ============

  @override
  Stream<InventoryBatch?> watchById(int id) {
    return _batches
        .where(FirestoreSchema.id, isEqualTo: id)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return InventoryBatchDocMapper.fromData(snapshot.docs.first.data());
        });
  }

  @override
  Stream<List<InventoryBatch>> watchAll() {
    return _batches.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => InventoryBatchDocMapper.fromData(doc.data()))
          .toList(),
    );
  }

  // ============ PaginatedRepository<InventoryBatch, int> ============

  @override
  Future<PaginatedResult<InventoryBatch>> findPaginated(
    PaginationParams params,
  ) async {
    final all = await findAll();
    return _paginate(all, params);
  }

  // ============ InventoryBatchRepository ============

  @override
  Future<List<InventoryBatch>> findByItem(int itemId) async {
    final snapshot = await _batches
        .where(FirestoreSchema.inventoryId, isEqualTo: itemId)
        .get();
    return snapshot.docs
        .map((doc) => InventoryBatchDocMapper.fromData(doc.data()))
        .toList();
  }

  @override
  Future<List<InventoryBatch>> findExpiring({int days = 30}) async {
    final now = DateTime.now();
    final horizon = now.add(Duration(days: days));
    final all = await findAll();
    return all.where((b) {
      if (b.expiresAt == null) return false;
      return b.expiresAt!.isAfter(now) && b.expiresAt!.isBefore(horizon);
    }).toList();
  }

  @override
  Future<List<InventoryBatch>> findExpired() async {
    final now = DateTime.now();
    final all = await findAll();
    return all
        .where((b) => b.expiresAt != null && b.expiresAt!.isBefore(now))
        .toList();
  }

  @override
  Future<double> consumeFromBatches(int itemId, double quantity) async {
    if (quantity <= 0) return 0;
    final itemBatches = await findByItem(itemId);
    // FIFO: consume earliest-expiring batches first (null expiry sorts last).
    itemBatches.sort((a, b) {
      final aTime = a.expiresAt ?? DateTime(9999);
      final bTime = b.expiresAt ?? DateTime(9999);
      return aTime.compareTo(bTime);
    });

    final batch = _firestore.batch();
    var remaining = quantity;
    double consumed = 0;
    for (final batchEntity in itemBatches) {
      if (remaining <= 0) break;
      if (batchEntity.quantity <= 0) continue;
      final take = remaining > batchEntity.quantity
          ? batchEntity.quantity
          : remaining;
      batch.update(_batches.doc('${batchEntity.id}'), {
        FirestoreSchema.quantity: batchEntity.quantity - take,
        FirestoreSchema.updatedAt: DateTime.now(),
      });
      remaining -= take;
      consumed += take;
    }
    if (consumed > 0) {
      await batch.commit();
      // Keep the aggregate item stock in sync.
      final item = await _itemRepository.findById(itemId);
      if (item != null) {
        await _itemRepository.updateStock(
          itemId,
          (item.currentStock - consumed).clamp(0, double.infinity),
        );
      }
    }
    return consumed;
  }

  @override
  Future<InventoryBatch> create(InventoryBatch batch) => save(batch);

  @override
  Future<InventoryBatch> update(InventoryBatch batch) => save(batch);

  // ============ Sync-aware operations (Firestore is the store) ============

  @override
  Future<InventoryBatch> createWithSync(
    InventoryBatch entity,
    String tableName,
  ) async => save(entity);

  @override
  Future<InventoryBatch> updateWithSync(
    InventoryBatch entity,
    String tableName,
  ) async => save(entity);

  @override
  Future<void> deleteWithSync(int id, String tableName) async => delete(id);

  // ============ Private helpers ============

  Future<DocumentSnapshot<Map<String, dynamic>>?> _findDocByIntId(
    int id,
  ) async {
    final snapshot = await _batches
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
