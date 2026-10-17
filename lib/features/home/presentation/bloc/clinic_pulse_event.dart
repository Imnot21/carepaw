import 'package:equatable/equatable.dart';

/// Base class for all clinic pulse events.
abstract class ClinicPulseEvent extends Equatable {
  const ClinicPulseEvent();

  @override
  List<Object?> get props => [];
}

/// Load the clinic pulse for the first time.
class ClinicPulseStarted extends ClinicPulseEvent {
  const ClinicPulseStarted();
}

/// Reload the pulse counters (pull-to-refresh).
class ClinicPulseRefreshRequested extends ClinicPulseEvent {
  const ClinicPulseRefreshRequested();
}
