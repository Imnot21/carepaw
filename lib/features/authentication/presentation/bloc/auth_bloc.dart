import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carepaw/features/authentication/domain/repositories/auth_repository.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_event.dart' as events;
import 'package:carepaw/features/authentication/presentation/bloc/auth_state.dart' as states;
import 'package:carepaw/core/errors/failures.dart';

/// Authentication BLoC for managing auth state.
///
/// Handles login, registration, logout, session restoration,
/// token refresh, and password management.
class AuthBloc extends Bloc<events.AuthEvent, states.AuthState> {
  final AuthRepository _authRepository;

  AuthBloc({required this._authRepository})
      : super(const states.AuthInitial()) {
    on<events.AuthLoginRequested>(_onLoginRequested);
    on<events.AuthRegisterRequested>(_onRegisterRequested);
    on<events.AuthLogoutRequested>(_onLogoutRequested);
    on<events.AuthCheckRequested>(_onCheckRequested);
    on<events.AuthTokenRefreshed>(_onTokenRefreshed);
    on<events.AuthPasswordChanged>(_onPasswordChanged);
    on<events.AuthForgotPasswordRequested>(_onForgotPasswordRequested);
    on<events.AuthResetPasswordRequested>(_onResetPasswordRequested);
    on<events.AuthBiometricRequested>(_onBiometricRequested);

    // Listen to auth state stream from repository
    _authRepository.authStateStream.listen((authResult) {
      if (authResult != null) {
        emit(states.AuthAuthenticated(authResult));
      } else {
        emit(const states.AuthUnauthenticated());
      }
    });
  }

  /// Handle login request
  Future<void> _onLoginRequested(
    events.AuthLoginRequested event,
    Emitter<states.AuthState> emit,
  ) async {
    emit(const states.AuthLoading());
    try {
      final authResult = await _authRepository.login(
        email: event.email.trim().toLowerCase(),
        password: event.password,
      );
      emit(states.AuthAuthenticated(authResult));
    } on Failure catch (failure) {
      emit(states.AuthError(failure));
    } catch (e) {
      emit(states.AuthError(UnexpectedFailure(message: e.toString())));
    }
  }

  /// Handle registration request
  Future<void> _onRegisterRequested(
    events.AuthRegisterRequested event,
    Emitter<states.AuthState> emit,
  ) async {
    emit(const states.AuthLoading());
    try {
      final authResult = await _authRepository.register(
        email: event.email.trim().toLowerCase(),
        password: event.password,
        fullName: event.fullName.trim(),
        phone: event.phone?.trim(),
        role: event.role,
      );
      emit(states.AuthAuthenticated(authResult));
    } on Failure catch (failure) {
      emit(states.AuthError(failure));
    } catch (e) {
      emit(states.AuthError(UnexpectedFailure(message: e.toString())));
    }
  }

  /// Handle logout request
  Future<void> _onLogoutRequested(
    events.AuthLogoutRequested event,
    Emitter<states.AuthState> emit,
  ) async {
    emit(const states.AuthLoading());
    try {
      await _authRepository.logout();
      emit(const states.AuthUnauthenticated());
    } on Failure catch (failure) {
      emit(states.AuthError(failure));
    } catch (e) {
      emit(states.AuthError(UnexpectedFailure(message: e.toString())));
    }
  }

  /// Handle session check (app startup)
  Future<void> _onCheckRequested(
    events.AuthCheckRequested event,
    Emitter<states.AuthState> emit,
  ) async {
    emit(const states.AuthLoading());
    try {
      final authResult = await _authRepository.getCurrentUser();
      if (authResult != null) {
        emit(states.AuthAuthenticated(authResult));
      } else {
        emit(const states.AuthUnauthenticated());
      }
    } catch (e) {
      emit(states.AuthError(UnexpectedFailure(message: e.toString())));
    }
  }

  /// Handle token refresh
  Future<void> _onTokenRefreshed(
    events.AuthTokenRefreshed event,
    Emitter<states.AuthState> emit,
  ) async {
    try {
      final authResult = await _authRepository.refreshToken();
      emit(states.AuthAuthenticated(authResult));
    } on Failure catch (failure) {
      // If refresh fails, logout
      await _authRepository.logout();
      emit(states.AuthError(failure));
    } catch (e) {
      await _authRepository.logout();
      emit(states.AuthError(UnexpectedFailure(message: e.toString())));
    }
  }

  /// Handle password change
  Future<void> _onPasswordChanged(
    events.AuthPasswordChanged event,
    Emitter<states.AuthState> emit,
  ) async {
    emit(const states.AuthLoading());
    try {
      await _authRepository.changePassword(
        currentPassword: event.currentPassword,
        newPassword: event.newPassword,
      );
      emit(const states.AuthPasswordChanged());
    } on Failure catch (failure) {
      emit(states.AuthError(failure));
    } catch (e) {
      emit(states.AuthError(UnexpectedFailure(message: e.toString())));
    }
  }

  /// Handle forgot password request
  Future<void> _onForgotPasswordRequested(
    events.AuthForgotPasswordRequested event,
    Emitter<states.AuthState> emit,
  ) async {
    emit(const states.AuthLoading());
    try {
      await _authRepository.forgotPassword(event.email.trim().toLowerCase());
      emit(const states.AuthForgotPasswordSent());
    } on Failure catch (failure) {
      emit(states.AuthError(failure));
    } catch (e) {
      emit(states.AuthError(UnexpectedFailure(message: e.toString())));
    }
  }

  /// Handle password reset
  Future<void> _onResetPasswordRequested(
    events.AuthResetPasswordRequested event,
    Emitter<states.AuthState> emit,
  ) async {
    emit(const states.AuthLoading());
    try {
      await _authRepository.resetPassword(
        token: event.token,
        newPassword: event.newPassword,
      );
      emit(const states.AuthPasswordReset());
    } on Failure catch (failure) {
      emit(states.AuthError(failure));
    } catch (e) {
      emit(states.AuthError(UnexpectedFailure(message: e.toString())));
    }
  }

  /// Handle biometric authentication request
  Future<void> _onBiometricRequested(
    events.AuthBiometricRequested event,
    Emitter<states.AuthState> emit,
  ) async {
    emit(const states.AuthLoading());
    // TODO: Implement biometric authentication
    // For now, emit error
    emit(states.AuthError(
      UnexpectedFailure(message: 'Biometric authentication not yet implemented'),
    ));
  }
}