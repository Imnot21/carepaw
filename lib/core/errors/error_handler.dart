import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carepaw/core/firebase/firebase_firestore_error_mapper.dart';
import 'failures.dart';
import 'exceptions.dart';

/// Centralized error handling for the application.
///
/// Converts exceptions to user-friendly failures and
/// provides consistent error messages throughout the app.
class ErrorHandler {
  const ErrorHandler._();

  /// Convert an exception to a failure
  static Failure handleException(Object exception) {
    // Handle our custom exceptions
    if (exception is AppException) {
      return _handleAppException(exception);
    }

    // Handle common Dart/Flutter exceptions
    return _handleOtherException(exception);
  }

  /// Handle CarePaw-specific exceptions
  static Failure _handleAppException(AppException exception) {
    // Network exceptions
    if (exception is NoConnectionException) {
      return const NoConnectionFailure();
    }
    if (exception is TimeoutException) {
      return const TimeoutFailure();
    }

    // Server exceptions
    if (exception is BadRequestException) {
      return BadRequestFailure(
        message: exception.message,
        code: exception.code,
      );
    }
    if (exception is UnauthorizedException) {
      return const UnauthorizedFailure();
    }
    if (exception is ForbiddenException) {
      return const UnauthorizedFailure(
        message: 'You do not have permission to access this resource.',
      );
    }
    if (exception is NotFoundException) {
      return NotFoundFailure(message: exception.message, code: exception.code);
    }
    if (exception is ConflictException) {
      return const AppointmentConflictFailure();
    }
    if (exception is ServerException) {
      return ServerFailure(message: exception.message, code: exception.code);
    }

    // Cache exceptions
    if (exception is CacheWriteException || exception is CacheException) {
      return const CacheFailure();
    }

    // Database exceptions
    if (exception is ConstraintViolationException) {
      return RequiredFieldFailure(message: exception.message);
    }
    if (exception is DatabaseException) {
      return NotFoundFailure(message: exception.message, code: exception.code);
    }

    // Auth exceptions
    if (exception is SessionExpiredException) {
      return const SessionExpiredFailure();
    }
    if (exception is AuthException) {
      return InvalidCredentialsFailure(message: exception.message);
    }

    // Validation exceptions
    if (exception is ValidationException) {
      return RequiredFieldFailure(message: exception.message);
    }

    // OCR exceptions
    if (exception is OcrException) {
      return const OcrProcessingFailure();
    }
    if (exception is ImageProcessingException) {
      return const OcrProcessingFailure(
        message: 'Failed to process image. Please try a different photo.',
      );
    }

    // Permission exceptions
    if (exception is PermissionDeniedException) {
      return const UnauthorizedFailure(message: 'Permission denied.');
    }

    // Format exceptions (custom)
    if (exception is FormatException) {
      return const InvalidEmailFailure(message: 'Invalid data format.');
    }

    // Default fallback
    return UnexpectedFailure(message: exception.message, code: exception.code);
  }

  /// Handle other common exceptions
  static Failure _handleOtherException(Object exception) {
    // Firestore exceptions
    if (exception is FirebaseException) {
      return mapFirestoreException(exception);
    }

    // Format exception (Dart)
    if (exception is FormatException) {
      return const InvalidEmailFailure(message: 'Invalid data format.');
    }

    // Range error
    if (exception is RangeError) {
      return const OutOfRangeFailure();
    }

    // ArgumentError
    if (exception is ArgumentError) {
      return const UnexpectedFailure(message: 'Invalid argument provided.');
    }

    // StateError
    if (exception is StateError) {
      return const UnexpectedFailure(
        message: 'Invalid state. Please restart the app.',
      );
    }

    // TypeError
    if (exception is TypeError) {
      return const UnexpectedFailure(message: 'Type error occurred.');
    }

    // Default to unexpected failure
    return UnexpectedFailure(message: exception.toString());
  }

  /// Get user-friendly error message from any error
  static String getErrorMessage(Object error) {
    if (error is Failure) {
      return error.message;
    }
    if (error is AppException) {
      return error.message;
    }

    final failure = handleException(error);
    return failure.message;
  }

  /// Check if error is a network-related error
  static bool isNetworkError(Object error) {
    if (error is NoConnectionException || error is TimeoutException) {
      return true;
    }
    if (error is NoConnectionFailure || error is TimeoutFailure) {
      return true;
    }
    return false;
  }

  /// Check if error requires re-authentication
  static bool requiresReauth(Object error) {
    if (error is SessionExpiredException || error is UnauthorizedException) {
      return true;
    }
    if (error is SessionExpiredFailure || error is UnauthorizedFailure) {
      return true;
    }
    return false;
  }
}
