import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carepaw/features/audit/domain/repositories/audit_log_repository.dart';
import 'package:carepaw/features/audit/presentation/bloc/audit_log_event.dart' as events;
import 'package:carepaw/features/audit/presentation/bloc/audit_log_state.dart' as states;
import 'package:carepaw/core/errors/failures.dart';

/// Audit log BLoC for the admin Audit Logs page.
///
/// Loads the most-recent append-only audit trail and applies optional
/// action/entity filters. No mutation events: audit entries are never
/// edited or deleted (append-only).
class AuditLogBloc extends Bloc<events.AuditLogEvent, states.AuditLogState> {
  final AuditLogRepository _repository;

  AuditLogBloc({required AuditLogRepository auditLogRepository})
      : _repository = auditLogRepository,
        super(const states.AuditLogInitial()) {
    on<events.AuditLogLoadRequested>(_onLoadRequested);
    on<events.AuditLogActionFilterChanged>(_onActionFilterChanged);
    on<events.AuditLogEntityTypeFilterChanged>(_onEntityTypeFilterChanged);
  }

  Future<void> _onLoadRequested(
    events.AuditLogLoadRequested event,
    Emitter<states.AuditLogState> emit,
  ) async {
    emit(const states.AuditLogLoading());
    try {
      var entries = await _repository.findAll();
      if (event.actionFilter != null && event.actionFilter!.isNotEmpty) {
        entries =
            entries.where((log) => log.action == event.actionFilter).take(100).toList();
      }
      if (event.entityTypeFilter != null && event.entityTypeFilter!.isNotEmpty) {
        entries = entries
            .where((log) => log.entityType == event.entityTypeFilter)
            .take(100)
            .toList();
      }
      emit(states.AuditLogLoaded(
        entries: entries,
        actionFilter: event.actionFilter,
        entityTypeFilter: event.entityTypeFilter,
      ));
    } on Failure catch (failure) {
      emit(states.AuditLogError(failure));
    } catch (e) {
      emit(states.AuditLogError(UnexpectedFailure(message: e.toString())));
    }
  }

  Future<void> _onActionFilterChanged(
    events.AuditLogActionFilterChanged event,
    Emitter<states.AuditLogState> emit,
  ) async {
    final current = state is states.AuditLogLoaded
        ? (state as states.AuditLogLoaded).actionFilter
        : null;
    final next = event.action == current ? null : event.action;
    add(events.AuditLogLoadRequested(
      actionFilter: next,
      entityTypeFilter: state is states.AuditLogLoaded
          ? (state as states.AuditLogLoaded).entityTypeFilter
          : null,
    ));
  }

  Future<void> _onEntityTypeFilterChanged(
    events.AuditLogEntityTypeFilterChanged event,
    Emitter<states.AuditLogState> emit,
  ) async {
    final current = state is states.AuditLogLoaded
        ? (state as states.AuditLogLoaded).entityTypeFilter
        : null;
    final next = event.entityType == current ? null : event.entityType;
    add(events.AuditLogLoadRequested(
      actionFilter: state is states.AuditLogLoaded
          ? (state as states.AuditLogLoaded).actionFilter
          : null,
      entityTypeFilter: next,
    ));
  }
}