import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carepaw/core/firebase/firestore_id_sequence.dart';
import 'package:carepaw/core/firebase/firestore_schema.dart';
import 'package:carepaw/core/repositories/base_repository.dart';
import 'package:carepaw/features/appointments/data/mappers/appointment_doc_mapper.dart';
import 'package:carepaw/features/appointments/domain/entities/appointment.dart';
import 'package:carepaw/features/appointments/domain/repositories/appointment_repository.dart';
import 'package:carepaw/features/pets/domain/repositories/pet_repository.dart';
import 'package:carepaw/features/users/domain/repositories/user_repository.dart';

/// Appointment repository implementation - data layer (Firestore-backed).
///
/// Implements [AppointmentRepository] with Cloud Firestore's `appointments`
/// collection as the source of truth. Documents are keyed by the app-facing
/// integer `id` (string form). Relies on [PetRepository] and [UserRepository]
/// to compose the various "with details" views.
///
/// The former Drift repository is intentionally set aside and no longer wired.
class FirestoreAppointmentRepository implements AppointmentRepository {
  FirestoreAppointmentRepository({
    required FirebaseFirestore firestore,
    required FirestoreIdSequence appointmentIdSequence,
    required PetRepository petRepository,
    required UserRepository userRepository,
  })  : _firestore = firestore,
        _idSequence = appointmentIdSequence,
        _petRepository = petRepository,
        _userRepository = userRepository;

  final FirebaseFirestore _firestore;
  final FirestoreIdSequence _idSequence;
  final PetRepository _petRepository;
  final UserRepository _userRepository;

  CollectionReference<Map<String, dynamic>> get _appointments =>
      _firestore.collection(FirestoreSchema.appointments);

  // ============ BaseRepository<Appointment, int> ============

  @override
  Future<Appointment?> findById(int id) async {
    final doc = await _findDocByIntId(id);
    return doc == null ? null : AppointmentDocMapper.fromData(doc.data() ?? const {});
  }

  @override
  Future<List<Appointment>> findAll() async {
    final snapshot = await _appointments.get();
    return snapshot.docs.map((doc) => AppointmentDocMapper.fromData(doc.data())).toList();
  }

  @override
  Future<Appointment> save(Appointment entity) async {
    var toWrite = entity;
    if (toWrite.id == null) {
      toWrite = toWrite.copyWith(id: await _idSequence.next());
    }
    await _appointments.doc('${toWrite.id}').set(AppointmentDocMapper.toData(toWrite));
    return toWrite;
  }

  @override
  Future<void> delete(int id) => softDelete(id);

  @override
  Future<bool> exists(int id) async => await findById(id) != null;

  // ============ SoftDeleteRepository<Appointment, int> ============

  @override
  Future<void> softDelete(int id) async {
    final existing = await findById(id);
    if (existing == null || existing.isTerminal) return;
    await save(existing.copyWith(
      status: AppointmentStatus.cancelled,
      cancelledAt: DateTime.now(),
      cancellationReason: 'Soft deleted',
      updatedAt: DateTime.now(),
    ));
  }

  @override
  Future<void> restore(int id) async {
    final doc = await _findDocByIntId(id);
    if (doc == null) return;
    await doc.reference.update({
      FirestoreSchema.status: AppointmentStatus.requested.value,
      FirestoreSchema.cancelledAt: null,
      FirestoreSchema.cancellationReason: null,
      FirestoreSchema.updatedAt: DateTime.now(),
    });
  }

  @override
  Future<List<Appointment>> findAllIncludingDeleted() => findAll();

  // ============ StreamRepository<Appointment, int> ============

  @override
  Stream<Appointment?> watchById(int id) {
    return _appointments
        .where(FirestoreSchema.id, isEqualTo: id)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return AppointmentDocMapper.fromData(snapshot.docs.first.data());
    });
  }

  @override
  Stream<List<Appointment>> watchAll() {
    return _appointments.snapshots().map(
        (snapshot) => snapshot.docs.map((doc) => AppointmentDocMapper.fromData(doc.data())).toList());
  }

  // ============ PaginatedRepository<Appointment, int> ============

  @override
  Future<PaginatedResult<Appointment>> findPaginated(PaginationParams params) async {
    final all = await findAll();
    return _paginate(all, params);
  }

  // ============ AppointmentRepository ============

  @override
  Future<List<Appointment>> findByPet(int petId) async {
    final snapshot = await _appointments.where(FirestoreSchema.petId, isEqualTo: petId).get();
    return snapshot.docs.map((doc) => AppointmentDocMapper.fromData(doc.data())).toList();
  }

  @override
  Stream<List<Appointment>> watchByPet(int petId) {
    return _appointments
        .where(FirestoreSchema.petId, isEqualTo: petId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => AppointmentDocMapper.fromData(doc.data())).toList());
  }

  @override
  Future<List<Appointment>> findByVeterinarian(int veterinarianId) async {
    final snapshot = await _appointments.where(FirestoreSchema.veterinarianId, isEqualTo: veterinarianId).get();
    return snapshot.docs.map((doc) => AppointmentDocMapper.fromData(doc.data())).toList();
  }

  @override
  Future<List<Appointment>> findByStatus(AppointmentStatus status) async {
    final snapshot = await _appointments.where(FirestoreSchema.status, isEqualTo: status.value).get();
    return snapshot.docs.map((doc) => AppointmentDocMapper.fromData(doc.data())).toList();
  }

  @override
  Future<List<Appointment>> findUpcomingForPet(int petId) async {
    final now = DateTime.now();
    final appts = await findByPet(petId);
    return appts.where((a) => a.scheduledAt.isAfter(now) && !a.isTerminal).toList();
  }

  @override
  Future<List<Appointment>> findByOwner(int ownerId) async {
    final pets = await _petRepository.findByOwner(ownerId);
    final petIds = pets.map((p) => p.id).whereType<int>().toSet();
    if (petIds.isEmpty) return [];
    // Fetch per-pet rather than scanning the entire appointments collection,
    // which grows with every pet/owner in the system.
    final chunks = await Future.wait(petIds.map(findByPet));
    return chunks.expand((x) => x).toList();
  }

  @override
  Future<List<Appointment>> findUpcomingForOwner(int ownerId) async {
    final now = DateTime.now();
    final ownerAppts = await findByOwner(ownerId);
    return ownerAppts.where((a) => a.scheduledAt.isAfter(now) && !a.isTerminal).toList();
  }

  @override
  Future<List<AppointmentWithPetDetails>> findWithPetDetailsByOwner(int ownerId) async {
    final appts = await findByOwner(ownerId);
    return _enrichWithPets(appts);
  }

  @override
  Future<List<AppointmentWithPetDetails>> findUpcomingWithPetDetailsForOwner(int ownerId) async {
    final appts = await findUpcomingForOwner(ownerId);
    return _enrichWithPets(appts);
  }

  @override
  Future<List<Appointment>> findTodaysForVeterinarian(int veterinarianId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final vetAppts = await findByVeterinarian(veterinarianId);
    return vetAppts.where((a) => a.scheduledAt.isAfter(startOfDay) && a.scheduledAt.isBefore(endOfDay)).toList();
  }

  @override
  Future<AppointmentWithDetails?> findWithDetails(int appointmentId) async {
    final appt = await findById(appointmentId);
    if (appt == null) return null;
    final pet = await _petRepository.findById(appt.petId);
    final vet = await _userRepository.findById(appt.veterinarianId);
    if (pet == null || vet == null) return null;
    return AppointmentWithDetails(appointment: appt, pet: pet, veterinarian: vet);
  }

  @override
  Future<Appointment> updateStatus(
    int id,
    AppointmentStatus status, {
    DateTime? checkInAt,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
    String? cancellationReason,
  }) async {
    final existing = await findById(id);
    if (existing == null) throw Exception('Appointment not found');
    return save(existing.copyWith(
      status: status,
      checkInAt: checkInAt ?? existing.checkInAt,
      startedAt: startedAt ?? existing.startedAt,
      completedAt: completedAt ?? existing.completedAt,
      cancelledAt: cancelledAt ?? existing.cancelledAt,
      cancellationReason: cancellationReason ?? existing.cancellationReason,
      updatedAt: DateTime.now(),
    ));
  }

  @override
  Future<Appointment> checkIn(int id) async {
    final existing = await findById(id);
    if (existing == null) throw Exception('Appointment not found');
    if (!existing.canCheckIn) throw Exception('Appointment cannot be checked in');
    return save(existing.copyWith(
      status: AppointmentStatus.checkedIn,
      checkInAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
  }

  @override
  Future<Appointment> start(int id) async {
    final existing = await findById(id);
    if (existing == null) throw Exception('Appointment not found');
    if (!existing.canStart) throw Exception('Appointment cannot be started');
    return save(existing.copyWith(
      status: AppointmentStatus.inProgress,
      startedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
  }

  @override
  Future<Appointment> complete(int id) async {
    final existing = await findById(id);
    if (existing == null) throw Exception('Appointment not found');
    if (!existing.canComplete) throw Exception('Appointment cannot be completed');
    return save(existing.copyWith(
      status: AppointmentStatus.completed,
      completedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
  }

  @override
  Future<Appointment> cancel(int id, String reason) async {
    final existing = await findById(id);
    if (existing == null) throw Exception('Appointment not found');
    if (!existing.canCancel) throw Exception('Appointment cannot be cancelled');
    return save(existing.copyWith(
      status: AppointmentStatus.cancelled,
      cancelledAt: DateTime.now(),
      cancellationReason: reason,
      updatedAt: DateTime.now(),
    ));
  }

  @override
  Future<Appointment> reschedule(int id, DateTime newTime) async {
    final existing = await findById(id);
    if (existing == null) throw Exception('Appointment not found');
    return save(existing.copyWith(
      scheduledAt: newTime,
      status: AppointmentStatus.requested,
      updatedAt: DateTime.now(),
    ));
  }

  @override
  Future<int> countByStatus(AppointmentStatus status) async {
    final appts = await findByStatus(status);
    return appts.length;
  }

  @override
  Future<int> countTodaysForVeterinarian(int veterinarianId) async {
    final appts = await findTodaysForVeterinarian(veterinarianId);
    return appts.length;
  }

  // ============ Sync-aware operations (Firestore is the store) ============

  @override
  Future<Appointment> createWithSync(Appointment entity, String tableName) async => save(entity);

  @override
  Future<Appointment> updateWithSync(Appointment entity, String tableName) async => save(entity);

  @override
  Future<void> deleteWithSync(int id, String tableName) async => softDelete(id);

  // ============ Private helpers ============

  Future<DocumentSnapshot<Map<String, dynamic>>?> _findDocByIntId(int id) async {
    final snapshot = await _appointments.where(FirestoreSchema.id, isEqualTo: id).limit(1).get();
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

  Future<List<AppointmentWithPetDetails>> _enrichWithPets(List<Appointment> appointments) async {
    Future<AppointmentWithPetDetails?> enrichOne(Appointment appt) async {
      final pet = await _petRepository.findById(appt.petId);
      if (pet == null) return null;
      return AppointmentWithPetDetails(appointment: appt, pet: pet);
    }

    final resolved = await Future.wait(appointments.map(enrichOne));
    return resolved.whereType<AppointmentWithPetDetails>().toList();
  }
}