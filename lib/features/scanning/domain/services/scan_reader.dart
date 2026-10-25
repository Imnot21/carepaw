import 'package:carepaw/features/scanning/domain/entities/scan_record.dart';
import 'package:carepaw/features/scanning/domain/services/scan_text_parser.dart';

/// One medicine read off a box, or one line of a supplier receipt.
///
/// Every value is a suggestion: the person edits it on the review screen
/// before anything reaches stock (CLAUDE.md rule 2).
class ScannedLine {
  final String name;
  final double? quantity;
  final String? unit;
  final String? lot;

  /// The expiry as text, e.g. `2027-12-31` or `12/2027`. Read with
  /// [ScanTextParser.parseDate].
  final String? expiry;

  const ScannedLine({
    required this.name,
    this.quantity,
    this.unit,
    this.lot,
    this.expiry,
  });
}

/// What a scan says: who supplied it and which medicines it lists.
class ScanReading {
  final String? supplier;
  final List<ScannedLine> lines;

  /// The printed text, kept with the scan record for reference.
  final String rawText;

  const ScanReading({this.supplier, this.lines = const [], this.rawText = ''});

  bool get isEmpty => lines.isEmpty && rawText.trim().isEmpty;

  /// Builds a reading from plain OCR text with the rule-based parser.
  ///
  /// Used when the AI read fails. A medicine box gives one line; a
  /// receipt gives only the supplier, and the person adds the lines.
  factory ScanReading.fromText(String raw, ScanType type) {
    final fields = ScanTextParser.parse(raw, type).values;
    if (type == ScanType.receipt) {
      return ScanReading(supplier: fields['Store'], rawText: raw);
    }
    final name = fields['Name'];
    return ScanReading(
      rawText: raw,
      lines: name == null
          ? const []
          : [
              ScannedLine(
                name: name,
                quantity: 1,
                unit: 'box',
                lot: fields['Lot / Batch'],
                expiry: fields['Expiry'],
              ),
            ],
    );
  }
}

/// Reads a medicine box or supplier receipt photo into a [ScanReading].
abstract class ScanReader {
  Future<ScanReading> read(String imagePath, ScanType type);
}
