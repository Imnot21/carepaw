import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carepaw/core/errors/failures.dart';

/// Maps a Firestore [FirebaseException] to a user-friendly [Failure].
///
/// Firestore exception codes live under the `cloud_firestore/` namespace.
/// This mapper centralises the conversion so UI code only ever sees a
/// typed [Failure] with a clear, actionable message.
Failure mapFirestoreException(FirebaseException e) {
  switch (e.code) {
    case 'permission-denied':
      return const UnauthorizedFailure(
        message:
            'Permission denied. Ensure you are signed in and '
            'that Firestore security rules allow this operation. '
            'For development, deploy firestore.rules (the permissive '
            'test rules) to your Firebase project.',
      );
    case 'unauthenticated':
      return const UnauthorizedFailure(
        message: 'You are not signed in. Please log in and try again.',
      );
    case 'not-found':
      return const NotFoundFailure(message: 'The requested document was not found.');
    case 'already-exists':
      return const AlreadyExistsFailure();
    case 'failed-precondition':
      return UnexpectedFailure(
        message: 'Operation failed due to a data conflict. ${e.message ?? ''}',
      );
    case 'aborted':
      return UnexpectedFailure(
        message: 'The operation was aborted (transaction conflict). Please retry.',
      );
    case 'unavailable':
      return const NoConnectionFailure(
        message: 'Firestore is unavailable. Check your network connection.',
      );
    case 'deadline-exceeded':
      return const TimeoutFailure(
        message: 'Firestore request timed out. Please try again.',
      );
    case 'resource-exhausted':
      return UnexpectedFailure(
        message: 'Firestore quota exceeded or too many requests. Please try again later.',
      );
    case 'internal':
      return ServerFailure(
        message: 'Internal Firestore error. ${e.message ?? ''}',
      );
    default:
      return UnexpectedFailure(
        message: 'Firestore error: ${e.message ?? e.code}',
      );
  }
}
