import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carepaw/core/firebase/firestore_id_sequence.dart';
import 'package:carepaw/core/firebase/firestore_schema.dart';
import 'package:carepaw/core/repositories/base_repository.dart';
import 'package:carepaw/features/appointments/domain/entities/appointment.dart';
import 'package:carepaw/features/appointments/domain/repositories/appointment_repository.dart';
import 'package:carepaw/features/medical_records/data/mappers/medical_record_doc_mapper.dart';
import 'package:carepaw/features/medical_records/domain/entities/medical_record.dart';
import 'package:carepaw/features/medical_records/domain/repositories/medical_record_repository.dart';
import 'package:carepaw/features/pets/domain/repositories/pet_repository.dart';
import 'package:carepaw/features/users/domain/repositories/user_repository.dart';

/// Medical record repository implementation - data layer (Firestore-backed).
///
/// Implements [MedicalRecordRepository] with Cloud Firestore's `medicalRecords`
/// collection as the source of truth. Documents are keyed by the app-facing
/// integer `id` (string form).
///
/// Medical records are **append-only** by design: no update or delete is
/// permitted on an existing record.
///
/// The former Drift repository is intentionally set aside and no longer wired.
class FirestoreMedicalRecordRepository implements MedicalRecordRepository {
  FirestoreMedicalRecordRepository({
    required FirebaseFirestore firestore,
    required FirestoreIdSequence medicalRecordIdSequence,
    required PetRepository petRepository,
    required UserRepository userRepository,
    required AppointmentRepository appointmentRepository,
  })  : _firestore = firestore,
        _idSequence = medicalRecordIdSequence,
        _petRepository = petRepository,
        _userRepository = userRepository,
        _appointmentRepository = appointmentRepository;

  final FirebaseFirestore _firestore;
  final FirestoreIdSequence _idSequence;
  final PetRepository _petRepository;
  final UserRepository _userRepository;
  final AppointmentRepository _appointmentRepository;

  CollectionReference<Map<String, dynamic>> get _records =>
      _firestore.collection(FirestoreSchema.medicalRecords);

  // ============ BaseRepository<MedicalRecord, int> ============

  @override
  Future<MedicalRecord?> findById(int id) async {
    final doc = await _findDocByIntId(id);
    return doc == null ? null : MedicalRecordDocMapper.fromData(doc.data() ?? const {});
  }

  @override
  Future<List<MedicalRecord>> findAll() async {
    final snapshot = await _records.get();
    return snapshot.docs.map((doc) => MedicalRecordDocMapper.fromData(doc.data())).toList();
  }

  @override
  Future<MedicalRecord> save(MedicalRecord entity) async {
    if (entity.id != null) {
      throw UnsupportedError('Medical records are append-only and cannot be updated');
    }
    return create(entity);
  }

  @override
  Future<void> delete(int id) {
    throw UnsupportedError('Medical records are append-only and cannot be deleted');
  }

  @override
  Future<bool> exists(int id) async => await findById(id) != null;

  // ============ StreamRepository<MedicalRecord, int> ============

  @override
  Stream<MedicalRecord?> watchById(int id) {
    return _records
        .where(FirestoreSchema.id, isEqualTo: id)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return MedicalRecordDocMapper.fromData(snapshot.docs.first.data());
    });
  }

  @override
  Stream<List<MedicalRecord>> watchAll() {
    return _records.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => MedicalRecordDocMapper.fromData(doc.data())).toList());
  }

  // ============ PaginatedRepository<MedicalRecord, int> ============

  @override
  Future<PaginatedResult<MedicalRecord>> findPaginated(PaginationParams params) async {
    final all = await findAll();
    return _paginate(all, params);
  }

  // ============ MedicalRecordRepository ============

  @override
  Future<List<MedicalRecord>> findByPet(int petId) async {
    final snapshot = await _records.where(FirestoreSchema.petId, isEqualTo: petId).get();
    final records = snapshot.docs
        .map((doc) => MedicalRecordDocMapper.fromData(doc.data()))
        .toList()
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    return records;
  }

  @override
  Stream<List<MedicalRecord>> watchByPet(int petId) {
    return _records
        .where(FirestoreSchema.petId, isEqualTo: petId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => MedicalRecordDocMapper.fromData(doc.data())).toList());
  }

  @override
  Future<List<MedicalRecord>> findByType(int petId, MedicalRecordType recordType) async {
    final petRecords = await findByPet(petId);
    return petRecords.where((r) => r.recordType == recordType).toList();
  }

  @override
  Future<List<MedicalRecord>> findByAppointment(int appointmentId) async {
    final snapshot = await _records.where(FirestoreSchema.appointmentId, isEqualTo: appointmentId).get();
    return snapshot.docs.map((doc) => MedicalRecordDocMapper.fromData(doc.data())).toList();
  }

  @override
  Future<MedicalRecordWithDetails?> findWithDetails(int recordId) async {
    final record = await findById(recordId);
    if (record == null) return null;
    return _enrich([record]).then((list) => list.isEmpty ? null : list.first);
  }

  @override
  Future<List<MedicalRecordWithDetails>> getRecent({int limit = 20}) async {
    final snapshot = await _records.limit(100).get();
    final records = snapshot.docs
        .map((doc) => MedicalRecordDocMapper.fromData(doc.data()))
        .toList()
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    final recent = records.take(limit).toList();
    return _enrich(recent);
  }

  @override
  Future<MedicalRecord> create(MedicalRecord record) async {
    var toWrite = record;
    if (toWrite.id == null) {
      toWrite = toWrite.copyWith(id: await _idSequence.next());
    }
    await _records.doc('${toWrite.id}').set(MedicalRecordDocMapper.toData(toWrite));
    return toWrite;
  }

  @override
  Future<MedicalRecord> createVisitRecord({
    required int petId,
    required int veterinarianId,
    required int appointmentId,
    required String title,
    String? description,
    String? diagnosis,
    String? treatment,
    String? medications,
    String? attachments,
  }) async {
    final now = DateTime.now();
    return create(MedicalRecord(
      petId: petId,
      veterinarianId: veterinarianId,
      appointmentId: appointmentId,
      recordType: MedicalRecordType.visit,
      title: title,
      description: description,
      diagnosis: diagnosis,
      treatment: treatment,
      medications: medications,
      attachments: attachments,
      recordedAt: now,
      createdAt: now,
    ));
  }

  @override
  Future<MedicalRecord> createVaccinationRecord({
    required int petId,
    required int veterinarianId,
    int? appointmentId,
    required String title,
    String? description,
    String? medications,
  }) async {
    final now = DateTime.now();
    return create(MedicalRecord(
      petId: petId,
      veterinarianId: veterinarianId,
      appointmentId: appointmentId,
      recordType: MedicalRecordType.vaccination,
      title: title,
      description: description,
      medications: medications,
      recordedAt: now,
      createdAt: now,
    ));
  }

  @override
  Future<MedicalRecord> createAllergyRecord({
    required int petId,
    required int veterinarianId,
    required String title,
    required String description,
  }) async {
    final now = DateTime.now();
    return create(MedicalRecord(
      petId: petId,
      veterinarianId: veterinarianId,
      recordType: MedicalRecordType.allergy,
      title: title,
      description: description,
      recordedAt: now,
      createdAt: now,
    ));
  }

  @override
  Future<MedicalRecord> createLabResultRecord({
    required int petId,
    required int veterinarianId,
    int? appointmentId,
    required String title,
    required String description,
  }) async {
    final now = DateTime.now();
    return create(MedicalRecord(
      petId: petId,
      veterinarianId: veterinarianId,
      appointmentId: appointmentId,
      recordType: MedicalRecordType.labResult,
      title: title,
      description: description,
      recordedAt: now,
      createdAt: now,
    ));
  }

  // ============ Sync-aware operations (Firestore is the store) ============

  @override
  Future<MedicalRecord> createWithSync(MedicalRecord entity, String tableName) async => create(entity);

  @override
  Future<MedicalRecord> updateWithSync(MedicalRecord entity, String tableName) {
    throw UnsupportedError('Medical records are append-only and cannot be updated');
  }

  @override
  Future<void> deleteWithSync(int id, String tableName) {
    throw UnsupportedError('Medical records are append-only and cannot be deleted');
  }

  // ============ Private helpers ============

  Future<DocumentSnapshot<Map<String, dynamic>>?> _findDocByIntId(int id) async {
    final snapshot = await _records.where(FirestoreSchema.id, isEqualTo: id).limit(1).get();
    return snapshot.docs.isEmpty ? null : snapshot.docs.first;
  }

  Future<List<MedicalRecordWithDetails>> _enrich(List<MedicalRecord> records) async {
    final result = <MedicalRecordWithDetails>[];
    for (final record in records) {
      final pet = await _petRepository.findById(record.petId);
      if (pet == null) continue;
      final veterinarian = await _userRepository.findById(record.veterinarianId);
      if (veterinarian == null) continue;
      Appointment? appointment;
      if (record.appointmentId != null) {
        appointment = await _appointmentRepository.findById(record.appointmentId!);
      }
      result.add(MedicalRecordWithDetails(
        record: record,
        pet: pet,
        veterinarian: veterinarian,
        appointment: appointment,
      ));
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