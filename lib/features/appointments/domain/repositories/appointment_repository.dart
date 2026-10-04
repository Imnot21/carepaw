import 'package:carepaw/core/repositories/base_repository.dart';
import 'package:carepaw/features/appointments/domain/entities/appointment.dart';

/// Appointment repository interface - domain layer contract
abstract class AppointmentRepository
    extends SoftDeleteRepository<Appointment, int>
    implements
        StreamRepository<Appointment, int>,
        PaginatedRepository<Appointment, int> {
  /// Sync-aware operations
  @override
  Future<Appointment> createWithSync(Appointment entity, String tableName);

  @override
  Future<Appointment> updateWithSync(Appointment entity, String tableName);

  @override
  Future<void> deleteWithSync(int id, String tableName);

  /// Find appointments for a pet
  Future<List<Appointment>> findByPet(int petId);

  /// Watch appointments for a pet (real-time)
  Stream<List<Appointment>> watchByPet(int petId);

  /// Find appointments for a veterinarian
  Future<List<Appointment>> findByVeterinarian(int veterinarianId);

  /// Find appointments by status
  Future<List<Appointment>> findByStatus(AppointmentStatus status);

  /// Find upcoming appointments for a pet
  Future<List<Appointment>> findUpcomingForPet(int petId);

  /// Find all appointments for an owner (pet owner's pets)
  Future<List<Appointment>> findByOwner(int ownerId);

  /// Find upcoming appointments for an owner
  Future<List<Appointment>> findUpcomingForOwner(int ownerId);

  /// Find appointments with pet details for an owner
  Future<List<AppointmentWithPetDetails>> findWithPetDetailsByOwner(
    int ownerId,
  );

  /// Find upcoming appointments with pet details for an owner
  Future<List<AppointmentWithPetDetails>> findUpcomingWithPetDetailsForOwner(
    int ownerId,
  );

  /// Find today's appointments for a veterinarian
  Future<List<Appointment>> findTodaysForVeterinarian(int veterinarianId);

  /// Find appointment with details
  Future<AppointmentWithDetails?> findWithDetails(int appointmentId);

  /// Update appointment status
  Future<Appointment> updateStatus(
    int id,
    AppointmentStatus status, {
    DateTime? checkInAt,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
    String? cancellationReason,
  });

  /// Check in appointment
  Future<Appointment> checkIn(int id);

  /// Start appointment
  Future<Appointment> start(int id);

  /// Complete appointment
  Future<Appointment> complete(int id);

  /// Cancel appointment
  Future<Appointment> cancel(int id, String reason);

  /// Reschedule appointment
  Future<Appointment> reschedule(int id, DateTime newTime);

  /// Get appointment count by status
  Future<int> countByStatus(AppointmentStatus status);

  /// Get appointment count for veterinarian today
  Future<int> countTodaysForVeterinarian(int veterinarianId);
}
