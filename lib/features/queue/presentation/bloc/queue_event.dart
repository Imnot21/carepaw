import 'package:equatable/equatable.dart';

/// Base class for all queue events
abstract class QueueEvent extends Equatable {
  const QueueEvent();

  @override
  List<Object?> get props => [];
}

/// Load current queue for the user (pet owner view)
class QueueLoadRequested extends QueueEvent {
  const QueueLoadRequested();
}

/// Load current queue for staff view (all patients)
class QueueStaffLoadRequested extends QueueEvent {
  const QueueStaffLoadRequested();
}

/// Watch current queue for real-time updates
class QueueWatchRequested extends QueueEvent {
  const QueueWatchRequested();
}

/// Call next patient (staff action)
class QueueCallNextRequested extends QueueEvent {
  const QueueCallNextRequested();
}

/// Move patient to room (staff action)
class QueueMoveToRoomRequested extends QueueEvent {
  final int queueId;
  final String room;

  const QueueMoveToRoomRequested(this.queueId, this.room);

  @override
  List<Object?> get props => [queueId, room];
}

/// Complete queue entry (staff action)
class QueueCompleteRequested extends QueueEvent {
  final int queueId;

  const QueueCompleteRequested(this.queueId);

  @override
  List<Object?> get props => [queueId];
}

/// Skip patient (staff action)
class QueueSkipRequested extends QueueEvent {
  final int queueId;

  const QueueSkipRequested(this.queueId);

  @override
  List<Object?> get props => [queueId];
}

/// Check in an appointment into the queue (pet owner).
class QueueCheckInRequested extends QueueEvent {
  final int appointmentId;

  const QueueCheckInRequested(this.appointmentId);

  @override
  List<Object?> get props => [appointmentId];
}

/// Reposition queue after changes (staff action)
class QueueRepositionRequested extends QueueEvent {
  const QueueRepositionRequested();
}

/// Clear error state
class QueueErrorCleared extends QueueEvent {
  const QueueErrorCleared();
}