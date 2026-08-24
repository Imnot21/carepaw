import 'package:equatable/equatable.dart';
import 'package:carepaw/features/authentication/domain/entities/user.dart';
import 'package:carepaw/core/errors/failures.dart';

/// Base class for all authentication states.
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any auth check.
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Loading state during auth operations.
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Authenticated state with user and tokens.
class AuthAuthenticated extends AuthState {
  final AuthResult authResult;

  const AuthAuthenticated(this.authResult);

  /// Convenience getter for the user
  User get user => authResult.user;

  /// Convenience getter for access token
  String get accessToken => authResult.accessToken;

  /// Convenience getter for refresh token
  String get refreshToken => authResult.refreshToken;

  @override
  List<Object?> get props => [authResult];
}

/// Unauthenticated state - user is logged out.
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Error state with failure information.
class AuthError extends AuthState {
  final Failure failure;

  const AuthError(this.failure);

  @override
  List<Object?> get props => [failure];
}

/// Password change success state.
class AuthPasswordChanged extends AuthState {
  const AuthPasswordChanged();
}

/// Forgot password request sent state.
class AuthForgotPasswordSent extends AuthState {
  const AuthForgotPasswordSent();
}

/// Password reset success state.
class AuthPasswordReset extends AuthState {
  const AuthPasswordReset();
}