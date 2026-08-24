// Core formatters for the application
import 'package:intl/intl.dart';

/// Formats a [DateTime] to a localized string
/// Example: "Aug 21, 2026 2:30 PM"
String formatDateTime(DateTime dateTime, {bool includeTime = true}) {
  final months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  final month = months[dateTime.month - 1];
  final day = dateTime.day;
  final year = dateTime.year;

  if (!includeTime) {
    return '$month $day, $year';
  }

  int hour = dateTime.hour;
  final minute = dateTime.minute.toString().padLeft(2, '0');
  final period = hour >= 12 ? 'PM' : 'AM';

  if (hour == 0) {
    hour = 12;
  } else if (hour > 12) hour -= 12;

  return '$month $day, $year $hour:$minute $period';
}

/// Formats a [DateTime] to a short date string
/// Example: "Aug 21, 2026"
String formatDate(DateTime dateTime) {
  return formatDateTime(dateTime, includeTime: false);
}

/// Formats a [DateTime] to a time string
/// Example: "2:30 PM"
String formatTime(DateTime dateTime) {
  int hour = dateTime.hour;
  final minute = dateTime.minute.toString().padLeft(2, '0');
  final period = hour >= 12 ? 'PM' : 'AM';

  if (hour == 0) {
    hour = 12;
  } else if (hour > 12) hour -= 12;

  return '$hour:$minute $period';
}

/// Formats a number with commas and optional decimals
/// Example: 1234.56 -> "1,234.56"
String formatNumber(num value, {int decimals = 2}) {
  final formatter = NumberFormat('#,##0.${'0' * decimals}', 'en_US');
  return formatter.format(value);
}

/// Formats a number as currency
/// Example: 1234.56 -> "₱1,234.56"
String formatCurrency(num value, {String symbol = '₱', int decimals = 2}) {
  return '$symbol${formatNumber(value, decimals: decimals)}';
}

/// Formats a quantity with unit
/// Example: 100.5, "tablets" -> "100.5 tablets"
String formatQuantity(num quantity, String unit) {
  return '${formatNumber(quantity, decimals: quantity == quantity.roundToDouble() ? 0 : 2)} $unit';
}

/// Formats a relative time (e.g., "2 hours ago", "in 3 days")
String formatRelativeTime(DateTime dateTime) {
  final now = DateTime.now();
  final difference = dateTime.difference(now);

  if (difference.isNegative) {
    // Past
    final absDiff = now.difference(dateTime);
    if (absDiff.inDays > 0) {
      return '${absDiff.inDays} day${absDiff.inDays == 1 ? '' : 's'} ago';
    } else if (absDiff.inHours > 0) {
      return '${absDiff.inHours} hour${absDiff.inHours == 1 ? '' : 's'} ago';
    } else if (absDiff.inMinutes > 0) {
      return '${absDiff.inMinutes} minute${absDiff.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  } else {
    // Future
    if (difference.inDays > 0) {
      return 'In ${difference.inDays} day${difference.inDays == 1 ? '' : 's'}';
    } else if (difference.inHours > 0) {
      return 'In ${difference.inHours} hour${difference.inHours == 1 ? '' : 's'}';
    } else if (difference.inMinutes > 0) {
      return 'In ${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'}';
    } else {
      return 'Just now';
    }
  }
}

/// Formats file size in human readable format
/// Example: 1024 -> "1 KB", 1048576 -> "1 MB"
String formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}

/// Formats a Philippine mobile number for display
/// Examples:
/// - "+639123456789" -> "+63 912 345 6789"
/// - "09123456789" -> "0912 345 6789"
/// - "9123456789" -> "+63 912 345 6789"
String formatPhoneNumber(String phoneNumber) {
  // Remove all non-digits
  final digits = phoneNumber.replaceAll(RegExp(r'\D'), '');

  if (digits.startsWith('63') && digits.length == 12) {
    // Philippine number with country code: 639XXXXXXXXX
    return '+63 ${digits.substring(2, 5)} ${digits.substring(5, 8)} ${digits.substring(8)}';
  } else if (digits.length == 11 && digits.startsWith('09')) {
    // Philippine mobile local format: 09XXXXXXXXX
    return '${digits.substring(0, 4)} ${digits.substring(4, 7)} ${digits.substring(7)}';
  } else if (digits.length == 10 && digits.startsWith('9')) {
    // Philippine mobile without leading 0 or country code: 9XXXXXXXXX
    return '+63 ${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
  }

  // Try to format as generic international
  if (digits.length >= 10 && digits.length <= 15) {
    // Add spaces every 3-4 digits for readability
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (i % 3 == 0 || i % 4 == 0)) {
        buffer.write(' ');
      }
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  return phoneNumber; // Return as-is if not recognized
}

/// Formats a Philippine mobile number input for text field
/// Converts various formats to standardized local format: 09XX XXX XXXX
String formatPhoneNumberInput(String phoneNumber) {
  // Remove all non-digits
  final digits = phoneNumber.replaceAll(RegExp(r'\D'), '');

  if (digits.startsWith('63') && digits.length == 12) {
    // +63 9XX XXX XXXX -> 09XX XXX XXXX
    return '0${digits.substring(2, 5)} ${digits.substring(5, 8)} ${digits.substring(8)}';
  } else if (digits.length == 11 && digits.startsWith('09')) {
    // Already in local format
    return '${digits.substring(0, 4)} ${digits.substring(4, 7)} ${digits.substring(7)}';
  } else if (digits.length == 10 && digits.startsWith('9')) {
    // 9XXXXXXXXX -> 09XX XXX XXXX
    return '0${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
  }

  // Return digits grouped in 4-3-4 format for local numbers
  if (digits.length <= 11) {
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i == 4 || i == 7) buffer.write(' ');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  return phoneNumber;
}

/// Truncates text with ellipsis if it exceeds maxLength
String truncate(String text, int maxLength) {
  if (text.length <= maxLength) return text;
  return '${text.substring(0, maxLength - 3)}...';
}

/// Capitalizes first letter of each word
String capitalizeWords(String text) {
  return text.split(' ').map((word) {
    if (word.isEmpty) return word;
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }).join(' ');
}