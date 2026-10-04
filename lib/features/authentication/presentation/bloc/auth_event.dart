import 'package:equatable/equatable.dart';
import 'package:carepaw/features/authentication/domain/entities/user.dart';

/// Base class for all authentication events.
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Request user login with email and password.
class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

/// Request user registration.
class AuthRegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String fullName;
  final String? phone;
  final UserRole role;

  const AuthRegisterRequested({
    required this.email,
    required this.password,
    required this.fullName,
    this.phone,
    this.role = UserRole.petOwner,
  });

  @override
  List<Object?> get props => [email, password, fullName, phone, role];
}

/// Request logout.
class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

/// Request to check/restore current session on app startup.
class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// Request token refresh.
class AuthTokenRefreshed extends AuthEvent {
  const AuthTokenRefreshed();
}

/// Request password change.
class AuthPasswordChanged extends AuthEvent {
  final String currentPassword;
  final String newPassword;

  const AuthPasswordChanged({
    required this.currentPassword,
    required this.newPassword,
  });

  @override
  List<Object?> get props => [currentPassword, newPassword];
}

/// Request forgot password (send reset email).
class AuthForgotPasswordRequested extends AuthEvent {
  final String email;

  const AuthForgotPasswordRequested({required this.email});

  @override
  List<Object?> get props => [email];
}

/// Request password reset with token.
class AuthResetPasswordRequested extends AuthEvent {
  final String token;
  final String newPassword;

  const AuthResetPasswordRequested({
    required this.token,
    required this.newPassword,
  });

  @override
  List<Object?> get props => [token, newPassword];
}

/// Request biometric authentication.
class AuthBiometricRequested extends AuthEvent {
  const AuthBiometricRequested();
}
