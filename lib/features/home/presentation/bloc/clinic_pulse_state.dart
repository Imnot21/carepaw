import 'package:equatable/equatable.dart';

/// Where the pulse counters are in their load cycle.
enum ClinicPulseStatus { initial, loading, ready }

/// Snapshot of the clinic's state at a glance.
///
/// A counter is `null` while unknown — still loading, or its source failed on
/// first load. The strip renders those as a dash rather than a fake zero.
/// During a refresh, a source that fails simply keeps its previous value.
class ClinicPulseState extends Equatable {
  final ClinicPulseStatus status;

  /// Patients in line: waiting or called — the same definition the Line
  /// board's own counter uses.
  final int? waiting;

  /// Appointments scheduled for today, cancelled excluded.
  final int? todayBookings;

  /// Stock items at or below their minimum level.
  final int? lowStock;

  /// Increments once per completed load cycle, so pull-to-refresh can await
  /// the emission that reflects its own reload.
  final int revision;

  const ClinicPulseState({
    this.status = ClinicPulseStatus.initial,
    this.waiting,
    this.todayBookings,
    this.lowStock,
    this.revision = 0,
  });

  ClinicPulseState copyWith({
    ClinicPulseStatus? status,
    int? waiting,
    int? todayBookings,
    int? lowStock,
    int? revision,
  }) {
    return ClinicPulseState(
      status: status ?? this.status,
      waiting: waiting ?? this.waiting,
      todayBookings: todayBookings ?? this.todayBookings,
      lowStock: lowStock ?? this.lowStock,
      revision: revision ?? this.revision,
    );
  }

  @override
  List<Object?> get props => [
    status,
    waiting,
    todayBookings,
    lowStock,
    revision,
  ];
}
