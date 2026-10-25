import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:carepaw/features/scanning/data/services/firebase_ai_scan_reader.dart';
import 'package:carepaw/features/scanning/domain/entities/scan_record.dart';
import 'package:carepaw/features/scanning/domain/services/ocr_service.dart';

class _FakeOcr implements OcrService {
  int calls = 0;

  @override
  Future<String> readText(String imagePath) async {
    calls++;
    return 'Amoxicillin 250mg\nEXP 12/2027\nLOT: AMX2291';
  }
}

void main() {
  late Directory dir;
  late String imagePath;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('scan_test');
    imagePath = '${dir.path}/scan.jpg';
    File(imagePath).writeAsBytesSync([0xFF, 0xD8, 0xFF]);
  });

  tearDown(() => dir.deleteSync(recursive: true));

  group('FirebaseAiScanReader', () {
    test('reads the supplier and every receipt line', () async {
      final reader = FirebaseAiScanReader(
        generate: (prompt, bytes, mimeType) async => '''
{"supplier": "VetPharma Supply", "text": "VetPharma Supply\\n\\n 10 x Amoxicillin ",
 "items": [
  {"name": " Amoxicillin 250mg ", "quantity": 10, "unit": "box", "lot": "AMX2291", "expiry": "2027-12-31"},
  {"name": "Meloxicam 1.5mg", "quantity": 2, "unit": null, "lot": "", "expiry": null},
  {"name": "", "quantity": 1}
 ]}''',
      );

      final reading = await reader.read(imagePath, ScanType.receipt);

      expect(reading.supplier, 'VetPharma Supply');
      expect(reading.rawText, 'VetPharma Supply\n10 x Amoxicillin');
      expect(reading.lines, hasLength(2));
      expect(reading.lines[0].name, 'Amoxicillin 250mg');
      expect(reading.lines[0].quantity, 10);
      expect(reading.lines[0].expiry, '2027-12-31');
      expect(reading.lines[1].unit, isNull);
      expect(reading.lines[1].lot, isNull);
    });

    test('asks for a receipt or a box depending on the scan type', () async {
      final prompts = <String>[];
      final reader = FirebaseAiScanReader(
        generate: (prompt, bytes, mimeType) async {
          prompts.add(prompt);
          return '{"text": "", "items": []}';
        },
      );

      await reader.read(imagePath, ScanType.receipt);
      await reader.read(imagePath, ScanType.medicineBox);

      expect(prompts[0], FirebaseAiScanReader.receiptPrompt);
      expect(prompts[1], FirebaseAiScanReader.medicineBoxPrompt);
    });

    test('accepts JSON wrapped in a code fence', () {
      final reading = FirebaseAiScanReader.parseReply(
        '```json\n{"text": "x", "items": [{"name": "Cefalexin"}]}\n```',
      );
      expect(reading.lines.single.name, 'Cefalexin');
      expect(reading.lines.single.quantity, isNull);
    });

    test('sends the photo bytes and its type to the model', () async {
      String? sentType;
      List<int>? sentBytes;
      final reader = FirebaseAiScanReader(
        generate: (prompt, bytes, mimeType) async {
          sentType = mimeType;
          sentBytes = bytes;
          return null;
        },
      );

      final reading = await reader.read(imagePath, ScanType.medicineBox);

      expect(reading.isEmpty, isTrue);
      expect(sentType, 'image/jpeg');
      expect(sentBytes, [0xFF, 0xD8, 0xFF]);
    });

    test('falls back to the on-device reader when the reply is not JSON',
        () async {
      final fallback = _FakeOcr();
      final reader = FirebaseAiScanReader(
        generate: (prompt, bytes, mimeType) async => 'Amoxicillin 250mg',
        fallback: fallback,
      );

      final reading = await reader.read(imagePath, ScanType.medicineBox);

      expect(fallback.calls, 1);
      final line = reading.lines.single;
      expect(line.name, 'Amoxicillin 250mg');
      expect(line.quantity, 1);
      expect(line.lot, 'AMX2291');
      expect(line.expiry, '12/2027');
    });

    test('falls back when the model is too slow', () async {
      final fallback = _FakeOcr();
      final reader = FirebaseAiScanReader(
        generate: (prompt, bytes, mimeType) => Completer<String?>().future,
        fallback: fallback,
        timeout: const Duration(milliseconds: 10),
      );

      final reading = await reader.read(imagePath, ScanType.receipt);

      expect(fallback.calls, 1);
      expect(reading.lines, isEmpty);
      expect(reading.supplier, 'Amoxicillin 250mg');
    });

    test('rethrows when the model fails and there is no fallback', () async {
      final reader = FirebaseAiScanReader(
        generate: (prompt, bytes, mimeType) async => throw Exception('offline'),
      );

      expect(reader.read(imagePath, ScanType.receipt), throwsException);
    });

    test('picks the image type from the file name', () {
      expect(FirebaseAiScanReader.mimeTypeOf('a.PNG'), 'image/png');
      expect(FirebaseAiScanReader.mimeTypeOf('a.webp'), 'image/webp');
      expect(FirebaseAiScanReader.mimeTypeOf('a.jpg'), 'image/jpeg');
    });
  });
}
