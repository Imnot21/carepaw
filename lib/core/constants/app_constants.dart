/// Application-wide constants for CarePaw.
///
/// Centralizes configuration values, limits, and settings
/// used throughout the application.
class AppConstants {
  AppConstants._();

  // ============ App Info ============

  static const String appName = 'CarePaw';
  static const String appVersion = '0.1.0';
  static const String appDescription = 'Smart Veterinary Patient Management System';

  // ============ Timing ============

  /// Default timeout for API requests (in seconds)
  static const int apiTimeoutSeconds = 30;

  /// Session timeout duration (in hours)
  static const int sessionTimeoutHours = 24;

  /// Token refresh threshold (in minutes before expiry)
  static const int tokenRefreshThresholdMinutes = 5;

  /// Debounce duration for search (in milliseconds)
  static const int searchDebounceMs = 300;

  /// Toast/snackbar duration (in seconds)
  static const int snackbarDurationSeconds = 3;

  // ============ Pagination ============

  /// Default page size for lists
  static const int defaultPageSize = 20;

  /// Maximum page size
  static const int maxPageSize = 100;

  // ============ Validation ============

  /// Minimum password length
  static const int minPasswordLength = 8;

  /// Maximum password length
  static const int maxPasswordLength = 128;

  /// Maximum name length
  static const int maxNameLength = 100;

  /// Maximum email length
  static const int maxEmailLength = 254;

  /// Maximum phone length
  static const int maxPhoneLength = 15;

  /// Maximum notes/description length
  static const int maxNotesLength = 2000;

  /// Maximum pet name length
  static const int maxPetNameLength = 50;

  /// Maximum weight in kg
  static const double maxWeightKg = 500.0;

  // ============ Queue ============

  /// Estimated time per appointment (in minutes)
  static const int estimatedTimePerAppointment = 15;

  /// Check-in window before appointment (in minutes)
  static const int checkInWindowMinutes = 30;

  /// Late arrival threshold (in minutes after scheduled)
  static const int lateArrivalMinutes = 15;

  // ============ Inventory ============

  /// Low stock threshold
  static const int lowStockThreshold = 10;

  /// Expiration warning days
  static const int expirationWarningDays = 30;

  /// Critical expiration days
  static const int criticalExpirationDays = 7;

  // ============ OCR ============

  /// Minimum OCR confidence threshold (0.0 - 1.0)
  static const double ocrConfidenceThreshold = 0.7;

  /// Maximum image file size (in bytes)
  static const int maxImageSizeBytes = 10 * 1024 * 1024; // 10MB

  /// Supported image formats
  static const List<String> supportedImageFormats = ['jpg', 'jpeg', 'png'];

  // ============ Notifications ============

  /// Maximum notification history days
  static const int notificationRetentionDays = 90;

  /// Reminder hours before appointment
  static const List<int> appointmentReminderHours = [24, 2]; // 24h and 2h before

  // ============ Audit Log ============

  /// Audit log retention days
  static const int auditLogRetentionDays = 365;

  // ============ Security ============

  /// Maximum login attempts before lockout
  static const int maxLoginAttempts = 5;

  /// Account lockout duration (in minutes)
  static const int lockoutDurationMinutes = 15;

  /// Password history count (prevent reuse)
  static const int passwordHistoryCount = 5;
}

/// Route names and paths
class RouteConstants {
  RouteConstants._();

  // These will be expanded in Phase 3 with full routing
}

/// Error codes for API responses
class ErrorCodeConstants {
  ErrorCodeConstants._();

  // Auth errors (1xxx)
  static const String invalidCredentials = 'AUTH_1001';
  static const String sessionExpired = 'AUTH_1002';
  static const String unauthorized = 'AUTH_1003';
  static const String accountLocked = 'AUTH_1004';

  // Validation errors (2xxx)
  static const String validationError = 'VAL_2001';
  static const String requiredField = 'VAL_2002';
  static const String invalidFormat = 'VAL_2003';

  // Resource errors (3xxx)
  static const String notFound = 'RES_3001';
  static const String alreadyExists = 'RES_3002';
  static const String conflict = 'RES_3003';

  // Server errors (5xxx)
  static const String internalError = 'SRV_5001';
  static const String serviceUnavailable = 'SRV_5002';
}
