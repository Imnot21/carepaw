import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:carepaw/features/appointments/domain/entities/appointment.dart';
import 'package:carepaw/features/appointments/domain/repositories/appointment_repository.dart';
import 'package:carepaw/features/home/presentation/bloc/clinic_pulse_event.dart';
import 'package:carepaw/features/home/presentation/bloc/clinic_pulse_state.dart';
import 'package:carepaw/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:carepaw/features/queue/domain/repositories/queue_repository.dart';

/// Loads the clinic's at-a-glance counters for the operator dashboard.
///
/// Each counter is independent: a source that fails leaves its value unknown
/// (the strip shows a dash) without taking the other two down with it, and a
/// refresh simply re-runs all three.
class ClinicPulseBloc extends Bloc<ClinicPulseEvent, ClinicPulseState> {
  final QueueRepository _queueRepository;
  final AppointmentRepository _appointmentRepository;
  final InventoryItemRepository _inventoryRepository;

  ClinicPulseBloc({
    required this._queueRepository,
    required this._appointmentRepository,
    required this._inventoryRepository,
  }) : super(const ClinicPulseState()) {
    on<ClinicPulseStarted>(_onStarted);
    on<ClinicPulseRefreshRequested>(_onRefresh);
  }

  Future<void> _onStarted(
    ClinicPulseStarted event,
    Emitter<ClinicPulseState> emit,
  ) async {
    emit(state.copyWith(status: ClinicPulseStatus.loading));
    await _load(emit);
  }

  Future<void> _onRefresh(
    ClinicPulseRefreshRequested event,
    Emitter<ClinicPulseState> emit,
  ) async {
    await _load(emit);
  }

  Future<void> _load(Emitter<ClinicPulseState> emit) async {
    final (waiting, todayBookings, lowStock) = await (
      _countWaiting(),
      _countTodayBookings(),
      _countLowStock(),
    ).wait;

    emit(
      state.copyWith(
        status: ClinicPulseStatus.ready,
        waiting: waiting,
        todayBookings: todayBookings,
        lowStock: lowStock,
        revision: state.revision + 1,
      ),
    );
  }

  Future<int?> _countWaiting() async {
    try {
      final entries = await _queueRepository.getCurrentQueue();
      // Called patients are still in line — same definition as the Line board.
      return entries
          .where((e) => e.queueEntry.isWaiting || e.queueEntry.isCalled)
          .length;
    } catch (e) {
      debugPrint('[ClinicPulseBloc] waiting count failed: $e');
      return null;
    }
  }

  Future<int?> _countTodayBookings() async {
    try {
      final appointments = await _appointmentRepository.findAllWithPetDetails();
      return appointments
          .where(
            (a) =>
                a.appointment.isToday &&
                a.appointment.status != AppointmentStatus.cancelled,
          )
          .length;
    } catch (e) {
      debugPrint('[ClinicPulseBloc] bookings count failed: $e');
      return null;
    }
  }

  Future<int?> _countLowStock() async {
    try {
      final items = await _inventoryRepository.findLowStock();
      return items.length;
    } catch (e) {
      debugPrint('[ClinicPulseBloc] low stock count failed: $e');
      return null;
    }
  }
}
