/// Input validation utilities for CarePaw.
///
/// Provides common validation functions for form inputs.
/// All validators return null for valid input, or an error
/// message string for invalid input.
class Validators {
  Validators._();

  // ============ Common Validators ============

  /// Validates that a field is not empty
  static String? required(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }
    return null;
  }

  /// Validates minimum length
  static String? minLength(String? value, int min, [String? fieldName]) {
    if (value == null || value.isEmpty) return null;
    if (value.length < min) {
      return '${fieldName ?? 'This field'} must be at least $min characters';
    }
    return null;
  }

  /// Validates maximum length
  static String? maxLength(String? value, int max, [String? fieldName]) {
    if (value == null || value.isEmpty) return null;
    if (value.length > max) {
      return '${fieldName ?? 'This field'} must be at most $max characters';
    }
    return null;
  }

  // ============ Email Validation ============

  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  /// Validates email format
  static String? email(String? value) {
    if (value == null || value.isEmpty) return null;
    if (!_emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  // ============ Password Validation ============

  /// Validates password strength
  ///
  /// Requirements:
  /// - At least 8 characters
  /// - At least one uppercase letter
  /// - At least one lowercase letter
  /// - At least one number
  static String? password(String? value) {
    if (value == null || value.isEmpty) return null;

    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }

    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }

    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }

    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }

    return null;
  }

  /// Alias for password() to match expected API
  static String? validatePassword(String? value) => password(value);

  /// Validates password confirmation matches
  static String? passwordConfirm(String? value, String password) {
    if (value == null || value.isEmpty) return null;
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  // ============ Phone Validation (Philippines) ============

  /// Philippine mobile number regex
  /// Supports: +63 9XX XXX XXXX, 09XX XXX XXXX, +639XXXXXXXXX, 09XXXXXXXXX
  static final RegExp _phPhoneRegex = RegExp(
    r'^(\+63|0)9\d{9}$',
  );

  /// Validates Philippine mobile number format
  ///
  /// Philippine mobile numbers:
  /// - +63 9XX XXX XXXX (international format)
  /// - 09XX XXX XXXX (local format)
  /// - +639XXXXXXXXX (compact international)
  /// - 09XXXXXXXXX (compact local)
  static String? phone(String? value) {
    if (value == null || value.isEmpty) return null;

    // Clean the input - remove spaces, dashes, parentheses
    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Check if it matches Philippine mobile format
    if (!_phPhoneRegex.hasMatch(cleaned)) {
      return 'Please enter a valid Philippine mobile number (e.g., +63 9XX XXX XXXX or 09XX XXX XXXX)';
    }

    return null;
  }

  /// Validates Philippine landline number format
  /// Supports: +63 2X XXX XXXX, 02 XXXX XXXX, etc.
  static String? landline(String? value) {
    if (value == null || value.isEmpty) return null;

    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    // Philippine landline: +63 2 XXXX XXXX or 02 XXXX XXXX (Metro Manila)
    // Other areas have different area codes
    final landlineRegex = RegExp(r'^(\+63|0)(2|3[2-9]|4[2-9]|5[2-9]|6[2-9]|7[2-9]|8[2-9])\d{7}$');

    if (!landlineRegex.hasMatch(cleaned)) {
      return 'Please enter a valid Philippine landline number';
    }

    return null;
  }

  // ============ Name Validation ============

  /// Validates person name
  static String? name(String? value, [String? fieldName]) {
    if (value == null || value.isEmpty) return null;

    if (value.trim().length < 2) {
      return '${fieldName ?? 'Name'} must be at least 2 characters';
    }

    if (!RegExp(r"^[a-zA-Z\s\-']+$").hasMatch(value)) {
      return '${fieldName ?? 'Name'} can only contain letters, spaces, hyphens, and apostrophes';
    }

    return null;
  }

  /// Validates pet name
  static String? petName(String? value) {
    if (value == null || value.isEmpty) return null;

    if (value.trim().isEmpty) {
      return 'Pet name is required';
    }

    if (value.trim().length > 50) {
      return 'Pet name must be at most 50 characters';
    }

    return null;
  }

  // ============ Number Validation ============

  /// Validates positive number
  static String? positiveNumber(String? value, [String? fieldName]) {
    if (value == null || value.isEmpty) return null;

    final number = double.tryParse(value);
    if (number == null) {
      return 'Please enter a valid number';
    }

    if (number <= 0) {
      return '${fieldName ?? 'Value'} must be greater than 0';
    }

    return null;
  }

  /// Validates number is within range
  static String? numberRange(
    String? value,
    double min,
    double max, [
    String? fieldName,
  ]) {
    if (value == null || value.isEmpty) return null;

    final number = double.tryParse(value);
    if (number == null) {
      return 'Please enter a valid number';
    }

    if (number < min || number > max) {
      return '${fieldName ?? 'Value'} must be between $min and $max';
    }

    return null;
  }

  /// Validates integer
  static String? integer(String? value, [String? fieldName]) {
    if (value == null || value.isEmpty) return null;

    final number = int.tryParse(value);
    if (number == null) {
      return 'Please enter a valid whole number';
    }

    return null;
  }

  // ============ Date Validation ============

  /// Validates date is not in the past
  static String? futureDate(DateTime? value, [String? fieldName]) {
    if (value == null) return null;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(value.year, value.month, value.day);

    if (date.isBefore(today)) {
      return '${fieldName ?? 'Date'} cannot be in the past';
    }

    return null;
  }

  /// Validates date is not in the future
  static String? pastDate(DateTime? value, [String? fieldName]) {
    if (value == null) return null;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(value.year, value.month, value.day);

    if (date.isAfter(today)) {
      return '${fieldName ?? 'Date'} cannot be in the future';
    }

    return null;
  }

  /// Validates age is at least minimum years
  static String? minimumAge(DateTime? birthDate, int minAge, [String? fieldName]) {
    if (birthDate == null) return null;

    final now = DateTime.now();
    final age = now.year - birthDate.year -
        (now.month < birthDate.month ||
                (now.month == birthDate.month && now.day < birthDate.day)
            ? 1
            : 0);

    if (age < minAge) {
      return 'Must be at least $minAge years old';
    }

    return null;
  }

  // ============ Weight Validation ============

  /// Validates pet weight (in kg)
  static String? weight(String? value) {
    if (value == null || value.isEmpty) return null;

    final weight = double.tryParse(value);
    if (weight == null) {
      return 'Please enter a valid weight';
    }

    if (weight <= 0) {
      return 'Weight must be greater than 0';
    }

    if (weight > 500) {
      return 'Weight seems too large. Please verify.';
    }

    return null;
  }

  // ============ Microchip Validation ============

  /// Validates microchip number (15 digits)
  static String? microchip(String? value) {
    if (value == null || value.isEmpty) return null;

    final cleaned = value.replaceAll(RegExp(r'[\s\-]'), '');

    if (!RegExp(r'^\d{15}$').hasMatch(cleaned)) {
      return 'Microchip number must be 15 digits';
    }

    return null;
  }

  // ============ Composite Validators ============

  /// Combines multiple validators
  static String? combine(String? value, List<String? Function(String?)> validators) {
    for (final validator in validators) {
      final error = validator(value);
      if (error != null) return error;
    }
    return null;
  }

  /// Creates a required validator with additional validators
  static String? Function(String?) requiredWith(
    List<String? Function(String?)> validators, [
    String? fieldName,
  ]) {
    return (String? value) {
      final requiredError = required(value, fieldName);
      if (requiredError != null) return requiredError;

      return combine(value, validators);
    };
  }
}
