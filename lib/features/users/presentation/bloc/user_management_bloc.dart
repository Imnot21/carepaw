import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carepaw/core/di/dependency_injection.dart';
import 'package:carepaw/features/authentication/domain/entities/user.dart';
import 'package:carepaw/features/users/domain/repositories/user_repository.dart';
import 'package:carepaw/features/users/presentation/bloc/user_management_event.dart' as events;
import 'package:carepaw/features/users/presentation/bloc/user_management_state.dart' as states;
import 'package:carepaw/core/errors/failures.dart';

/// User management BLoC for the admin's Users page.
///
/// Handles loading the staff/veterinarian list, creating new accounts
/// (via the Firestore-backed [UserRepository.createAccount]), changing roles,
/// and toggling active status. Keeps business logic out of the widgets.
class UserManagementBloc extends Bloc<events.UserManagementEvent, states.UserManagementState> {
  final UserRepository _userRepository;

  UserManagementBloc({UserRepository? userRepository})
      : _userRepository = userRepository ?? getIt<UserRepository>(),
        super(const states.UserManagementInitial()) {
    on<events.UserManagementLoadRequested>(_onLoadRequested);
    on<events.UserManagementCreateRequested>(_onCreateRequested);
    on<events.UserManagementChangeRoleRequested>(_onChangeRoleRequested);
    on<events.UserManagementToggleActiveRequested>(_onToggleActiveRequested);
  }

  /// Load staff + veterinarian accounts for management.
  Future<void> _onLoadRequested(
    events.UserManagementLoadRequested event,
    Emitter<states.UserManagementState> emit,
  ) async {
    emit(const states.UserManagementLoading());
    try {
      final staff = await _userRepository.findByRole(UserRole.staff);
      final vets = await _userRepository.findByRole(UserRole.veterinarian);
      emit(states.UserManagementLoaded([...staff, ...vets]));
    } on Failure catch (failure) {
      emit(states.UserManagementError(failure));
    } catch (e) {
      emit(states.UserManagementError(UnexpectedFailure(message: e.toString())));
    }
  }

  /// Create a new staff / veterinarian / pet-owner account.
  Future<void> _onCreateRequested(
    events.UserManagementCreateRequested event,
    Emitter<states.UserManagementState> emit,
  ) async {
    emit(const states.UserManagementLoading());
    try {
      await _userRepository.createAccount(
        email: event.email.trim().toLowerCase(),
        password: event.password,
        fullName: event.fullName.trim(),
        phone: event.phone?.trim(),
        role: event.role,
      );
      emit(const states.UserManagementActionSuccess(
        'Account created. The user can now sign in with these credentials.',
      ));
      // Refresh the list to include the new account.
      add(const events.UserManagementLoadRequested());
    } on Failure catch (failure) {
      emit(states.UserManagementError(failure));
    } catch (e) {
      emit(states.UserManagementError(UnexpectedFailure(message: e.toString())));
    }
  }

  /// Change a user's role.
  Future<void> _onChangeRoleRequested(
    events.UserManagementChangeRoleRequested event,
    Emitter<states.UserManagementState> emit,
  ) async {
    try {
      await _userRepository.changeRole(event.userId, event.newRole);
      emit(states.UserManagementActionSuccess(
        'Role updated to ${event.newRole.displayName}.',
      ));
      add(const events.UserManagementLoadRequested());
    } on Failure catch (failure) {
      emit(states.UserManagementError(failure));
    } catch (e) {
      emit(states.UserManagementError(UnexpectedFailure(message: e.toString())));
    }
  }

  /// Toggle a user's active status.
  Future<void> _onToggleActiveRequested(
    events.UserManagementToggleActiveRequested event,
    Emitter<states.UserManagementState> emit,
  ) async {
    try {
      await _userRepository.setActive(event.userId, event.isActive);
      emit(states.UserManagementActionSuccess(
        event.isActive ? 'User re-activated.' : 'User de-activated.',
      ));
      add(const events.UserManagementLoadRequested());
    } on Failure catch (failure) {
      emit(states.UserManagementError(failure));
    } catch (e) {
      emit(states.UserManagementError(UnexpectedFailure(message: e.toString())));
    }
  }
}