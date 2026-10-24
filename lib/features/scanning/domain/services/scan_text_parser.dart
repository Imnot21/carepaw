import 'package:carepaw/features/scanning/domain/entities/scan_record.dart';

/// Fields pulled out of raw OCR text, in display order.
class ScanFields {
  /// Label → value, e.g. `Expiry → 12/2027`. Only fields that were found.
  final Map<String, String> values;

  /// Share of the expected fields that were found, 0.0–1.0. This is how
  /// complete the read was, not a promise that the values are right.
  final double confidence;

  const ScanFields(this.values, this.confidence);

  bool get isEmpty => values.isEmpty;

  /// `Label: value` lines, stored as the scan's extracted data.
  String toDisplay() =>
      values.entries.map((e) => '${e.key}: ${e.value}').join('\n');
}

/// Turns raw OCR text into labelled fields for a [ScanType].
///
/// Pure Dart and rule-based so it is easy to test and explain. It only
/// suggests values; the clinic confirms or rejects every scan.
class ScanTextParser {
  const ScanTextParser._();

  static const _date =
      r'(\d{1,2}[/\-.]\d{1,2}[/\-.]\d{2,4}|\d{4}[/\-.]\d{1,2}(?:[/\-.]\d{1,2})?'
      r'|\d{1,2}[/\-.]\d{4}|[A-Za-z]{3,9}\.?[ \-/]?\d{1,2}?,?[ \-/]?\d{2,4})';

  static final _expiry = RegExp(
    r'(?:EXP(?:IRY|IRATION)?(?:\s*DATE)?|USE\s+BEFORE|BEST\s+BEFORE)\.?\s*[:.]?\s*'
    '$_date',
    caseSensitive: false,
  );
  static final _expiryKeyword = RegExp(
    r'\b(EXP(?:IRY|IRATION)?|USE\s+BEFORE|BEST\s+BEFORE)\b',
    caseSensitive: false,
  );
  static final _lot = RegExp(
    r'\b(?:LOT|BATCH|B\.\s?N\.?)\s*(?:NO\.?|NUMBER|#)?\s*[:.]?\s*([A-Z0-9][A-Z0-9\-]{2,})',
    caseSensitive: false,
  );
  static final _total = RegExp(
    r'(?<!SUB)(?<!SUB\s)TOTAL(?:\s+(?:DUE|AMOUNT))?\s*[:.]?\s*(?:PHP|P|₱)?\s*'
    r'([0-9][0-9,]*(?:\.\d{1,2})?)',
    caseSensitive: false,
  );
  static final _anyDate = RegExp(_date);
  static final _keywordLine = RegExp(
    r'\b(EXP|LOT|BATCH|MFG|MFD|TOTAL|RX|DATE|TEL|NO\.)\b',
    caseSensitive: false,
  );

  static ScanFields parse(String raw, ScanType type) {
    final lines = raw
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.isEmpty) return const ScanFields({}, 0);

    final values = <String, String>{};
    final int expected;

    switch (type) {
      case ScanType.medicineBox:
        expected = 3;
        _put(values, 'Name', _title(lines));
        _put(values, 'Expiry', _expiryOf(lines));
        _put(values, 'Lot / Batch', _lot.firstMatch(raw)?.group(1));
      case ScanType.receipt:
        expected = 3;
        _put(values, 'Store', _title(lines));
        _put(values, 'Date', _anyDate.firstMatch(raw)?.group(1));
        final totals = _total.allMatches(raw).toList();
        _put(values, 'Total', totals.isEmpty ? null : totals.last.group(1));
      case ScanType.prescription:
      case ScanType.labReport:
      case ScanType.other:
        expected = 2;
        _put(values, 'Title', _title(lines));
        _put(values, 'Date', _anyDate.firstMatch(raw)?.group(1));
    }

    return ScanFields(values, values.length / expected);
  }

  static void _put(Map<String, String> into, String key, String? value) {
    final v = value?.trim();
    if (v != null && v.isNotEmpty) into[key] = v;
  }

  /// First line that reads like a name: has letters and is not a label.
  static String? _title(List<String> lines) {
    for (final line in lines) {
      final letters = line.replaceAll(RegExp(r'[^A-Za-z]'), '').length;
      if (letters >= 3 && !_keywordLine.hasMatch(line)) return line;
    }
    return null;
  }

  /// Expiry on the same line as its label, or on the line right after it.
  static String? _expiryOf(List<String> lines) {
    for (var i = 0; i < lines.length; i++) {
      final same = _expiry.firstMatch(lines[i]);
      if (same != null) return same.group(1);
      if (_expiryKeyword.hasMatch(lines[i]) && i + 1 < lines.length) {
        final next = _anyDate.firstMatch(lines[i + 1]);
        if (next != null) return next.group(1);
      }
    }
    return null;
  }
}
