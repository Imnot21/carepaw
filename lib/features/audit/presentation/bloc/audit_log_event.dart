import 'package:equatable/equatable.dart';

/// Events for the audit log BLoC.
abstract class AuditLogEvent extends Equatable {
  const AuditLogEvent();

  @override
  List<Object?> get props => [];
}

/// Load the most recent audit entries.
class AuditLogLoadRequested extends AuditLogEvent {
  final String? actionFilter;
  final String? entityTypeFilter;

  const AuditLogLoadRequested({this.actionFilter, this.entityTypeFilter});

  @override
  List<Object?> get props => [actionFilter, entityTypeFilter];
}

/// Apply/remove an action filter and reload.
class AuditLogActionFilterChanged extends AuditLogEvent {
  final String? action;

  const AuditLogActionFilterChanged(this.action);

  @override
  List<Object?> get props => [action];
}

/// Apply/remove an entity-type filter and reload.
class AuditLogEntityTypeFilterChanged extends AuditLogEvent {
  final String? entityType;

  const AuditLogEntityTypeFilterChanged(this.entityType);

  @override
  List<Object?> get props => [entityType];
}
