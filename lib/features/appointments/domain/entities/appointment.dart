import 'package:equatable/equatable.dart';
import 'package:carepaw/features/pets/domain/entities/pet.dart';
import 'package:carepaw/features/authentication/domain/entities/user.dart';

/// Appointment entity - domain layer representation
class Appointment extends Equatable {
  final int? id;
  final int petId;
  final int veterinarianId;
  final DateTime scheduledAt;
  final int durationMinutes;
  final AppointmentStatus status;
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
    required this.veterinarianId,
    required this.scheduledAt,
    this.durationMinutes = 30,
    this.status = AppointmentStatus.requested,
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

  /// Check if appointment can be checked in
  bool get canCheckIn => status == AppointmentStatus.confirmed;

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

  /// Check if appointment is overdue
  bool get isOverdue =>
      scheduledAt.isBefore(DateTime.now()) &&
      (status == AppointmentStatus.requested ||
          status == AppointmentStatus.confirmed);

  @override
  List<Object?> get props => [
    id,
    petId,
    veterinarianId,
    scheduledAt,
    durationMinutes,
    status,
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
    int? veterinarianId,
    DateTime? scheduledAt,
    int? durationMinutes,
    AppointmentStatus? status,
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
      veterinarianId: veterinarianId ?? this.veterinarianId,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      status: status ?? this.status,
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
enum AppointmentStatus {
  requested('REQUESTED'),
  confirmed('CONFIRMED'),
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
        return 'Requested';
      case AppointmentStatus.confirmed:
        return 'Confirmed';
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
