import 'package:equatable/equatable.dart';
import 'package:carepaw/features/queue/domain/entities/queue_entry.dart';

/// Base class for all queue states
abstract class QueueState extends Equatable {
  const QueueState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class QueueInitial extends QueueState {}

/// Loading state
class QueueLoading extends QueueState {}

// Queue loaded state (for pet owner view - filtered to their pets)
class QueueLoaded extends QueueState {
  final List<QueueEntryWithDetails> queueEntries;
  final int? userPosition; // Pet owner's position in queue
  final int? petsAhead; // Number of pets ahead
  final bool higherPriorityAhead; // A triaged (urgent/emergency) entry precedes this owner

  const QueueLoaded({
    required this.queueEntries,
    this.userPosition,
    this.petsAhead,
    this.higherPriorityAhead = false,
  });

  @override
  List<Object?> get props => [queueEntries, userPosition, petsAhead, higherPriorityAhead];

  QueueLoaded copyWith({
    List<QueueEntryWithDetails>? queueEntries,
    int? userPosition,
    int? petsAhead,
    bool? higherPriorityAhead,
  }) {
    return QueueLoaded(
      queueEntries: queueEntries ?? this.queueEntries,
      userPosition: userPosition ?? this.userPosition,
      petsAhead: petsAhead ?? this.petsAhead,
      higherPriorityAhead: higherPriorityAhead ?? this.higherPriorityAhead,
    );
  }
}

/// Staff queue loaded state (all patients with full details)
class QueueStaffLoaded extends QueueState {
  final List<QueueEntryWithDetails> queueEntries;
  final int currentServing; // Position currently being served
  final int totalWaiting;
  final int totalInRoom;

  const QueueStaffLoaded({
    required this.queueEntries,
    required this.currentServing,
    required this.totalWaiting,
    required this.totalInRoom,
  });

  @override
  List<Object?> get props => [queueEntries, currentServing, totalWaiting, totalInRoom];

  QueueStaffLoaded copyWith({
    List<QueueEntryWithDetails>? queueEntries,
    int? currentServing,
    int? totalWaiting,
    int? totalInRoom,
  }) {
    return QueueStaffLoaded(
      queueEntries: queueEntries ?? this.queueEntries,
      currentServing: currentServing ?? this.currentServing,
      totalWaiting: totalWaiting ?? this.totalWaiting,
      totalInRoom: totalInRoom ?? this.totalInRoom,
    );
  }
}

/// Queue error state
class QueueError extends QueueState {
  final String message;

  const QueueError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Queue operation success state
class QueueOperationSuccess extends QueueState {
  final String message;

  const QueueOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}