import 'package:equatable/equatable.dart';
import 'package:carepaw/features/authentication/domain/entities/user.dart';
import 'package:carepaw/core/errors/failures.dart';

/// Base class for user management states.
abstract class UserManagementState extends Equatable {
  const UserManagementState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any load.
class UserManagementInitial extends UserManagementState {
  const UserManagementInitial();
}

/// Loading state while fetching users.
class UserManagementLoading extends UserManagementState {
  const UserManagementLoading();
}

/// Comfortably-loaded state with the user list (staff + veterinarians).
class UserManagementLoaded extends UserManagementState {
  final List<User> users;

  const UserManagementLoaded(this.users);

  @override
  List<Object?> get props => [users];
}

/// Action (create / change role / toggle active) succeeded.
class UserManagementActionSuccess extends UserManagementState {
  final String message;

  const UserManagementActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

/// Error state with failure information.
class UserManagementError extends UserManagementState {
  final Failure failure;

  const UserManagementError(this.failure);

  @override
  List<Object?> get props => [failure];
}