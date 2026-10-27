import 'package:carepaw/core/constants/app_constants.dart';
import 'package:equatable/equatable.dart';
import 'package:carepaw/features/pets/domain/entities/pet.dart';
import 'package:carepaw/features/authentication/domain/entities/user.dart';

/// Appointment entity - domain layer representation
class Appointment extends Equatable {
  final int? id;
  final int petId;
  final int ownerId;
  final int veterinarianId;
  final DateTime scheduledAt;
  final int durationMinutes;
  final AppointmentStatus status;

  /// Clinic service for this visit (thesis: owner selects the service).
  /// Examples: Consultation, Vaccination, Deworming — see [clinicServices].
  final String? service;

  /// Where a [homeServiceLabel] visit takes place; null for clinic visits.
  final String? serviceAddress;
  final String? reason;
  final String? notes;
  final DateTime? checkInAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Appointment({
    this.id,
    required this.petId,
    this.ownerId = 0,
    required this.veterinarianId,
    required this.scheduledAt,
    this.durationMinutes = 30,
    this.status = AppointmentStatus.requested,
    this.service,
    this.serviceAddress,
    this.reason,
    this.notes,
    this.checkInAt,
    this.startedAt,
    this.completedAt,
    this.cancelledAt,
    this.cancellationReason,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check if appointment is in a terminal state
  bool get isTerminal =>
      status == AppointmentStatus.completed ||
      status == AppointmentStatus.cancelled ||
      status == AppointmentStatus.noShow;

  /// Check if appointment can be checked in.
  ///
  /// Confirmed bookings and rescheduled ones (date changed after booking,
  /// still a valid upcoming visit) may check in at the clinic.
  bool get canCheckIn =>
      status == AppointmentStatus.confirmed ||
      status == AppointmentStatus.rescheduled;

  /// Check if appointment can be started
  bool get canStart => status == AppointmentStatus.checkedIn;

  /// Check if appointment can be completed
  bool get canComplete => status == AppointmentStatus.inProgress;

  /// Check if appointment can be cancelled
  bool get canCancel => !isTerminal;

  /// Get end time of appointment
  DateTime get endTime => scheduledAt.add(Duration(minutes: durationMinutes));

  /// Check if appointment is today
  bool get isToday {
    final now = DateTime.now();
    return scheduledAt.year == now.year &&
        scheduledAt.month == now.month &&
        scheduledAt.day == now.day;
  }

  /// Check if appointment is upcoming
  bool get isUpcoming => scheduledAt.isAfter(DateTime.now()) && !isTerminal;

  /// Whether this visit happens at the owner's home rather than the clinic.
  bool get isHomeService => service == homeServiceLabel;

  /// The owner has not checked in [AppConstants.lateArrivalMinutes] after the
  /// scheduled time. Clinic visits only: home visits have no arrival.
  bool get isLate =>
      canCheckIn &&
      !isHomeService &&
      DateTime.now().isAfter(
        scheduledAt.add(
          const Duration(minutes: AppConstants.lateArrivalMinutes),
        ),
      );

  /// Check if appointment is overdue
  bool get isOverdue =>
      scheduledAt.isBefore(DateTime.now()) &&
      (status == AppointmentStatus.requested ||
          status == AppointmentStatus.confirmed);

  @override
  List<Object?> get props => [
    id,
    petId,
    ownerId,
    veterinarianId,
    scheduledAt,
    durationMinutes,
    status,
    service,
    serviceAddress,
    reason,
    notes,
    checkInAt,
    startedAt,
    completedAt,
    cancelledAt,
    cancellationReason,
    createdAt,
    updatedAt,
  ];

  Appointment copyWith({
    int? id,
    int? petId,
    int? ownerId,
    int? veterinarianId,
    DateTime? scheduledAt,
    int? durationMinutes,
    AppointmentStatus? status,
    String? service,
    String? serviceAddress,
    String? reason,
    String? notes,
    DateTime? checkInAt,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
    String? cancellationReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Appointment(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      ownerId: ownerId ?? this.ownerId,
      veterinarianId: veterinarianId ?? this.veterinarianId,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      status: status ?? this.status,
      service: service ?? this.service,
      serviceAddress: serviceAddress ?? this.serviceAddress,
      reason: reason ?? this.reason,
      notes: notes ?? this.notes,
      checkInAt: checkInAt ?? this.checkInAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Appointment status enum
///
/// [rescheduled] is set when the date/time of a booked appointment is
/// changed afterwards (thesis paper status: rescheduled).
enum AppointmentStatus {
  requested('REQUESTED'),
  confirmed('CONFIRMED'),
  rescheduled('RESCHEDULED'),
  checkedIn('CHECKED_IN'),
  inProgress('IN_PROGRESS'),
  completed('COMPLETED'),
  cancelled('CANCELLED'),
  noShow('NO_SHOW');

  final String value;
  const AppointmentStatus(this.value);

  static AppointmentStatus fromString(String value) {
    return AppointmentStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => AppointmentStatus.requested,
    );
  }

  String get displayName {
    switch (this) {
      case AppointmentStatus.requested:
        return 'Pending Approval';
      case AppointmentStatus.confirmed:
        return 'Approved';
      case AppointmentStatus.rescheduled:
        return 'Rescheduled';
      case AppointmentStatus.checkedIn:
        return 'Checked In';
      case AppointmentStatus.inProgress:
        return 'In Progress';
      case AppointmentStatus.completed:
        return 'Completed';
      case AppointmentStatus.cancelled:
        return 'Cancelled';
      case AppointmentStatus.noShow:
        return 'No Show';
    }
  }
}

/// The service the vet performs at the owner's address.
const String homeServiceLabel = 'Home Service';

/// Clinic services offered (DocMyk's PILA VET HUB service list).
/// Used as the service picker when requesting an appointment.
const List<String> clinicServices = [
  'Consultation',
  homeServiceLabel,
  'Vaccination',
  'Deworming',
  'Dental Care',
  'Minor Surgery',
  'Diagnostic Test',
  'Medicine Dispensing',
  'Follow-up Checkup',
];

/// Appointment with related details
class AppointmentWithDetails extends Equatable {
  final Appointment appointment;
  final Pet pet;
  final User veterinarian;

  const AppointmentWithDetails({
    required this.appointment,
    required this.pet,
    required this.veterinarian,
  });

  @override
  List<Object?> get props => [appointment, pet, veterinarian];
}

/// Appointment with pet details (for owner listing)
class AppointmentWithPetDetails extends Equatable {
  final Appointment appointment;
  final Pet pet;

  const AppointmentWithPetDetails({
    required this.appointment,
    required this.pet,
  });

  @override
  List<Object?> get props => [appointment, pet];
}
