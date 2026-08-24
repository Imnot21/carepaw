import 'package:drift/drift.dart';
import 'package:carepaw/core/database/database.dart';
import 'package:carepaw/core/database/tables.dart';

part 'appointments_dao.g.dart';

@DriftAccessor(tables: [Appointments, Pets, Users])
class AppointmentsDao extends DatabaseAccessor<CarePawDatabase> with _$AppointmentsDaoMixin {
  AppointmentsDao(super.db);

  // ============ Queries ============

  /// Get appointment by ID
  Future<Appointment?> getById(int id) {
    return (select(appointments)..where((a) => a.id.equals(id))).getSingleOrNull();
  }

  /// Get all active appointments (not cancelled/no-show)
  Future<List<Appointment>> getAllActive() {
    return (select(appointments)
          ..where((a) => a.status.isNotIn(['CANCELLED', 'NO_SHOW']))
          ..orderBy([(a) => OrderingTerm.desc(a.scheduledAt)]))
        .get();
  }

  /// Get appointments for a pet
  Future<List<Appointment>> getByPet(int petId) {
    return (select(appointments)
          ..where((a) => a.petId.equals(petId))
          ..orderBy([(a) => OrderingTerm.desc(a.scheduledAt)]))
        .get();
  }

  /// Get appointments for a veterinarian
  Future<List<Appointment>> getByVeterinarian(int vetId) {
    return (select(appointments)
          ..where((a) => a.veterinarianId.equals(vetId))
          ..orderBy([(a) => OrderingTerm.asc(a.scheduledAt)]))
        .get();
  }

  /// Get appointments by status
  Future<List<Appointment>> getByStatus(String status) {
    return (select(appointments)
          ..where((a) => a.status.equals(status))
          ..orderBy([(a) => OrderingTerm.asc(a.scheduledAt)]))
        .get();
  }

  /// Get appointments for a pet owner (joined with pets table)
  Future<List<AppointmentWithPet>> getByOwner(int ownerId) {
    final query = select(appointments).join([
      innerJoin(pets, pets.id.equalsExp(appointments.petId)),
    ])..where(pets.ownerId.equals(ownerId));

    return query.map((row) {
      return AppointmentWithPet(
        appointment: row.readTable(appointments),
        pet: row.readTable(pets),
      );
    }).get();
  }

  /// Get upcoming appointments for a pet owner
  Future<List<AppointmentWithPet>> getUpcomingForOwner(int ownerId) {
    final now = DateTime.now();
    final query = select(appointments).join([
      innerJoin(pets, pets.id.equalsExp(appointments.petId)),
    ])..where(
        pets.ownerId.equals(ownerId) &
        appointments.scheduledAt.isBiggerOrEqualValue(now) &
        (appointments.status.equals('REQUESTED') |
            appointments.status.equals('CONFIRMED') |
            appointments.status.equals('CHECKED_IN')),
      );

    return query.map((row) {
      return AppointmentWithPet(
        appointment: row.readTable(appointments),
        pet: row.readTable(pets),
      );
    }).get();
  }

  /// Get all appointments with pet details for an owner
  Future<List<AppointmentWithPet>> getWithPetDetailsByOwner(int ownerId) {
    final query = select(appointments).join([
      innerJoin(pets, pets.id.equalsExp(appointments.petId)),
    ])..where(pets.ownerId.equals(ownerId));

    return query.map((row) {
      return AppointmentWithPet(
        appointment: row.readTable(appointments),
        pet: row.readTable(pets),
      );
    }).get();
  }

  /// Get upcoming appointments with pet details for an owner
  Future<List<AppointmentWithPet>> getUpcomingWithPetDetailsForOwner(int ownerId) {
    final now = DateTime.now();
    final query = select(appointments).join([
      innerJoin(pets, pets.id.equalsExp(appointments.petId)),
    ])..where(
        pets.ownerId.equals(ownerId) &
        appointments.scheduledAt.isBiggerOrEqualValue(now) &
        (appointments.status.equals('REQUESTED') |
            appointments.status.equals('CONFIRMED') |
            appointments.status.equals('CHECKED_IN')),
      );

    return query.map((row) {
      return AppointmentWithPet(
        appointment: row.readTable(appointments),
        pet: row.readTable(pets),
      );
    }).get();
  }

  /// Get upcoming appointments for a pet
  Future<List<Appointment>> getUpcomingForPet(int petId) {
    final now = DateTime.now();
    return (select(appointments)
          ..where((a) =>
              a.petId.equals(petId) &
              a.scheduledAt.isBiggerOrEqualValue(now) &
              (a.status.equals('REQUESTED') | a.status.equals('CONFIRMED') | a.status.equals('CHECKED_IN')))
          ..orderBy([(a) => OrderingTerm.asc(a.scheduledAt)]))
        .get();
  }

  /// Get today's appointments for a veterinarian
  Future<List<Appointment>> getTodaysAppointments(int vetId) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return (select(appointments)
          ..where((a) =>
              a.veterinarianId.equals(vetId) &
              a.scheduledAt.isBiggerOrEqualValue(startOfDay) &
              a.scheduledAt.isSmallerThanValue(endOfDay))
          ..orderBy([(a) => OrderingTerm.asc(a.scheduledAt)]))
        .get();
  }

  /// Get appointment with pet and vet info
  Future<AppointmentWithDetails?> getWithDetails(int appointmentId) {
    final query = select(appointments).join([
      innerJoin(pets, pets.id.equalsExp(appointments.petId)),
      innerJoin(users, users.id.equalsExp(appointments.veterinarianId)),
    ])..where(appointments.id.equals(appointmentId));

    return query.map((row) {
      return AppointmentWithDetails(
        appointment: row.readTable(appointments),
        pet: row.readTable(pets),
        veterinarian: row.readTable(users),
      );
    }).getSingleOrNull();
  }

  /// Stream all appointments for real-time updates
  Stream<List<Appointment>> watchAll() {
    return (select(appointments)
          ..orderBy([(a) => OrderingTerm.desc(a.scheduledAt)]))
        .watch();
  }

  /// Stream appointments for real-time updates
  Stream<List<Appointment>> watchByPet(int petId) {
    return (select(appointments)
          ..where((a) => a.petId.equals(petId))
          ..orderBy([(a) => OrderingTerm.desc(a.scheduledAt)]))
        .watch();
  }

  /// Watch appointment by ID for real-time updates
  Stream<Appointment?> watchById(int id) {
    return (select(appointments)..where((a) => a.id.equals(id))).watchSingleOrNull();
  }

  /// Soft delete appointment (mark as cancelled)
  Future<int> softDelete(int id) {
    return updateStatus(id, 'CANCELLED', cancelledAt: DateTime.now(), cancellationReason: 'Deleted');
  }

  // ============ Mutations ============

  /// Create appointment
  Future<int> createAppointment(AppointmentsCompanion appointment) {
    return into(appointments).insert(appointment);
  }

  /// Update appointment
  Future<bool> updateAppointment(AppointmentsCompanion appointment) {
    return update(appointments).replace(appointment);
  }

  /// Update appointment status
  Future<int> updateStatus(int id, String status, {DateTime? checkInAt, DateTime? startedAt, DateTime? completedAt, DateTime? cancelledAt, String? cancellationReason}) async {
    final companion = AppointmentsCompanion(
      id: Value(id),
      status: Value(status),
      updatedAt: Value(DateTime.now()),
      checkInAt: checkInAt != null ? Value(checkInAt) : const Value.absent(),
      startedAt: startedAt != null ? Value(startedAt) : const Value.absent(),
      completedAt: completedAt != null ? Value(completedAt) : const Value.absent(),
      cancelledAt: cancelledAt != null ? Value(cancelledAt) : const Value.absent(),
      cancellationReason: cancellationReason != null ? Value(cancellationReason) : const Value.absent(),
    );
    await update(appointments).replace(companion);
    return id;
  }

  /// Check in appointment
  Future<int> checkIn(int id) {
    return updateStatus(id, 'CHECKED_IN', checkInAt: DateTime.now());
  }

  /// Start appointment
  Future<int> start(int id) {
    return updateStatus(id, 'IN_PROGRESS', startedAt: DateTime.now());
  }

  /// Complete appointment
  Future<int> complete(int id) {
    return updateStatus(id, 'COMPLETED', completedAt: DateTime.now());
  }

  /// Cancel appointment
  Future<int> cancel(int id, String reason) {
    return updateStatus(id, 'CANCELLED', cancelledAt: DateTime.now(), cancellationReason: reason);
  }
}

/// Appointment with related pet and veterinarian data
class AppointmentWithDetails {
  final Appointment appointment;
  final Pet pet;
  final User veterinarian;

  AppointmentWithDetails({
    required this.appointment,
    required this.pet,
    required this.veterinarian,
  });
}

/// Appointment with related pet data (for owner filtering)
class AppointmentWithPet {
  final Appointment appointment;
  final Pet pet;

  AppointmentWithPet({
    required this.appointment,
    required this.pet,
  });
}