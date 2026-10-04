import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carepaw/core/firebase/firestore_id_sequence.dart';
import 'package:carepaw/core/firebase/firestore_schema.dart';
import 'package:carepaw/core/repositories/base_repository.dart';
import 'package:carepaw/features/medical_records/data/mappers/vaccination_doc_mapper.dart';
import 'package:carepaw/features/medical_records/domain/entities/vaccination.dart';
import 'package:carepaw/features/medical_records/domain/repositories/vaccination_repository.dart';
import 'package:carepaw/features/pets/domain/repositories/pet_repository.dart';
import 'package:carepaw/features/users/domain/repositories/user_repository.dart';

/// Vaccination repository implementation - data layer (Firestore-backed).
///
/// Implements [VaccinationRepository] with Cloud Firestore's `vaccinations`
/// collection as the source of truth. Documents are keyed by the app-facing
/// integer `id` (string form).
///
/// The former Drift repository is intentionally set aside and no longer wired.
class FirestoreVaccinationRepository implements VaccinationRepository {
  FirestoreVaccinationRepository({
    required FirebaseFirestore firestore,
    required FirestoreIdSequence vaccinationIdSequence,
    required PetRepository petRepository,
    required UserRepository userRepository,
  }) : _firestore = firestore,
       _idSequence = vaccinationIdSequence,
       _petRepository = petRepository,
       _userRepository = userRepository;

  final FirebaseFirestore _firestore;
  final FirestoreIdSequence _idSequence;
  final PetRepository _petRepository;
  final UserRepository _userRepository;

  CollectionReference<Map<String, dynamic>> get _vaccinations =>
      _firestore.collection(FirestoreSchema.vaccinations);

  // ============ BaseRepository<Vaccination, int> ============

  @override
  Future<Vaccination?> findById(int id) async {
    final doc = await _findDocByIntId(id);
    return doc == null
        ? null
        : VaccinationDocMapper.fromData(doc.data() ?? const {});
  }

  @override
  Future<List<Vaccination>> findAll() async {
    final snapshot = await _vaccinations.get();
    return snapshot.docs
        .map((doc) => VaccinationDocMapper.fromData(doc.data()))
        .toList();
  }

  @override
  Future<Vaccination> save(Vaccination entity) async {
    var toWrite = entity;
    if (toWrite.id == null) {
      toWrite = toWrite.copyWith(id: await _idSequence.next());
    }
    await _vaccinations
        .doc('${toWrite.id}')
        .set(VaccinationDocMapper.toData(toWrite));
    return toWrite;
  }

  @override
  Future<void> delete(int id) async {
    final doc = await _findDocByIntId(id);
    await doc?.reference.delete();
  }

  @override
  Future<bool> exists(int id) async => await findById(id) != null;

  // ============ StreamRepository<Vaccination, int> ============

  @override
  Stream<Vaccination?> watchById(int id) {
    return _vaccinations
        .where(FirestoreSchema.id, isEqualTo: id)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return VaccinationDocMapper.fromData(snapshot.docs.first.data());
        });
  }

  @override
  Stream<List<Vaccination>> watchAll() {
    return _vaccinations.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => VaccinationDocMapper.fromData(doc.data()))
          .toList(),
    );
  }

  // ============ PaginatedRepository<Vaccination, int> ============

  @override
  Future<PaginatedResult<Vaccination>> findPaginated(
    PaginationParams params,
  ) async {
    final all = await findAll();
    return _paginate(all, params);
  }

  // ============ VaccinationRepository ============

  @override
  Future<List<Vaccination>> findByPet(int petId) async {
    final snapshot = await _vaccinations
        .where(FirestoreSchema.petId, isEqualTo: petId)
        .get();
    final vaccinations =
        snapshot.docs
            .map((doc) => VaccinationDocMapper.fromData(doc.data()))
            .toList()
          ..sort((a, b) => b.administeredAt.compareTo(a.administeredAt));
    return vaccinations;
  }

  @override
  Stream<List<Vaccination>> watchByPet(int petId) {
    return _vaccinations
        .where(FirestoreSchema.petId, isEqualTo: petId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => VaccinationDocMapper.fromData(doc.data()))
              .toList(),
        );
  }

  @override
  Future<List<Vaccination>> findDueSoon({int days = 30}) async {
    final now = DateTime.now();
    final horizon = now.add(Duration(days: days));
    final all = await findAll();
    return all.where((v) {
      if (v.nextDueAt == null) return false;
      return v.nextDueAt!.isAfter(now) && v.nextDueAt!.isBefore(horizon);
    }).toList();
  }

  @override
  Future<List<Vaccination>> findOverdue() async {
    final now = DateTime.now();
    final all = await findAll();
    return all
        .where((v) => v.nextDueAt != null && v.nextDueAt!.isBefore(now))
        .toList();
  }

  @override
  Future<List<VaccinationWithDetails>> findWithDetailsByPet(int petId) async {
    final vaccinations = await findByPet(petId);
    return _enrich(vaccinations);
  }

  @override
  Future<Vaccination> create(Vaccination vaccination) => save(vaccination);

  @override
  Future<Vaccination> update(Vaccination vaccination) => save(vaccination);

  @override
  Future<int> countDueSoon(int petId, {int days = 30}) async {
    final petVaccinations = await findByPet(petId);
    final now = DateTime.now();
    final horizon = now.add(Duration(days: days));
    return petVaccinations.where((v) {
      if (v.nextDueAt == null) return false;
      return v.nextDueAt!.isAfter(now) && v.nextDueAt!.isBefore(horizon);
    }).length;
  }

  @override
  Future<int> countOverdue(int petId) async {
    final petVaccinations = await findByPet(petId);
    final now = DateTime.now();
    return petVaccinations
        .where((v) => v.nextDueAt != null && v.nextDueAt!.isBefore(now))
        .length;
  }

  // ============ Sync-aware operations (Firestore is the store) ============

  @override
  Future<Vaccination> createWithSync(
    Vaccination entity,
    String tableName,
  ) async => save(entity);

  @override
  Future<Vaccination> updateWithSync(
    Vaccination entity,
    String tableName,
  ) async => save(entity);

  @override
  Future<void> deleteWithSync(int id, String tableName) async => delete(id);

  // ============ Private helpers ============

  Future<DocumentSnapshot<Map<String, dynamic>>?> _findDocByIntId(
    int id,
  ) async {
    final snapshot = await _vaccinations
        .where(FirestoreSchema.id, isEqualTo: id)
        .limit(1)
        .get();
    return snapshot.docs.isEmpty ? null : snapshot.docs.first;
  }

  Future<List<VaccinationWithDetails>> _enrich(
    List<Vaccination> vaccinations,
  ) async {
    final result = <VaccinationWithDetails>[];
    for (final vaccination in vaccinations) {
      final pet = await _petRepository.findById(vaccination.petId);
      if (pet == null) continue;
      final veterinarian = await _userRepository.findById(
        vaccination.veterinarianId,
      );
      if (veterinarian == null) continue;
      result.add(
        VaccinationWithDetails(
          vaccination: vaccination,
          pet: pet,
          veterinarian: veterinarian,
        ),
      );
    }
    return result;
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
