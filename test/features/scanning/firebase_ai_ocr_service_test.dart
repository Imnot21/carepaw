import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:carepaw/features/scanning/data/services/firebase_ai_ocr_service.dart';
import 'package:carepaw/features/scanning/domain/services/ocr_service.dart';

class _FakeOcr implements OcrService {
  int calls = 0;

  @override
  Future<String> readText(String imagePath) async {
    calls++;
    return 'on-device text';
  }
}

void main() {
  late Directory dir;
  late String imagePath;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('ocr_test');
    imagePath = '${dir.path}/scan.jpg';
    File(imagePath).writeAsBytesSync([0xFF, 0xD8, 0xFF]);
  });

  tearDown(() => dir.deleteSync(recursive: true));

  group('FirebaseAiOcrService', () {
    test('returns the model text with fences and blank lines removed', () async {
      final service = FirebaseAiOcrService(
        generate: (prompt, bytes, mimeType) async =>
            '```text\nAmoxicillin 250mg\n\n  EXP 12/2027  \nLOT: AMX2291\n```',
      );

      expect(
        await service.readText(imagePath),
        'Amoxicillin 250mg\nEXP 12/2027\nLOT: AMX2291',
      );
    });

    test('sends the photo bytes and its type to the model', () async {
      String? sentType;
      List<int>? sentBytes;
      final service = FirebaseAiOcrService(
        generate: (prompt, bytes, mimeType) async {
          sentType = mimeType;
          sentBytes = bytes;
          return '';
        },
      );

      await service.readText(imagePath);

      expect(sentType, 'image/jpeg');
      expect(sentBytes, [0xFF, 0xD8, 0xFF]);
    });

    test('returns an empty string when the model finds no text', () async {
      final service = FirebaseAiOcrService(
        generate: (prompt, bytes, mimeType) async => null,
      );

      expect(await service.readText(imagePath), '');
    });

    test('falls back to the on-device reader when the model fails', () async {
      final fallback = _FakeOcr();
      final service = FirebaseAiOcrService(
        generate: (prompt, bytes, mimeType) async => throw Exception('offline'),
        fallback: fallback,
      );

      expect(await service.readText(imagePath), 'on-device text');
      expect(fallback.calls, 1);
    });

    test('falls back when the model is too slow', () async {
      final fallback = _FakeOcr();
      final service = FirebaseAiOcrService(
        generate: (prompt, bytes, mimeType) => Completer<String?>().future,
        fallback: fallback,
        timeout: const Duration(milliseconds: 10),
      );

      expect(await service.readText(imagePath), 'on-device text');
    });

    test('rethrows when the model fails and there is no fallback', () async {
      final service = FirebaseAiOcrService(
        generate: (prompt, bytes, mimeType) async => throw Exception('offline'),
      );

      expect(service.readText(imagePath), throwsException);
    });

    test('picks the image type from the file name', () {
      expect(FirebaseAiOcrService.mimeTypeOf('a.PNG'), 'image/png');
      expect(FirebaseAiOcrService.mimeTypeOf('a.webp'), 'image/webp');
      expect(FirebaseAiOcrService.mimeTypeOf('a.jpg'), 'image/jpeg');
    });
  });
}
