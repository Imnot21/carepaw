import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carepaw/core/firebase/firestore_id_sequence.dart';
import 'package:carepaw/core/firebase/firestore_schema.dart';
import 'package:carepaw/core/repositories/base_repository.dart';
import 'package:carepaw/features/pets/data/mappers/pet_doc_mapper.dart';
import 'package:carepaw/features/pets/domain/entities/pet.dart';
import 'package:carepaw/features/pets/domain/repositories/pet_repository.dart';

/// Pet repository implementation - data layer (Firestore-backed).
///
/// Implements [PetRepository] with Cloud Firestore's `pets` collection as the
/// source of truth. Documents are keyed by the app-facing integer `id` (string
/// form), live in `pets/{id}`, and are located via the dedicated `id` field
/// when only the integer is known.
///
/// The former Drift repository is intentionally set aside and no longer wired.
class FirestorePetRepository implements PetRepository {
  FirestorePetRepository({
    required FirebaseFirestore firestore,
    required FirestoreIdSequence petIdSequence,
  }) : _firestore = firestore,
       _idSequence = petIdSequence;

  final FirebaseFirestore _firestore;
  final FirestoreIdSequence _idSequence;

  /// Field used to soft-delete pets that lack a domain `isActive` toggle path.
  /// (Pets do carry `isActive`, so it is preferred when present.)
  static const String _deletedField = 'deleted';

  CollectionReference<Map<String, dynamic>> get _pets =>
      _firestore.collection(FirestoreSchema.pets);

  // ============ BaseRepository<Pet, int> ============

  @override
  Future<Pet?> findById(int id) async {
    final doc = await _findDocByIntId(id);
    if (doc == null || _isDeleted(doc)) return null;
    return PetDocMapper.fromData(doc.data() ?? const {});
  }

  @override
  Future<List<Pet>> findAll() async {
    final snapshot = await _pets.get();
    return snapshot.docs
        .where((doc) => !_isDeleted(doc))
        .map((doc) => PetDocMapper.fromData(doc.data()))
        .toList();
  }

  @override
  Future<Pet> save(Pet entity) async {
    var toWrite = entity;
    if (toWrite.id == null) {
      toWrite = toWrite.copyWith(id: await _idSequence.next());
    }
    await _pets.doc('${toWrite.id}').set(PetDocMapper.toData(toWrite));
    return toWrite;
  }

  @override
  Future<void> delete(int id) => softDelete(id);

  @override
  Future<bool> exists(int id) async => await findById(id) != null;

  // ============ SoftDeleteRepository<Pet, int> ============

  @override
  Future<void> softDelete(int id) async {
    final doc = await _findDocByIntId(id);
    if (doc == null) return;
    await doc.reference.update({
      FirestoreSchema.isActive: false,
      FirestoreSchema.updatedAt: DateTime.now(),
    });
  }

  @override
  Future<void> restore(int id) async {
    final doc = await _findDocByIntId(id);
    if (doc == null) return;
    await doc.reference.update({
      FirestoreSchema.isActive: true,
      FirestoreSchema.updatedAt: DateTime.now(),
    });
  }

  @override
  Future<List<Pet>> findAllIncludingDeleted() async {
    final snapshot = await _pets.get();
    return snapshot.docs
        .map((doc) => PetDocMapper.fromData(doc.data()))
        .toList();
  }

  // ============ StreamRepository<Pet, int> ============

  @override
  Stream<Pet?> watchById(int id) {
    return _pets
        .where(FirestoreSchema.id, isEqualTo: id)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty || _isDeleted(snapshot.docs.first))
            return null;
          return PetDocMapper.fromData(snapshot.docs.first.data());
        });
  }

  @override
  Stream<List<Pet>> watchAll() {
    return _pets.snapshots().map(
      (snapshot) => snapshot.docs
          .where((doc) => !_isDeleted(doc))
          .map((doc) => PetDocMapper.fromData(doc.data()))
          .toList(),
    );
  }

  // ============ PaginatedRepository<Pet, int> ============

  @override
  Future<PaginatedResult<Pet>> findPaginated(PaginationParams params) async {
    final all = await findAll();
    return _paginate(all, params);
  }

  // ============ PetRepository ============

  @override
  Future<List<Pet>> findByOwner(int ownerId) async {
    final snapshot = await _pets
        .where(FirestoreSchema.ownerId, isEqualTo: ownerId)
        .get();
    final results = snapshot.docs
        .where((doc) => !_isDeleted(doc))
        .map((doc) => PetDocMapper.fromData(doc.data()))
        .toList();
    results.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return results;
  }

  @override
  Stream<List<Pet>> watchByOwner(int ownerId) {
    return _pets
        .where(FirestoreSchema.ownerId, isEqualTo: ownerId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .where((doc) => !_isDeleted(doc))
              .map((doc) => PetDocMapper.fromData(doc.data()))
              .toList(),
        );
  }

  @override
  Future<List<Pet>> searchByName(int ownerId, String query) async {
    final normalized = query.trim().toLowerCase();
    final ownerPets = await findByOwner(ownerId);
    if (normalized.isEmpty) return ownerPets;
    return ownerPets
        .where((pet) => pet.name.toLowerCase().contains(normalized))
        .toList();
  }

  @override
  Future<Pet?> findWithOwner(int petId) => findById(petId);

  @override
  Future<Pet> updateWeight(int petId, double weightKg) async {
    final existing = await findById(petId);
    if (existing == null) {
      throw Exception('Pet not found');
    }
    return save(
      existing.copyWith(weightKg: weightKg, updatedAt: DateTime.now()),
    );
  }

  @override
  Future<int> countByOwner(int ownerId) async {
    final pets = await findByOwner(ownerId);
    return pets.length;
  }

  @override
  Future<int> countActiveByOwner(int ownerId) async {
    final pets = await findByOwner(ownerId);
    return pets.where((pet) => pet.isActive).length;
  }

  @override
  Future<List<Pet>> searchAllByName(String query) async {
    final normalized = query.trim().toLowerCase();
    final all = await findAll();
    if (normalized.isEmpty) return all;
    return all
        .where((pet) => pet.name.toLowerCase().contains(normalized))
        .toList();
  }

  // ============ Sync-aware operations (Firestore is the store) ============

  @override
  Future<Pet> createWithSync(Pet entity, String tableName) async =>
      save(entity);

  @override
  Future<Pet> updateWithSync(Pet entity, String tableName) async =>
      save(entity);

  @override
  Future<void> deleteWithSync(int id, String tableName) async => softDelete(id);

  // ============ Private helpers ============

  bool _isDeleted(DocumentSnapshot<Map<String, dynamic>> doc) =>
      (doc.data() ?? const {})[_deletedField] == true;

  Future<DocumentSnapshot<Map<String, dynamic>>?> _findDocByIntId(
    int id,
  ) async {
    final snapshot = await _pets
        .where(FirestoreSchema.id, isEqualTo: id)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return snapshot.docs.first;
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
