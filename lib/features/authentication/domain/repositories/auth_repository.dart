import 'package:carepaw/features/authentication/domain/entities/user.dart';

/// Authentication repository interface - domain layer contract.
///
/// Defines the operations for user authentication and session management.
/// Implementations handle the actual data sources (database, secure storage, etc.).
abstract class AuthRepository {
  /// Authenticate a user with email and password.
  ///
  /// Returns [AuthResult] containing user info and tokens on success.
  /// Throws [AuthFailure] on invalid credentials, user not found, or account locked.
  Future<AuthResult> login({
    required String email,
    required String password,
  });

  /// Register a new user account.
  ///
  /// Creates a new user with the given credentials.
  /// Default role is [UserRole.petOwner] unless specified.
  /// Returns [AuthResult] with tokens on success.
  /// Throws [AuthFailure] on email in use, weak password, or validation errors.
  Future<AuthResult> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    UserRole role = UserRole.petOwner,
  });

  /// Log out the current user.
  ///
  /// Clears all authentication tokens and session data.
  Future<void> logout();

  /// Get the current authenticated user from stored session.
  ///
  /// Attempts to restore session from secure storage.
  /// Returns [AuthResult] if valid session exists, `null` otherwise.
  /// Does not throw - returns null for expired/invalid sessions.
  Future<AuthResult?> getCurrentUser();

  /// Refresh the access token using the refresh token.
  ///
  /// Returns new [AuthResult] with updated tokens.
  /// Throws [AuthFailure] if refresh token is invalid or expired.
  Future<AuthResult> refreshToken();

  /// Change the current user's password.
  ///
  /// Requires the current password for verification.
  /// Throws [AuthFailure] on invalid current password or weak new password.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Request a password reset for the given email.
  ///
  /// In a real implementation, this would send a reset email.
  /// For now, this simulates the request (logs the action).
  /// Does not reveal whether the email exists (security best practice).
  Future<void> forgotPassword(String email);

  /// Reset password using a reset token.
  ///
  /// The token would typically come from a reset email link.
  /// Throws [AuthFailure] on invalid/expired token or weak password.
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  });

  /// Stream of authentication state changes.
  ///
  /// Emits the current [AuthResult] when authenticated,
  /// or `null` when unauthenticated.
  /// Used by BLoC for reactive UI updates.
  Stream<AuthResult?> get authStateStream;
}