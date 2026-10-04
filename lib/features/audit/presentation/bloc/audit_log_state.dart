import 'package:equatable/equatable.dart';
import 'package:carepaw/core/errors/failures.dart';
import 'package:carepaw/features/audit/domain/entities/audit_log.dart';

/// Base class for audit log states.
abstract class AuditLogState extends Equatable {
  const AuditLogState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any load.
class AuditLogInitial extends AuditLogState {
  const AuditLogInitial();
}

/// Loading state while fetching entries.
class AuditLogLoading extends AuditLogState {
  const AuditLogLoading();
}

/// Loaded state with the current (most-recent-first) entries.
///
/// Carries the entries plus the applied filters so the page can re-render a
/// filtered view and show the active filter state.
class AuditLogLoaded extends AuditLogState {
  final List<AuditLog> entries;
  final String? actionFilter;
  final String? entityTypeFilter;

  const AuditLogLoaded({
    required this.entries,
    this.actionFilter,
    this.entityTypeFilter,
  });

  @override
  List<Object?> get props => [entries, actionFilter, entityTypeFilter];
}

/// Error state with failure information.
class AuditLogError extends AuditLogState {
  final Failure failure;

  const AuditLogError(this.failure);

  @override
  List<Object?> get props => [failure];
}
