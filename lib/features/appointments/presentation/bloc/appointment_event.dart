import 'package:equatable/equatable.dart';
import 'package:carepaw/features/appointments/domain/entities/appointment.dart';

/// Base class for all appointment events
abstract class AppointmentEvent extends Equatable {
  const AppointmentEvent();

  @override
  List<Object?> get props => [];
}

/// Load appointments for the current user's pets
class AppointmentLoadRequested extends AppointmentEvent {
  final int? petId; // Optional: filter by specific pet

  const AppointmentLoadRequested({this.petId});

  @override
  List<Object?> get props => [petId];
}

/// Load upcoming appointments
class AppointmentUpcomingLoadRequested extends AppointmentEvent {
  final int petId;

  const AppointmentUpcomingLoadRequested(this.petId);

  @override
  List<Object?> get props => [petId];
}

/// Create a new appointment request
class AppointmentCreateRequested extends AppointmentEvent {
  final Appointment appointment;

  const AppointmentCreateRequested(this.appointment);

  @override
  List<Object?> get props => [appointment];
}

/// Update an existing appointment
class AppointmentUpdateRequested extends AppointmentEvent {
  final Appointment appointment;

  const AppointmentUpdateRequested(this.appointment);

  @override
  List<Object?> get props => [appointment];
}

/// Update appointment status (check-in, start, complete, cancel)
class AppointmentStatusUpdateRequested extends AppointmentEvent {
  final int appointmentId;
  final AppointmentStatus status;
  final String? cancellationReason;

  const AppointmentStatusUpdateRequested(
    this.appointmentId,
    this.status, {
    this.cancellationReason,
  });

  @override
  List<Object?> get props => [appointmentId, status, cancellationReason];
}

/// Check in appointment
class AppointmentCheckInRequested extends AppointmentEvent {
  final int appointmentId;

  const AppointmentCheckInRequested(this.appointmentId);

  @override
  List<Object?> get props => [appointmentId];
}

/// Start appointment
class AppointmentStartRequested extends AppointmentEvent {
  final int appointmentId;

  const AppointmentStartRequested(this.appointmentId);

  @override
  List<Object?> get props => [appointmentId];
}

/// Complete appointment
class AppointmentCompleteRequested extends AppointmentEvent {
  final int appointmentId;

  const AppointmentCompleteRequested(this.appointmentId);

  @override
  List<Object?> get props => [appointmentId];
}

/// Cancel appointment
class AppointmentCancelRequested extends AppointmentEvent {
  final int appointmentId;
  final String reason;

  const AppointmentCancelRequested(this.appointmentId, this.reason);

  @override
  List<Object?> get props => [appointmentId, reason];
}

/// Reschedule appointment
class AppointmentRescheduleRequested extends AppointmentEvent {
  final int appointmentId;
  final DateTime newTime;

  const AppointmentRescheduleRequested(this.appointmentId, this.newTime);

  @override
  List<Object?> get props => [appointmentId, newTime];
}

/// Delete appointment (soft delete)
class AppointmentDeleteRequested extends AppointmentEvent {
  final int appointmentId;

  const AppointmentDeleteRequested(this.appointmentId);

  @override
  List<Object?> get props => [appointmentId];
}

/// Clear error state
class AppointmentErrorCleared extends AppointmentEvent {}

/// Refresh appointments
class AppointmentRefreshRequested extends AppointmentEvent {}

/// Load single appointment with details (pet, veterinarian)
class AppointmentDetailLoadRequested extends AppointmentEvent {
  final int appointmentId;

  const AppointmentDetailLoadRequested(this.appointmentId);

  @override
  List<Object?> get props => [appointmentId];
}