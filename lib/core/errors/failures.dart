import 'package:equatable/equatable.dart';

/// Base class for all failures in the application.
///
/// Failures represent expected error conditions that can occur
/// during normal application operation. They are used to
/// communicate errors from the data/domain layer to the
/// presentation layer in a type-safe way.
///
/// Each failure should provide a user-friendly message
/// that can be displayed to the user.
abstract class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure({required this.message, this.code});

  @override
  List<Object?> get props => [message, code];
}

// ============ General Failures ============

/// Generic failure for unexpected errors
class UnexpectedFailure extends Failure {
  const UnexpectedFailure({
    super.message = 'An unexpected error occurred. Please try again.',
    super.code,
  });
}

/// Failure for cancelled operations
class CancelledFailure extends Failure {
  const CancelledFailure({
    super.message = 'Operation was cancelled.',
    super.code,
  });
}

// ============ Network Failures ============

/// Base class for network-related failures
abstract class NetworkFailure extends Failure {
  const NetworkFailure({required super.message, super.code});
}

/// No internet connection
class NoConnectionFailure extends NetworkFailure {
  const NoConnectionFailure({
    super.message =
        'No internet connection. Please check your network settings.',
    super.code = 'NO_CONNECTION',
  });
}

/// Connection timeout
class TimeoutFailure extends NetworkFailure {
  const TimeoutFailure({
    super.message = 'Connection timed out. Please try again.',
    super.code = 'TIMEOUT',
  });
}

/// Server error (5xx)
class ServerFailure extends NetworkFailure {
  const ServerFailure({
    super.message = 'Server error. Please try again later.',
    super.code,
  });
}

/// Bad request (4xx)
class BadRequestFailure extends NetworkFailure {
  const BadRequestFailure({
    super.message = 'Invalid request. Please check your input.',
    super.code,
  });
}

// ============ Authentication Failures ============

/// Base class for authentication failures
abstract class AuthFailure extends Failure {
  const AuthFailure({required super.message, super.code});
}

/// Invalid credentials
class InvalidCredentialsFailure extends AuthFailure {
  const InvalidCredentialsFailure({
    super.message = 'Invalid email or password.',
    super.code = 'INVALID_CREDENTIALS',
  });
}

/// User not found
class UserNotFoundFailure extends AuthFailure {
  const UserNotFoundFailure({
    super.message = 'No account found with this email.',
    super.code = 'USER_NOT_FOUND',
  });
}

/// Email already in use
class EmailAlreadyInUseFailure extends AuthFailure {
  const EmailAlreadyInUseFailure({
    super.message = 'An account with this email already exists.',
    super.code = 'EMAIL_IN_USE',
  });
}

/// Weak password
class WeakPasswordFailure extends AuthFailure {
  const WeakPasswordFailure({
    super.message = 'Password is too weak. Please use a stronger password.',
    super.code = 'WEAK_PASSWORD',
  });
}

/// Session expired
class SessionExpiredFailure extends AuthFailure {
  const SessionExpiredFailure({
    super.message = 'Your session has expired. Please log in again.',
    super.code = 'SESSION_EXPIRED',
  });
}

/// Unauthorized access
class UnauthorizedFailure extends AuthFailure {
  const UnauthorizedFailure({
    super.message = 'You are not authorized to perform this action.',
    super.code = 'UNAUTHORIZED',
  });
}

/// Account locked
class AccountLockedFailure extends AuthFailure {
  const AccountLockedFailure({
    super.message = 'Your account has been locked. Please contact support.',
    super.code = 'ACCOUNT_LOCKED',
  });
}

// ============ Validation Failures ============

/// Base class for validation failures
abstract class ValidationFailure extends Failure {
  const ValidationFailure({required super.message, super.code});
}

/// Required field empty
class RequiredFieldFailure extends ValidationFailure {
  const RequiredFieldFailure({
    super.message = 'This field is required.',
    super.code = 'REQUIRED',
  });
}

/// Invalid email format
class InvalidEmailFailure extends ValidationFailure {
  const InvalidEmailFailure({
    super.message = 'Please enter a valid email address.',
    super.code = 'INVALID_EMAIL',
  });
}

/// Invalid phone format
class InvalidPhoneFailure extends ValidationFailure {
  const InvalidPhoneFailure({
    super.message = 'Please enter a valid phone number.',
    super.code = 'INVALID_PHONE',
  });
}

/// Password requirements not met
class PasswordRequirementsFailure extends ValidationFailure {
  const PasswordRequirementsFailure({
    super.message =
        'Password must be at least 8 characters with uppercase, lowercase, and number.',
    super.code = 'PASSWORD_REQUIREMENTS',
  });
}

/// Value out of range
class OutOfRangeFailure extends ValidationFailure {
  const OutOfRangeFailure({
    super.message = 'Value is out of acceptable range.',
    super.code = 'OUT_OF_RANGE',
  });
}

// ============ Data Failures ============

/// Base class for data-related failures
abstract class DataFailure extends Failure {
  const DataFailure({required super.message, super.code});
}

/// Item not found
class NotFoundFailure extends DataFailure {
  const NotFoundFailure({
    super.message = 'The requested item was not found.',
    super.code = 'NOT_FOUND',
  });
}

/// Data already exists
class AlreadyExistsFailure extends DataFailure {
  const AlreadyExistsFailure({
    super.message = 'This item already exists.',
    super.code = 'ALREADY_EXISTS',
  });
}

/// Cache failure
class CacheFailure extends DataFailure {
  const CacheFailure({
    super.message = 'Failed to load cached data.',
    super.code = 'CACHE_ERROR',
  });
}

// ============ Storage Failures ============

/// Base class for storage failures
abstract class StorageFailure extends Failure {
  const StorageFailure({required super.message, super.code});
}

/// Failed to read from storage
class StorageReadFailure extends StorageFailure {
  const StorageReadFailure({
    super.message = 'Failed to read data.',
    super.code = 'STORAGE_READ_ERROR',
  });
}

/// Failed to write to storage
class StorageWriteFailure extends StorageFailure {
  const StorageWriteFailure({
    super.message = 'Failed to save data.',
    super.code = 'STORAGE_WRITE_ERROR',
  });
}

// ============ Appointment Failures ============

/// Appointment conflict
class AppointmentConflictFailure extends Failure {
  const AppointmentConflictFailure({
    super.message = 'This time slot is no longer available.',
    super.code = 'APPOINTMENT_CONFLICT',
  });
}

/// Invalid appointment status transition
class InvalidStatusTransitionFailure extends Failure {
  const InvalidStatusTransitionFailure({
    super.message = 'Cannot change appointment status.',
    super.code = 'INVALID_STATUS_TRANSITION',
  });
}

// ============ Inventory Failures ============

/// Insufficient stock
class InsufficientStockFailure extends Failure {
  const InsufficientStockFailure({
    super.message = 'Insufficient stock available.',
    super.code = 'INSUFFICIENT_STOCK',
  });
}

/// Medicine expired
class MedicineExpiredFailure extends Failure {
  const MedicineExpiredFailure({
    super.message = 'This medicine has expired and cannot be used.',
    super.code = 'MEDICINE_EXPIRED',
  });
}

// ============ OCR/Scan Failures ============

/// OCR processing failed
class OcrProcessingFailure extends Failure {
  const OcrProcessingFailure({
    super.message =
        'Failed to process image. Please try again with a clearer photo.',
    super.code = 'OCR_PROCESSING_ERROR',
  });
}

/// Low confidence OCR result
class LowConfidenceOcrFailure extends Failure {
  const LowConfidenceOcrFailure({
    super.message = 'Could not clearly read the image. Please try again.',
    super.code = 'LOW_CONFIDENCE_OCR',
  });
}

/// Invalid scan result
class InvalidScanResultFailure extends Failure {
  const InvalidScanResultFailure({
    super.message = 'Invalid scan result. Please verify the data.',
    super.code = 'INVALID_SCAN_RESULT',
  });
}
