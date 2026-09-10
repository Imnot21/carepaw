import 'package:equatable/equatable.dart';

/// Audit log entity - domain layer representation.
///
/// Records a sensitive operation (account creation, role change, activation
/// toggle, ...) for the admin Audit Logs surface. Entries are strictly
/// append-only: they are written once and never edited or deleted, matching
/// the "Always log sensitive operations - audit trail required" constraint.
class AuditLog extends Equatable {
  final int? id;
  final int userId;
  final String action;
  final String entityType;
  final String entityId;
  final Map<String, dynamic>? oldValues;
  final Map<String, dynamic>? newValues;
  final DateTime createdAt;

  const AuditLog({
    this.id,
    required this.userId,
    required this.action,
    required this.entityType,
    required this.entityId,
    this.oldValues,
    this.newValues,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        action,
        entityType,
        entityId,
        oldValues,
        newValues,
        createdAt,
      ];

  AuditLog copyWith({
    int? id,
    int? userId,
    String? action,
    String? entityType,
    String? entityId,
    Map<String, dynamic>? oldValues,
    Map<String, dynamic>? newValues,
    DateTime? createdAt,
  }) {
    return AuditLog(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      action: action ?? this.action,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      oldValues: oldValues ?? this.oldValues,
      newValues: newValues ?? this.newValues,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}