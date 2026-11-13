import 'package:carepaw/core/errors/failures.dart';

/// Friendly, non-revealing sentence for an auth [Failure].
///
/// Never echoes raw service text, and never confirms whether an email has an
/// account: unknown email and wrong password read the same, and a taken email
/// gets a neutral line.
String authFailureMessage(Failure failure) {
  if (failure is InvalidCredentialsFailure &&
      failure.message.contains('reset link')) {
    return 'This reset link is invalid or has expired. Request a new one.';
  }
  if (failure is InvalidCredentialsFailure || failure is UserNotFoundFailure) {
    return 'Email or password is incorrect.';
  }
  if (failure is EmailAlreadyInUseFailure) {
    return 'We couldn\u2019t create the account with those details. '
        'Try signing in, or use a different email.';
  }
  if (failure is WeakPasswordFailure) return failure.message;
  if (failure is InvalidEmailFailure) {
    return 'Enter a valid email address.';
  }
  if (failure is AccountLockedFailure) {
    return failure.message.contains('Too many')
        ? 'Too many attempts. Please try again later.'
        : 'This account can\u2019t sign in right now. '
              'Please contact the clinic.';
  }
  if (failure is NoConnectionFailure || failure is TimeoutFailure) {
    return 'Can\u2019t reach the server. Check your connection and try again.';
  }
  if (failure is SessionExpiredFailure) {
    return 'Your session has expired. Please sign in again.';
  }
  return 'Something went wrong. Please try again.';
}
