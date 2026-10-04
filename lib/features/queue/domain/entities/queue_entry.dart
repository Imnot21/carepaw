import 'package:equatable/equatable.dart';
import 'package:carepaw/features/appointments/domain/entities/appointment.dart';
import 'package:carepaw/features/pets/domain/entities/pet.dart';
import 'package:carepaw/features/authentication/domain/entities/user.dart';

/// Queue entry entity - domain layer representation
class QueueEntry extends Equatable {
  final int? id;
  final int appointmentId;
  final int position;
  final QueueStatus status;
  final QueuePriority priority;
  final DateTime checkedInAt;
  final DateTime? calledAt;
  final DateTime? roomEnteredAt;
  final DateTime? completedAt;
  final String? room;
  final int? estimatedWaitMinutes;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const QueueEntry({
    this.id,
    required this.appointmentId,
    required this.position,
    this.status = QueueStatus.waiting,
    this.priority = QueuePriority.routine,
    required this.checkedInAt,
    this.calledAt,
    this.roomEnteredAt,
    this.completedAt,
    this.room,
    this.estimatedWaitMinutes,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  /// Check if patient is currently being served
  bool get isBeingServed => status == QueueStatus.inRoom;

  /// Check if patient is waiting
  bool get isWaiting => status == QueueStatus.waiting;

  /// Check if patient has been called
  bool get isCalled => status == QueueStatus.called;

  /// Check if queue entry is completed
  bool get isCompleted => status == QueueStatus.completed;

  /// Check if queue entry is skipped
  bool get isSkipped => status == QueueStatus.skipped;

  /// Check if can check in (must be waiting)
  bool get canCheckIn => status == QueueStatus.waiting;

  /// Check in the patient
  QueueEntry checkIn() {
    if (!canCheckIn) {
      throw Exception('Cannot check in: invalid status');
    }
    return copyWith(
      status: QueueStatus.called,
      calledAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Check if can call (must be waiting)
  bool get canCall => status == QueueStatus.waiting;

  /// Call the patient
  QueueEntry call() {
    if (!canCall) {
      throw Exception('Cannot call: invalid status');
    }
    return copyWith(
      status: QueueStatus.called,
      calledAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Check if can move to room (must be called)
  bool get canMoveToRoom => status == QueueStatus.called;

  /// Move patient to room
  QueueEntry moveToRoom(String room) {
    if (!canMoveToRoom) {
      throw Exception('Cannot move to room: invalid status');
    }
    return copyWith(
      status: QueueStatus.inRoom,
      roomEnteredAt: DateTime.now(),
      room: room,
      updatedAt: DateTime.now(),
    );
  }

  /// Check if can complete (must be in room)
  bool get canComplete => status == QueueStatus.inRoom;

  /// Complete the queue entry
  QueueEntry complete() {
    if (!canComplete) {
      throw Exception('Cannot complete: invalid status');
    }
    return copyWith(
      status: QueueStatus.completed,
      completedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Check if can skip (must be waiting or called)
  bool get canSkip =>
      status == QueueStatus.waiting || status == QueueStatus.called;

  /// Skip the queue entry
  QueueEntry skip() {
    if (!canSkip) {
      throw Exception('Cannot skip: invalid status');
    }
    return copyWith(status: QueueStatus.skipped, updatedAt: DateTime.now());
  }

  @override
  List<Object?> get props => [
    id,
    appointmentId,
    position,
    status,
    priority,
    checkedInAt,
    calledAt,
    roomEnteredAt,
    completedAt,
    room,
    estimatedWaitMinutes,
    notes,
    createdAt,
    updatedAt,
  ];

  QueueEntry copyWith({
    int? id,
    int? appointmentId,
    int? position,
    QueueStatus? status,
    QueuePriority? priority,
    DateTime? checkedInAt,
    DateTime? calledAt,
    DateTime? roomEnteredAt,
    DateTime? completedAt,
    String? room,
    int? estimatedWaitMinutes,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return QueueEntry(
      id: id ?? this.id,
      appointmentId: appointmentId ?? this.appointmentId,
      position: position ?? this.position,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      checkedInAt: checkedInAt ?? this.checkedInAt,
      calledAt: calledAt ?? this.calledAt,
      roomEnteredAt: roomEnteredAt ?? this.roomEnteredAt,
      completedAt: completedAt ?? this.completedAt,
      room: room ?? this.room,
      estimatedWaitMinutes: estimatedWaitMinutes ?? this.estimatedWaitMinutes,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Canonical queue ordering: clinical priority first (emergency → urgent →
  /// routine), then first-come-first-serve by check-in time within a tier.
  ///
  /// This comparator is the single source of truth for queue order and MUST be
  /// used at every sort site (repo `findAll`/`watchAll`/`callNext`/`reposition`,
  /// the BLoC owner-position calculations, and the staff dashboard preview) so
  /// that `callNext` can never disagree with the displayed positions.
  ///
  /// Note: `[position]` is only a recomputed display serial and is deliberately
  /// NOT used here as a sort key.
  static int byQueueOrder(QueueEntry a, QueueEntry b) {
    final byPriority = a.priority.rank.compareTo(b.priority.rank);
    if (byPriority != 0) return byPriority;
    return a.checkedInAt.compareTo(b.checkedInAt);
  }
}

/// Queue status enum
enum QueueStatus {
  waiting('WAITING'),
  called('CALLED'),
  inRoom('IN_ROOM'),
  completed('COMPLETED'),
  skipped('SKIPPED');

  final String value;
  const QueueStatus(this.value);

  static QueueStatus fromString(String value) {
    return QueueStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => QueueStatus.waiting,
    );
  }

  String get displayName {
    switch (this) {
      case QueueStatus.waiting:
        return 'Waiting';
      case QueueStatus.called:
        return 'Called';
      case QueueStatus.inRoom:
        return 'In Room';
      case QueueStatus.completed:
        return 'Completed';
      case QueueStatus.skipped:
        return 'Skipped';
    }
  }
}

/// Clinical priority of a queue entry — staff triage level.
///
/// Emergency ranks above Urgent above Routine. Within a single tier the queue
/// remains first-come-first-serve. New (owner self-)check-ins default to
/// [QueuePriority.routine]; staff may retriage anytime via [QueueEntry.priority].
enum QueuePriority {
  emergency('EMERGENCY'),
  urgent('URGENT'),
  routine('ROUTINE');

  final String value;
  const QueuePriority(this.value);

  static QueuePriority fromString(String value) {
    return QueuePriority.values.firstWhere(
      (p) => p.value == value,
      orElse: () => QueuePriority.routine,
    );
  }

  /// Sort rank: lower sorts first (emergency = 0 … routine = 2).
  int get rank {
    switch (this) {
      case QueuePriority.emergency:
        return 0;
      case QueuePriority.urgent:
        return 1;
      case QueuePriority.routine:
        return 2;
    }
  }

  String get displayName {
    switch (this) {
      case QueuePriority.emergency:
        return 'Emergency';
      case QueuePriority.urgent:
        return 'Urgent';
      case QueuePriority.routine:
        return 'Routine';
    }
  }
}

/// Queue entry with related details
class QueueEntryWithDetails extends Equatable {
  final QueueEntry queueEntry;
  final Appointment appointment;
  final Pet pet;
  final User veterinarian;

  const QueueEntryWithDetails({
    required this.queueEntry,
    required this.appointment,
    required this.pet,
    required this.veterinarian,
  });

  @override
  List<Object?> get props => [queueEntry, appointment, pet, veterinarian];
}
