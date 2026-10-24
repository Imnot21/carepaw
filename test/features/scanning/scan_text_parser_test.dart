import 'package:flutter_test/flutter_test.dart';
import 'package:carepaw/features/scanning/domain/entities/scan_record.dart';
import 'package:carepaw/features/scanning/domain/services/scan_text_parser.dart';

void main() {
  group('ScanTextParser', () {
    test('medicine box: name, expiry and lot', () {
      const raw = 'Amoxicillin 250mg\nOral Suspension\nLOT: AMX2291\nEXP 12/2027';
      final f = ScanTextParser.parse(raw, ScanType.medicineBox);
      expect(f.values['Name'], 'Amoxicillin 250mg');
      expect(f.values['Expiry'], '12/2027');
      expect(f.values['Lot / Batch'], 'AMX2291');
      expect(f.confidence, 1.0);
    });

    test('medicine box: expiry date on the line after its label', () {
      const raw = 'Doxycycline\nExpiry Date\n2027-03-01\nBatch No. D-88';
      final f = ScanTextParser.parse(raw, ScanType.medicineBox);
      expect(f.values['Expiry'], '2027-03-01');
      expect(f.values['Lot / Batch'], 'D-88');
    });

    test('receipt: store, date and the grand total, not the subtotal', () {
      const raw =
          'Pila Vet Supply\n10/24/2026\nSubtotal 450.00\nVAT 54.00\nTOTAL PHP 504.00';
      final f = ScanTextParser.parse(raw, ScanType.receipt);
      expect(f.values['Store'], 'Pila Vet Supply');
      expect(f.values['Date'], '10/24/2026');
      expect(f.values['Total'], '504.00');
      expect(f.confidence, 1.0);
    });

    test('partial read lowers confidence', () {
      final f = ScanTextParser.parse('Vitamin B Complex', ScanType.medicineBox);
      expect(f.values.keys, ['Name']);
      expect(f.confidence, closeTo(1 / 3, 0.001));
    });

    test('no text means no fields and zero confidence', () {
      final f = ScanTextParser.parse('  \n ', ScanType.receipt);
      expect(f.isEmpty, isTrue);
      expect(f.confidence, 0);
    });

    test('display is one Label: value line per field', () {
      const raw = 'Lab Result\n2026-10-01';
      final f = ScanTextParser.parse(raw, ScanType.labReport);
      expect(f.toDisplay(), 'Title: Lab Result\nDate: 2026-10-01');
    });
  });
}
