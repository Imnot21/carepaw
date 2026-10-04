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
///
/// Carries the previous list through the loading phase so the page keeps
/// filtering and pagination visible while a create/role/active mutation reloads.
class UserManagementLoaded extends UserManagementState {
  final List<User> users;

  const UserManagementLoaded(this.users);

  @override
  List<Object?> get props => [users];
}

/// Mutation in flight — still holds the last good list so the page does not
/// lose search/filter/pagination while the re-load fires.
class UserManagementMutating extends UserManagementState {
  final List<User> users;

  const UserManagementMutating(this.users);

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
///
/// Carries the previous list so the page does not lose its filtered view
/// when a transient mutation fails; the listener surfaces the failure as a
/// SnackBar and the page re-dispatches a load to refresh.
class UserManagementError extends UserManagementState {
  final Failure failure;
  final List<User> users;

  const UserManagementError(this.failure, [this.users = const []]);

  @override
  List<Object?> get props => [failure, users];
}
