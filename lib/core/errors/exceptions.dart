/// Base class for all application-specific exceptions.
///
/// Exceptions represent unexpected error conditions that
/// should not occur during normal operation. They are
/// caught at the infrastructure layer and converted to
/// Failures for presentation to the user.
///
/// Use exceptions for:
/// - Programming errors (null reference, type mismatch)
/// - Infrastructure errors (database corruption, file not found)
/// - Unexpected runtime conditions
///
/// Use Failures for:
/// - Expected business errors (invalid credentials, item not found)
/// - User input validation errors
/// - Network errors
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final StackTrace? stackTrace;

  const AppException({required this.message, this.code, this.stackTrace});

  @override
  String toString() => 'AppException: $message';
}

// ============ Server Exceptions ============

/// Server returned an error response
class ServerException extends AppException {
  final int? statusCode;

  const ServerException({
    super.message = 'Server error',
    super.code,
    super.stackTrace,
    this.statusCode,
  });
}

/// Bad request to server
class BadRequestException extends ServerException {
  const BadRequestException({
    super.message = 'Bad request',
    super.code,
    super.stackTrace,
    super.statusCode = 400,
  });
}

/// Unauthorized request
class UnauthorizedException extends ServerException {
  const UnauthorizedException({
    super.message = 'Unauthorized',
    super.code,
    super.stackTrace,
    super.statusCode = 401,
  });
}

/// Forbidden request
class ForbiddenException extends ServerException {
  const ForbiddenException({
    super.message = 'Forbidden',
    super.code,
    super.stackTrace,
    super.statusCode = 403,
  });
}

/// Resource not found
class NotFoundException extends ServerException {
  const NotFoundException({
    super.message = 'Not found',
    super.code,
    super.stackTrace,
    super.statusCode = 404,
  });
}

/// Conflict error
class ConflictException extends ServerException {
  const ConflictException({
    super.message = 'Conflict',
    super.code,
    super.stackTrace,
    super.statusCode = 409,
  });
}

// ============ Network Exceptions ============

/// No internet connection
class NoConnectionException extends AppException {
  const NoConnectionException({
    super.message = 'No internet connection',
    super.code,
    super.stackTrace,
  });
}

/// Connection timeout
class TimeoutException extends AppException {
  const TimeoutException({
    super.message = 'Connection timeout',
    super.code,
    super.stackTrace,
  });
}

// ============ Cache Exceptions ============

/// Cache read error
class CacheException extends AppException {
  const CacheException({
    super.message = 'Cache error',
    super.code,
    super.stackTrace,
  });
}

/// Cache write error
class CacheWriteException extends CacheException {
  const CacheWriteException({
    super.message = 'Failed to write to cache',
    super.code,
    super.stackTrace,
  });
}

// ============ Database Exceptions ============

/// Database operation failed
class DatabaseException extends AppException {
  const DatabaseException({
    super.message = 'Database error',
    super.code,
    super.stackTrace,
  });
}

/// Database constraint violation
class ConstraintViolationException extends DatabaseException {
  const ConstraintViolationException({
    super.message = 'Database constraint violation',
    super.code,
    super.stackTrace,
  });
}

// ============ Validation Exceptions ============

/// Validation failed
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  const ValidationException({
    super.message = 'Validation failed',
    super.code,
    super.stackTrace,
    this.fieldErrors,
  });
}

// ============ Authentication Exceptions ============

/// Authentication failed
class AuthException extends AppException {
  const AuthException({
    super.message = 'Authentication failed',
    super.code,
    super.stackTrace,
  });
}

/// Session expired
class SessionExpiredException extends AuthException {
  const SessionExpiredException({
    super.message = 'Session expired',
    super.code,
    super.stackTrace,
  });
}

// ============ Format Exceptions ============

/// Data format error
class FormatException extends AppException {
  const FormatException({
    super.message = 'Invalid data format',
    super.code,
    super.stackTrace,
  });
}

// ============ OCR Exceptions ============

/// OCR processing error
class OcrException extends AppException {
  const OcrException({
    super.message = 'OCR processing failed',
    super.code,
    super.stackTrace,
  });
}

/// Image processing error
class ImageProcessingException extends AppException {
  const ImageProcessingException({
    super.message = 'Image processing failed',
    super.code,
    super.stackTrace,
  });
}

// ============ Permission Exceptions ============

/// Permission denied
class PermissionDeniedException extends AppException {
  const PermissionDeniedException({
    super.message = 'Permission denied',
    super.code,
    super.stackTrace,
  });
}
