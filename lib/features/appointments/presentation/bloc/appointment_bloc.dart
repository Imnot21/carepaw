import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carepaw/core/errors/error_handler.dart';
import 'package:carepaw/features/appointments/domain/repositories/appointment_repository.dart';
import 'package:carepaw/features/appointments/domain/entities/appointment.dart';
import 'package:carepaw/features/appointments/presentation/bloc/appointment_event.dart';
import 'package:carepaw/features/appointments/presentation/bloc/appointment_state.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_state.dart';

/// Appointment BLoC - manages appointment state and business logic
class AppointmentBloc extends Bloc<AppointmentEvent, AppointmentState> {
  final AppointmentRepository _repository;
  final AuthBloc _authBloc;
  int? _currentPetId;

  AppointmentBloc({
    required AppointmentRepository repository,
    required AuthBloc authBloc,
  }) : _repository = repository,
       _authBloc = authBloc,
       super(AppointmentInitial()) {
    on<AppointmentLoadRequested>(_onLoadRequested);
    on<AppointmentUpcomingLoadRequested>(_onUpcomingLoadRequested);
    on<AppointmentDetailLoadRequested>(_onDetailLoadRequested);
    on<AppointmentCreateRequested>(_onCreateRequested);
    on<AppointmentUpdateRequested>(_onUpdateRequested);
    on<AppointmentStatusUpdateRequested>(_onStatusUpdateRequested);
    on<AppointmentCheckInRequested>(_onCheckInRequested);
    on<AppointmentStartRequested>(_onStartRequested);
    on<AppointmentCompleteRequested>(_onCompleteRequested);
    on<AppointmentCancelRequested>(_onCancelRequested);
    on<AppointmentRescheduleRequested>(_onRescheduleRequested);
    on<AppointmentDeleteRequested>(_onDeleteRequested);
    on<AppointmentErrorCleared>(_onErrorCleared);
    on<AppointmentRefreshRequested>(_onRefreshRequested);
  }

  /// Load all appointments for the authenticated user's pets (optionally filtered by pet)
  Future<void> _onLoadRequested(
    AppointmentLoadRequested event,
    Emitter<AppointmentState> emit,
  ) async {
    _currentPetId = event.petId;
    emit(const AppointmentLoading());

    try {
      final authState = _authBloc.state;
      if (authState is! AuthAuthenticated) {
        emit(const AppointmentError('Not authenticated'));
        return;
      }

      List<Appointment> appointments;
      List<AppointmentWithPetDetails> upcomingWithPetDetails = [];
      List<AppointmentWithPetDetails> pastWithPetDetails = [];

      if (event.petId != null) {
        // If petId is specified, load appointments for that pet
        appointments = await _repository.findByPet(event.petId!);
      } else {
        // Load all appointments for all of user's pets via owner filter
        final ownerId = authState.user.id!;
        appointments = await _repository.findByOwner(ownerId);

        // Also load with pet details for better UI
        final now = DateTime.now();
        final allWithDetails = await _repository.findWithPetDetailsByOwner(
          ownerId,
        );

        upcomingWithPetDetails =
            allWithDetails
                .where(
                  (a) =>
                      a.appointment.scheduledAt.isAfter(now) &&
                      !a.appointment.isTerminal,
                )
                .toList()
              ..sort(
                (a, b) => a.appointment.scheduledAt.compareTo(
                  b.appointment.scheduledAt,
                ),
              );

        pastWithPetDetails =
            allWithDetails
                .where(
                  (a) =>
                      a.appointment.scheduledAt.isBefore(now) ||
                      a.appointment.isTerminal,
                )
                .toList()
              ..sort(
                (a, b) => b.appointment.scheduledAt.compareTo(
                  a.appointment.scheduledAt,
                ),
              );
      }

      final now = DateTime.now();
      final upcoming =
          appointments
              .where((a) => a.scheduledAt.isAfter(now) && !a.isTerminal)
              .toList()
            ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

      final past =
          appointments
              .where((a) => a.scheduledAt.isBefore(now) || a.isTerminal)
              .toList()
            ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));

      emit(
        AppointmentLoaded(
          appointments: appointments,
          upcomingAppointments: upcoming,
          pastAppointments: past,
          upcomingWithPetDetails: upcomingWithPetDetails,
          pastWithPetDetails: pastWithPetDetails,
        ),
      );
    } catch (e) {
      emit(AppointmentError(ErrorHandler.getErrorMessage(e)));
    }
  }

  /// Load upcoming appointments for a specific pet
  Future<void> _onUpcomingLoadRequested(
    AppointmentUpcomingLoadRequested event,
    Emitter<AppointmentState> emit,
  ) async {
    emit(const AppointmentLoading(isRefreshing: true));

    try {
      final appointments = await _repository.findUpcomingForPet(event.petId);

      // Also load with pet details - we need ownerId, so find pet first
      // For now, just use appointments without pet details
      emit(
        AppointmentLoaded(
          appointments: appointments,
          upcomingAppointments: appointments,
          pastAppointments: const [],
        ),
      );
    } catch (e) {
      emit(AppointmentError(ErrorHandler.getErrorMessage(e)));
    }
  }

  /// Load single appointment with details
  Future<void> _onDetailLoadRequested(
    AppointmentDetailLoadRequested event,
    Emitter<AppointmentState> emit,
  ) async {
    emit(const AppointmentLoading());

    try {
      final appointmentWithDetails = await _repository.findWithDetails(
        event.appointmentId,
      );
      if (appointmentWithDetails != null) {
        emit(AppointmentDetailLoaded(appointmentWithDetails));
      } else {
        emit(const AppointmentError('Appointment not found'));
      }
    } catch (e) {
      emit(AppointmentError(ErrorHandler.getErrorMessage(e)));
    }
  }

  /// Create a new appointment
  Future<void> _onCreateRequested(
    AppointmentCreateRequested event,
    Emitter<AppointmentState> emit,
  ) async {
    emit(const AppointmentLoading());

    try {
      final appointment = await _repository.save(event.appointment);
      emit(AppointmentCreated(appointment));

      // Reload appointments to show updated list
      if (_currentPetId != null) {
        add(AppointmentLoadRequested(petId: _currentPetId));
      } else {
        add(const AppointmentLoadRequested());
      }
    } catch (e) {
      emit(AppointmentError(ErrorHandler.getErrorMessage(e)));
    }
  }

  /// Update an existing appointment
  Future<void> _onUpdateRequested(
    AppointmentUpdateRequested event,
    Emitter<AppointmentState> emit,
  ) async {
    emit(const AppointmentLoading());

    try {
      final appointment = await _repository.save(event.appointment);
      emit(AppointmentUpdated(appointment));

      // Reload appointments
      if (_currentPetId != null) {
        add(AppointmentLoadRequested(petId: _currentPetId));
      } else {
        add(const AppointmentLoadRequested());
      }
    } catch (e) {
      emit(AppointmentError(ErrorHandler.getErrorMessage(e)));
    }
  }

  /// Update appointment status
  Future<void> _onStatusUpdateRequested(
    AppointmentStatusUpdateRequested event,
    Emitter<AppointmentState> emit,
  ) async {
    emit(const AppointmentLoading());

    try {
      final appointment = await _repository.updateStatus(
        event.appointmentId,
        event.status,
        cancellationReason: event.cancellationReason,
      );
      emit(AppointmentStatusUpdated(appointment));

      // Reload appointments
      if (_currentPetId != null) {
        add(AppointmentLoadRequested(petId: _currentPetId));
      } else {
        add(const AppointmentLoadRequested());
      }
    } catch (e) {
      emit(AppointmentError(ErrorHandler.getErrorMessage(e)));
    }
  }

  /// Check in appointment
  Future<void> _onCheckInRequested(
    AppointmentCheckInRequested event,
    Emitter<AppointmentState> emit,
  ) async {
    emit(const AppointmentLoading());

    try {
      final appointment = await _repository.checkIn(event.appointmentId);
      emit(AppointmentStatusUpdated(appointment));

      // Reload appointments
      if (_currentPetId != null) {
        add(AppointmentLoadRequested(petId: _currentPetId));
      } else {
        add(const AppointmentLoadRequested());
      }
    } catch (e) {
      emit(AppointmentError(ErrorHandler.getErrorMessage(e)));
    }
  }

  /// Start appointment
  Future<void> _onStartRequested(
    AppointmentStartRequested event,
    Emitter<AppointmentState> emit,
  ) async {
    emit(const AppointmentLoading());

    try {
      final appointment = await _repository.start(event.appointmentId);
      emit(AppointmentStatusUpdated(appointment));

      // Reload appointments
      if (_currentPetId != null) {
        add(AppointmentLoadRequested(petId: _currentPetId));
      } else {
        add(const AppointmentLoadRequested());
      }
    } catch (e) {
      emit(AppointmentError(ErrorHandler.getErrorMessage(e)));
    }
  }

  /// Complete appointment
  Future<void> _onCompleteRequested(
    AppointmentCompleteRequested event,
    Emitter<AppointmentState> emit,
  ) async {
    emit(const AppointmentLoading());

    try {
      final appointment = await _repository.complete(event.appointmentId);
      emit(AppointmentStatusUpdated(appointment));

      // Reload appointments
      if (_currentPetId != null) {
        add(AppointmentLoadRequested(petId: _currentPetId));
      } else {
        add(const AppointmentLoadRequested());
      }
    } catch (e) {
      emit(AppointmentError(ErrorHandler.getErrorMessage(e)));
    }
  }

  /// Cancel appointment
  Future<void> _onCancelRequested(
    AppointmentCancelRequested event,
    Emitter<AppointmentState> emit,
  ) async {
    emit(const AppointmentLoading());

    try {
      final appointment = await _repository.cancel(
        event.appointmentId,
        event.reason,
      );
      emit(AppointmentStatusUpdated(appointment));

      // Reload appointments
      if (_currentPetId != null) {
        add(AppointmentLoadRequested(petId: _currentPetId));
      } else {
        add(const AppointmentLoadRequested());
      }
    } catch (e) {
      emit(AppointmentError(ErrorHandler.getErrorMessage(e)));
    }
  }

  /// Reschedule appointment
  Future<void> _onRescheduleRequested(
    AppointmentRescheduleRequested event,
    Emitter<AppointmentState> emit,
  ) async {
    emit(const AppointmentLoading());

    try {
      final appointment = await _repository.reschedule(
        event.appointmentId,
        event.newTime,
      );
      emit(AppointmentUpdated(appointment));

      // Reload appointments
      if (_currentPetId != null) {
        add(AppointmentLoadRequested(petId: _currentPetId));
      } else {
        add(const AppointmentLoadRequested());
      }
    } catch (e) {
      emit(AppointmentError(ErrorHandler.getErrorMessage(e)));
    }
  }

  /// Delete appointment (soft delete)
  Future<void> _onDeleteRequested(
    AppointmentDeleteRequested event,
    Emitter<AppointmentState> emit,
  ) async {
    emit(const AppointmentLoading());

    try {
      await _repository.softDelete(event.appointmentId);
      emit(AppointmentDeleted(event.appointmentId));

      // Reload appointments
      if (_currentPetId != null) {
        add(AppointmentLoadRequested(petId: _currentPetId));
      } else {
        add(const AppointmentLoadRequested());
      }
    } catch (e) {
      emit(AppointmentError(ErrorHandler.getErrorMessage(e)));
    }
  }

  /// Clear error state
  void _onErrorCleared(
    AppointmentErrorCleared event,
    Emitter<AppointmentState> emit,
  ) {
    emit(AppointmentInitial());
  }

  /// Refresh appointments
  Future<void> _onRefreshRequested(
    AppointmentRefreshRequested event,
    Emitter<AppointmentState> emit,
  ) async {
    if (_currentPetId != null) {
      add(AppointmentLoadRequested(petId: _currentPetId));
    } else {
      add(const AppointmentLoadRequested());
    }
  }
}
