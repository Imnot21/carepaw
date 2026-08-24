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
  bool get canSkip => status == QueueStatus.waiting || status == QueueStatus.called;

  /// Skip the queue entry
  QueueEntry skip() {
    if (!canSkip) {
      throw Exception('Cannot skip: invalid status');
    }
    return copyWith(
      status: QueueStatus.skipped,
      updatedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        appointmentId,
        position,
        status,
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