import 'package:firebase_auth/firebase_auth.dart';
import 'package:carepaw/core/errors/failures.dart';

/// Maps a [FirebaseAuthException] to a user-friendly [Failure].
Failure mapFirebaseAuthException(FirebaseAuthException e) {
  switch (e.code) {
    case 'email-already-in-use':
      return const EmailAlreadyInUseFailure();
    case 'weak-password':
      return const WeakPasswordFailure();
    case 'invalid-email':
      return const InvalidEmailFailure();
    case 'user-not-found':
      return const UserNotFoundFailure();
    case 'wrong-password':
    case 'invalid-credential':
    case 'invalid-login-credentials':
      return const InvalidCredentialsFailure();
    case 'user-disabled':
      return const AccountLockedFailure();
    case 'too-many-requests':
      return const AccountLockedFailure(
        message: 'Too many attempts. Please try again later.',
      );
    case 'network-request-failed':
      return const NoConnectionFailure();
    case 'operation-not-allowed':
      return const UnauthorizedFailure(
        message:
            'Email/password sign-in is not enabled. Enable it in the Firebase console.',
      );
    case 'invalid-action-code':
      return const InvalidCredentialsFailure(
        message: 'The password reset link is invalid or has expired.',
      );
    default:
      return UnexpectedFailure(message: e.message ?? 'Authentication failed.');
  }
}
