import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carepaw/core/firebase/firestore_id_sequence.dart';
import 'package:carepaw/core/firebase/firestore_schema.dart';
import 'package:carepaw/core/repositories/base_repository.dart';
import 'package:carepaw/features/inventory/data/mappers/inventory_item_doc_mapper.dart';
import 'package:carepaw/features/inventory/domain/entities/inventory.dart';
import 'package:carepaw/features/inventory/domain/repositories/inventory_repository.dart';

/// Inventory item repository implementation - data layer (Firestore-backed).
///
/// Implements [InventoryItemRepository] with Cloud Firestore's
/// `inventoryItems` collection as the source of truth. Documents are keyed by
/// the app-facing integer `id` (string form).
///
/// Soft deletes are recorded with a `deleted` boolean flag on the document.
///
/// The former Drift repository is intentionally set aside and no longer wired.
class FirestoreInventoryItemRepository implements InventoryItemRepository {
  FirestoreInventoryItemRepository({
    required FirebaseFirestore firestore,
    required FirestoreIdSequence inventoryItemIdSequence,
  })  : _firestore = firestore,
        _idSequence = inventoryItemIdSequence;

  final FirebaseFirestore _firestore;
  final FirestoreIdSequence _idSequence;

  static const String _deletedField = 'deleted';

  CollectionReference<Map<String, dynamic>> get _items =>
      _firestore.collection(FirestoreSchema.inventoryItems);

  // ============ BaseRepository<InventoryItem, int> ============

  @override
  Future<InventoryItem?> findById(int id) async {
    final doc = await _findDocByIntId(id);
    if (doc == null || _isDeleted(doc)) return null;
    return InventoryItemDocMapper.fromData(doc.data() ?? const {});
  }

  @override
  Future<List<InventoryItem>> findAll() async {
    final snapshot = await _items.get();
    return snapshot.docs
        .where((doc) => !_isDeleted(doc))
        .map((doc) => InventoryItemDocMapper.fromData(doc.data()))
        .toList();
  }

  @override
  Future<InventoryItem> save(InventoryItem entity) async {
    var toWrite = entity;
    if (toWrite.id == null) {
      toWrite = toWrite.copyWith(id: await _idSequence.next());
    }
    await _items.doc('${toWrite.id}').set(InventoryItemDocMapper.toData(toWrite));
    return toWrite;
  }

  @override
  Future<void> delete(int id) => softDelete(id);

  @override
  Future<bool> exists(int id) async => await findById(id) != null;

  // ============ SoftDeleteRepository<InventoryItem, int> ============

  @override
  Future<void> softDelete(int id) async {
    final doc = await _findDocByIntId(id);
    if (doc == null) return;
    await doc.reference.update({
      _deletedField: true,
      FirestoreSchema.updatedAt: DateTime.now(),
    });
  }

  @override
  Future<void> restore(int id) async {
    final doc = await _findDocByIntId(id);
    if (doc == null) return;
    await doc.reference.update({
      _deletedField: false,
      FirestoreSchema.updatedAt: DateTime.now(),
    });
  }

  @override
  Future<List<InventoryItem>> findAllIncludingDeleted() async {
    final snapshot = await _items.get();
    return snapshot.docs
        .map((doc) => InventoryItemDocMapper.fromData(doc.data()))
        .toList();
  }

  // ============ StreamRepository<InventoryItem, int> ============

  @override
  Stream<InventoryItem?> watchById(int id) {
    return _items
        .where(FirestoreSchema.id, isEqualTo: id)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty || _isDeleted(snapshot.docs.first)) return null;
      return InventoryItemDocMapper.fromData(snapshot.docs.first.data());
    });
  }

  @override
  Stream<List<InventoryItem>> watchAll() {
    return _items.snapshots().map((snapshot) => snapshot.docs
        .where((doc) => !_isDeleted(doc))
        .map((doc) => InventoryItemDocMapper.fromData(doc.data()))
        .toList());
  }

  // ============ PaginatedRepository<InventoryItem, int> ============

  @override
  Future<PaginatedResult<InventoryItem>> findPaginated(PaginationParams params) async {
    final all = await findAll();
    return _paginate(all, params);
  }

  // ============ InventoryItemRepository ============

  @override
  Future<List<InventoryItem>> findByCategory(InventoryCategory category) async {
    final all = await findAll();
    return all.where((item) => item.category == category).toList();
  }

  @override
  Future<List<InventoryItem>> findLowStock() async {
    final all = await findAll();
    return all.where((item) => item.isLowStock).toList();
  }

  @override
  Future<List<InventoryItem>> search(String query) async {
    final normalized = query.trim().toLowerCase();
    final all = await findAll();
    if (normalized.isEmpty) return all;
    return all.where((item) => item.name.toLowerCase().contains(normalized)).toList();
  }

  @override
  Future<InventoryItem> updateStock(int id, double newStock) async {
    final existing = await findById(id);
    if (existing == null) throw Exception('Inventory item not found');
    return save(existing.copyWith(
      currentStock: newStock,
      updatedAt: DateTime.now(),
    ));
  }

  @override
  Future<InventoryItem> adjustStock(int id, double delta) async {
    final existing = await findById(id);
    if (existing == null) throw Exception('Inventory item not found');
    return save(existing.copyWith(
      currentStock: existing.currentStock + delta,
      updatedAt: DateTime.now(),
    ));
  }

  // ============ Sync-aware operations (Firestore is the store) ============

  @override
  Future<InventoryItem> createWithSync(InventoryItem entity, String tableName) async => save(entity);

  @override
  Future<InventoryItem> updateWithSync(InventoryItem entity, String tableName) async => save(entity);

  @override
  Future<void> deleteWithSync(int id, String tableName) async => softDelete(id);

  // ============ Private helpers ============

  bool _isDeleted(DocumentSnapshot<Map<String, dynamic>> doc) =>
      (doc.data() ?? const {})[_deletedField] == true;

  Future<DocumentSnapshot<Map<String, dynamic>>?> _findDocByIntId(int id) async {
    final snapshot = await _items.where(FirestoreSchema.id, isEqualTo: id).limit(1).get();
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