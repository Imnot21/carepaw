// Input formatters for number fields
import 'package:flutter/services.dart';

/// Lets a text field hold only a decimal number with at most
/// [maxDigits] digits before the point and [maxDecimals] after it.
///
/// A keystroke that would break the limit is ignored, so the field keeps
/// its last valid text (e.g. weight `999.99` with 3 digits and 2 decimals).
class DecimalInputFormatter extends TextInputFormatter {
  DecimalInputFormatter({required this.maxDigits, this.maxDecimals = 2})
    : _pattern = RegExp(
        maxDecimals > 0
            ? '^\\d{0,$maxDigits}(\\.\\d{0,$maxDecimals})?\$'
            : '^\\d{0,$maxDigits}\$',
      );

  final int maxDigits;
  final int maxDecimals;
  final RegExp _pattern;

  /// Pet weight in kg: up to 999.99.
  static final weightKg = DecimalInputFormatter(maxDigits: 3);

  /// Medicine stock quantity: up to 99,999.99.
  static final stockQuantity = DecimalInputFormatter(maxDigits: 5);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return _pattern.hasMatch(newValue.text) ? newValue : oldValue;
  }
}
