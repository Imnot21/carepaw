import 'dart:io';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:carepaw/features/scanning/domain/services/ocr_service.dart';

/// Sends one image to the model and returns its text reply, or null.
typedef ImageTextGenerator =
    Future<String?> Function(String prompt, Uint8List bytes, String mimeType);

/// [OcrService] backed by Gemini through Firebase AI Logic.
///
/// Gemini reads curved, small and glossy print on medicine boxes far better
/// than an on-device recognizer, so it is tried first. The photo is sent to
/// Google for this one read and nothing else. When the call fails (no
/// network, quota, slow reply, AI Logic not set up) the [fallback] reads
/// the photo on the device instead, so scanning still works offline.
///
/// The reply is a transcription only: [ScanTextParser] still pulls out the
/// fields and a person confirms every scan before it is trusted.
class FirebaseAiOcrService implements OcrService {
  /// Gemini model used for the read. Flash-Lite reads labels as well as
  /// Flash for this job in a fraction of the time, inside the free tier.
  static const model = 'gemini-3.5-flash-lite';

  /// Asks for the printed text only, laid out so the rule-based parser can
  /// find the name, labels and dates.
  static const prompt = '''
Transcribe the printed text in this photo of a veterinary clinic document (a medicine box, receipt, prescription or lab report).

Rules:
- Put the main name on the first line: the medicine name with its strength for a medicine box, the store or clinic name for a receipt, the document title otherwise.
- Then write every other piece of text, one line per printed line, exactly as printed.
- Keep each label on the same line as its value, for example "EXP 12/2027", "LOT: AMX2291", "TOTAL 1,250.00".
- Copy numbers, dates and codes character for character. Do not reformat them.
- Do not guess unreadable text, translate, explain or add anything that is not printed.
- Plain text only, no markdown.
- If there is no readable text, reply with nothing.''';

  final ImageTextGenerator _generate;
  final OcrService? fallback;

  /// How long to wait for the model before reading on the device instead.
  final Duration timeout;

  FirebaseAiOcrService({
    ImageTextGenerator? generate,
    this.fallback,
    this.timeout = const Duration(seconds: 20),
  }) : _generate = generate ?? _gemini;

  static Future<String?> _gemini(
    String prompt,
    Uint8List bytes,
    String mimeType,
  ) async {
    final gemini = FirebaseAI.googleAI().generativeModel(
      model: model,
      // Low temperature: copy the text, do not get creative with it.
      generationConfig: GenerationConfig(temperature: 0),
    );
    final response = await gemini.generateContent([
      Content.multi([TextPart(prompt), InlineDataPart(mimeType, bytes)]),
    ]);
    return response.text;
  }

  @override
  Future<String> readText(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final text = await _generate(
        prompt,
        bytes,
        mimeTypeOf(imagePath),
      ).timeout(timeout);
      return clean(text);
    } catch (e) {
      debugPrint('[ocr] Firebase AI read failed, using fallback: $e');
      final backup = fallback;
      if (backup == null) rethrow;
      return backup.readText(imagePath);
    }
  }

  /// Strips a markdown code fence and blank lines the model may add anyway.
  @visibleForTesting
  static String clean(String? text) => (text ?? '')
      .replaceAll(RegExp(r'^```[a-z]*\s*$', multiLine: true), '')
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .join('\n');

  @visibleForTesting
  static String mimeTypeOf(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic')) return 'image/heic';
    return 'image/jpeg';
  }
}
