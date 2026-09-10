import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carepaw/features/queue/presentation/bloc/queue_event.dart';
import 'package:carepaw/features/queue/presentation/bloc/queue_state.dart';
import 'package:carepaw/features/queue/domain/repositories/queue_repository.dart';
import 'package:carepaw/features/queue/domain/entities/queue_entry.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_state.dart';
import 'package:carepaw/features/authentication/domain/entities/user.dart';

/// Queue BLoC for managing queue state
class QueueBloc extends Bloc<QueueEvent, QueueState> {
  final QueueRepository _repository;
  final AuthBloc _authBloc;
  Stream<List<QueueEntryWithDetails>>? _queueStream;

  QueueBloc({
    required QueueRepository repository,
    required AuthBloc authBloc,
  }) : _repository = repository,
       _authBloc = authBloc,
       super(QueueInitial()) {
    on<QueueLoadRequested>(_onLoadRequested);
    on<QueueStaffLoadRequested>(_onStaffLoadRequested);
    on<QueueWatchRequested>(_onWatchRequested);
    on<QueueCheckInRequested>(_onCheckInRequested);
    on<QueueCallNextRequested>(_onCallNextRequested);
    on<QueueMoveToRoomRequested>(_onMoveToRoomRequested);
    on<QueueCompleteRequested>(_onCompleteRequested);
    on<QueueSkipRequested>(_onSkipRequested);
    on<QueueRepositionRequested>(_onRepositionRequested);
    on<QueueErrorCleared>(_onErrorCleared);
  }

  /// Load queue for pet owner (filtered to their pets)
  Future<void> _onLoadRequested(
    QueueLoadRequested event,
    Emitter<QueueState> emit,
  ) async {
    emit(QueueLoading());
    try {
      final authState = _authBloc.state;
      if (authState is! AuthAuthenticated) {
        emit(const QueueError('Not authenticated'));
        return;
      }

      final ownerId = authState.user.id!;
      final allQueue = await _repository.getCurrentQueue();

      // Filter queue entries for this owner's pets
      final userQueue = allQueue
          .where((entry) => entry.pet.ownerId == ownerId)
          .toList();

      // Calculate user's position
      final waitingEntries = allQueue
          .where((e) =>
              e.queueEntry.status == QueueStatus.waiting ||
              e.queueEntry.status == QueueStatus.called)
          .toList()
        ..sort((a, b) => a.queueEntry.position.compareTo(b.queueEntry.position));

      int? userPosition;
      int? petsAhead;

      for (int i = 0; i < waitingEntries.length; i++) {
        if (waitingEntries[i].pet.ownerId == ownerId) {
          userPosition = i + 1;
          petsAhead = i;
          break;
        }
      }

      emit(QueueLoaded(
        queueEntries: userQueue,
        userPosition: userPosition,
        petsAhead: petsAhead,
      ));
    } catch (e) {
      emit(QueueError('Failed to load queue: $e'));
    }
  }

  /// Load queue for staff (all patients)
  Future<void> _onStaffLoadRequested(
    QueueStaffLoadRequested event,
    Emitter<QueueState> emit,
  ) async {
    emit(QueueLoading());
    try {
      final queueEntries = await _repository.getCurrentQueue();
      _calculateStaffStats(queueEntries, emit);
    } catch (e) {
      emit(QueueError('Failed to load queue: $e'));
    }
  }

  /// Watch queue for real-time updates
  Future<void> _onWatchRequested(
    QueueWatchRequested event,
    Emitter<QueueState> emit,
  ) async {
    try {
      final authState = _authBloc.state;
      final isStaff = authState is AuthAuthenticated &&
          (authState.user.role == UserRole.staff ||
              authState.user.role == UserRole.veterinarian ||
              authState.user.role == UserRole.admin);

      _queueStream = _repository.watchCurrentQueue();
      await for (final queueEntries in _queueStream!) {
        if (isStaff) {
          _calculateStaffStats(queueEntries, emit);
        } else if (authState is AuthAuthenticated) {
          final ownerId = authState.user.id!;
          final userQueue = queueEntries
              .where((entry) => entry.pet.ownerId == ownerId)
              .toList();

          final waitingEntries = queueEntries
              .where((e) =>
                  e.queueEntry.status == QueueStatus.waiting ||
                  e.queueEntry.status == QueueStatus.called)
              .toList()
            ..sort((a, b) => a.queueEntry.position.compareTo(b.queueEntry.position));

          int? userPosition;
          int? petsAhead;

          for (int i = 0; i < waitingEntries.length; i++) {
            if (waitingEntries[i].pet.ownerId == ownerId) {
              userPosition = i + 1;
              petsAhead = i;
              break;
            }
          }

          emit(QueueLoaded(
            queueEntries: userQueue,
            userPosition: userPosition,
            petsAhead: petsAhead,
          ));
        }
      }
    } catch (e) {
      emit(QueueError('Failed to watch queue: $e'));
    }
  }

  /// Check an upcoming appointment into the queue (pet owner).
  Future<void> _onCheckInRequested(
    QueueCheckInRequested event,
    Emitter<QueueState> emit,
  ) async {
    try {
      await _repository.checkIn(event.appointmentId);
      emit(const QueueOperationSuccess("Checked in, you're in the queue!"));
      add(const QueueLoadRequested());
    } catch (e) {
      emit(QueueError('Failed to check in: $e'));
    }
  }

  /// Call next patient (staff)
  Future<void> _onCallNextRequested(
    QueueCallNextRequested event,
    Emitter<QueueState> emit,
  ) async {
    try {
      final result = await _repository.callNext();
      if (result != null) {
        emit(QueueOperationSuccess('Patient called'));
        // Reload queue
        add(QueueStaffLoadRequested());
      } else {
        emit(const QueueError('No waiting patients'));
      }
    } catch (e) {
      emit(QueueError('Failed to call next: $e'));
    }
  }

  /// Move patient to room (staff)
  Future<void> _onMoveToRoomRequested(
    QueueMoveToRoomRequested event,
    Emitter<QueueState> emit,
  ) async {
    try {
      await _repository.moveToRoom(event.queueId, event.room);
      emit(QueueOperationSuccess('Patient moved to room'));
      add(QueueStaffLoadRequested());
    } catch (e) {
      emit(QueueError('Failed to move to room: $e'));
    }
  }

  /// Complete queue entry (staff)
  Future<void> _onCompleteRequested(
    QueueCompleteRequested event,
    Emitter<QueueState> emit,
  ) async {
    try {
      await _repository.complete(event.queueId);
      emit(QueueOperationSuccess('Visit completed'));
      add(QueueStaffLoadRequested());
    } catch (e) {
      emit(QueueError('Failed to complete: $e'));
    }
  }

  /// Skip patient (staff)
  Future<void> _onSkipRequested(
    QueueSkipRequested event,
    Emitter<QueueState> emit,
  ) async {
    try {
      await _repository.skip(event.queueId);
      emit(QueueOperationSuccess('Patient skipped'));
      add(QueueStaffLoadRequested());
    } catch (e) {
      emit(QueueError('Failed to skip: $e'));
    }
  }

  /// Reposition queue (staff)
  Future<void> _onRepositionRequested(
    QueueRepositionRequested event,
    Emitter<QueueState> emit,
  ) async {
    try {
      await _repository.repositionQueue();
      add(QueueStaffLoadRequested());
    } catch (e) {
      emit(QueueError('Failed to reposition queue: $e'));
    }
  }

  /// Clear error state
  void _onErrorCleared(
    QueueErrorCleared event,
    Emitter<QueueState> emit,
  ) {
    if (state is QueueError) {
      emit(QueueInitial());
    }
  }

  void _calculateStaffStats(
    List<QueueEntryWithDetails> queueEntries,
    Emitter<QueueState> emit,
  ) {
    final sortedEntries = List<QueueEntryWithDetails>.from(queueEntries)
      ..sort((a, b) => a.queueEntry.position.compareTo(b.queueEntry.position));

    int currentServing = 0;
    int totalWaiting = 0;
    int totalInRoom = 0;

    for (final entry in sortedEntries) {
      switch (entry.queueEntry.status) {
        case QueueStatus.waiting:
          if (currentServing == 0) currentServing = entry.queueEntry.position;
          totalWaiting++;
          break;
        case QueueStatus.called:
          if (currentServing == 0) currentServing = entry.queueEntry.position;
          totalWaiting++;
          break;
        case QueueStatus.inRoom:
          if (currentServing == 0) currentServing = entry.queueEntry.position;
          totalInRoom++;
          break;
        case QueueStatus.completed:
        case QueueStatus.skipped:
          break;
      }
    }

    emit(QueueStaffLoaded(
      queueEntries: sortedEntries,
      currentServing: currentServing,
      totalWaiting: totalWaiting,
      totalInRoom: totalInRoom,
    ));
  }

  @override
  Future<void> close() {
    _queueStream = null;
    return super.close();
  }
}