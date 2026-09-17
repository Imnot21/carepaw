import 'package:equatable/equatable.dart';
import 'package:carepaw/features/authentication/domain/entities/user.dart';

/// Base class for user management events.
abstract class UserManagementEvent extends Equatable {
  const UserManagementEvent();

  @override
  List<Object?> get props => [];
}

/// Load the manageable user list (staff + veterinarians).
class UserManagementLoadRequested extends UserManagementEvent {
  const UserManagementLoadRequested();
}

/// Create a new staff / veterinarian / pet-owner account (admin action).
class UserManagementCreateRequested extends UserManagementEvent {
  final String email;
  final String password;
  final String fullName;
  final String? phone;
  final UserRole role;

  const UserManagementCreateRequested({
    required this.email,
    required this.password,
    required this.fullName,
    this.phone,
    required this.role,
  });

  @override
  List<Object?> get props => [email, password, fullName, phone, role];
}

/// Change a user's role.
class UserManagementChangeRoleRequested extends UserManagementEvent {
  final int userId;
  final UserRole newRole;

  const UserManagementChangeRoleRequested({
    required this.userId,
    required this.newRole,
  });

  @override
  List<Object?> get props => [userId, newRole];
}

/// Toggle a user's active status.
class UserManagementToggleActiveRequested extends UserManagementEvent {
  final int userId;
  final bool isActive;

  const UserManagementToggleActiveRequested({
    required this.userId,
    required this.isActive,
  });

  @override
  List<Object?> get props => [userId, isActive];
}

/// Permanently delete a user account (admin action).
///
/// Delegates to the backend `deleteUser` Cloud Function, which revokes the
/// target's Firebase Auth credential (freeing the email) and removes the
/// Firestore document. The UI shows a confirmation dialog before dispatching.
class UserManagementDeleteRequested extends UserManagementEvent {
  final int userId;

  const UserManagementDeleteRequested({required this.userId});

  @override
  List<Object?> get props => [userId];
}