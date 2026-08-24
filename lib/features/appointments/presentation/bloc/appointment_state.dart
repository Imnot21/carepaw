import 'package:equatable/equatable.dart';
import 'package:carepaw/features/appointments/domain/entities/appointment.dart';

/// Base class for all appointment states
abstract class AppointmentState extends Equatable {
  const AppointmentState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class AppointmentInitial extends AppointmentState {
  const AppointmentInitial();
}

/// Loading state
class AppointmentLoading extends AppointmentState {
  final bool isRefreshing;

  const AppointmentLoading({this.isRefreshing = false});

  @override
  List<Object?> get props => [isRefreshing];
}

/// Appointments loaded successfully
class AppointmentLoaded extends AppointmentState {
  final List<Appointment> appointments;
  final List<Appointment> upcomingAppointments;
  final List<Appointment> pastAppointments;
  final List<AppointmentWithPetDetails> upcomingWithPetDetails;
  final List<AppointmentWithPetDetails> pastWithPetDetails;

  const AppointmentLoaded({
    required this.appointments,
    this.upcomingAppointments = const [],
    this.pastAppointments = const [],
    this.upcomingWithPetDetails = const [],
    this.pastWithPetDetails = const [],
  });

  @override
  List<Object?> get props => [appointments, upcomingAppointments, pastAppointments, upcomingWithPetDetails, pastWithPetDetails];

  /// Get appointments grouped by status for UI
  Map<AppointmentStatus, List<Appointment>> get byStatus {
    final map = <AppointmentStatus, List<Appointment>>{};
    for (final appointment in appointments) {
      map.putIfAbsent(appointment.status, () => []).add(appointment);
    }
    return map;
  }

  /// Get appointments for a specific status
  List<Appointment> getByStatus(AppointmentStatus status) {
    return byStatus[status] ?? [];
  }
}

/// Single appointment loaded
class AppointmentDetailLoaded extends AppointmentState {
  final AppointmentWithDetails appointmentWithDetails;

  const AppointmentDetailLoaded(this.appointmentWithDetails);

  @override
  List<Object?> get props => [appointmentWithDetails];
}

/// Appointment created successfully
class AppointmentCreated extends AppointmentState {
  final Appointment appointment;

  const AppointmentCreated(this.appointment);

  @override
  List<Object?> get props => [appointment];
}

/// Appointment updated successfully
class AppointmentUpdated extends AppointmentState {
  final Appointment appointment;

  const AppointmentUpdated(this.appointment);

  @override
  List<Object?> get props => [appointment];
}

/// Appointment status updated successfully
class AppointmentStatusUpdated extends AppointmentState {
  final Appointment appointment;

  const AppointmentStatusUpdated(this.appointment);

  @override
  List<Object?> get props => [appointment];
}

/// Appointment deleted successfully
class AppointmentDeleted extends AppointmentState {
  final int appointmentId;

  const AppointmentDeleted(this.appointmentId);

  @override
  List<Object?> get props => [appointmentId];
}

/// Error state
class AppointmentError extends AppointmentState {
  final String message;
  final String? code;

  const AppointmentError(this.message, {this.code});

  @override
  List<Object?> get props => [message, code];
}