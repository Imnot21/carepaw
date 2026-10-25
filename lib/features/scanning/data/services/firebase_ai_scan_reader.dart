import 'dart:convert';
import 'dart:io';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:carepaw/features/scanning/domain/entities/scan_record.dart';
import 'package:carepaw/features/scanning/domain/services/ocr_service.dart';
import 'package:carepaw/features/scanning/domain/services/scan_reader.dart';

/// Sends one image to the model and returns its text reply, or null.
typedef ImageTextGenerator =
    Future<String?> Function(String prompt, Uint8List bytes, String mimeType);

/// [ScanReader] backed by Gemini through Firebase AI Logic.
///
/// Gemini reads curved, small and glossy print on medicine boxes far better
/// than an on-device recognizer, and can split a supplier receipt into its
/// medicine lines, so it is tried first. It replies in JSON shaped by
/// [responseSchema]. The photo is sent to Google for this one read and
/// nothing else. When the call fails (no network, quota, slow reply, AI
/// Logic not set up) the [fallback] reads the text on the device and the
/// rule-based parser fills what it can, so scanning still works offline.
///
/// Every value is a suggestion: the review screen lets the person correct
/// it before anything is added to stock.
class FirebaseAiScanReader implements ScanReader {
  /// Gemini model used for the read. Flash-Lite reads labels as well as
  /// Flash for this job in a fraction of the time, inside the free tier.
  static const model = 'gemini-3.5-flash-lite';

  static const _rules = '''
Rules:
- Copy names, numbers, lot codes and dates exactly as printed. Do not guess: use null for anything you cannot read.
- name: the medicine name with its strength, e.g. "Amoxicillin 250mg".
- expiry: write it as YYYY-MM-DD. If only the month and year are printed, use the last day of that month.
- text: every piece of printed text, one line per printed line.
- If there is no readable text, return an empty items list and empty text.''';

  static const medicineBoxPrompt =
      '''
This is a photo of a veterinary medicine box, bottle or vial. Read it into JSON.
- items: exactly one item for the medicine shown. quantity is 1 unless several identical boxes are visible. unit is the container: box, bottle, vial or pack. lot is the lot or batch number.
- supplier: the manufacturer or distributor if printed, else null.
$_rules''';

  static const receiptPrompt =
      '''
This is a photo of a supplier receipt, invoice or delivery note for a veterinary clinic. Read it into JSON.
- supplier: the supplier or store name, usually at the top.
- items: one item per medicine or product line. quantity is how many units were bought on that line, never the price. unit as printed (box, bottle, vial, pcs), else "pcs". lot and expiry only if printed on that line.
- Skip totals, tax, discounts, payment and change lines.
$_rules''';

  /// The JSON shape the model must reply with.
  static final responseSchema = Schema.object(
    properties: {
      'supplier': Schema.string(nullable: true),
      'text': Schema.string(),
      'items': Schema.array(
        items: Schema.object(
          properties: {
            'name': Schema.string(),
            'quantity': Schema.number(nullable: true),
            'unit': Schema.string(nullable: true),
            'lot': Schema.string(nullable: true),
            'expiry': Schema.string(nullable: true),
          },
          optionalProperties: ['quantity', 'unit', 'lot', 'expiry'],
        ),
      ),
    },
    optionalProperties: ['supplier'],
  );

  final ImageTextGenerator _generate;
  final OcrService? fallback;

  /// How long to wait for the model before reading on the device instead.
  final Duration timeout;

  FirebaseAiScanReader({
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
      generationConfig: GenerationConfig(
        // Low temperature: copy the text, do not get creative with it.
        temperature: 0,
        responseMimeType: 'application/json',
        responseSchema: responseSchema,
      ),
    );
    final response = await gemini.generateContent([
      Content.multi([TextPart(prompt), InlineDataPart(mimeType, bytes)]),
    ]);
    return response.text;
  }

  @override
  Future<ScanReading> read(String imagePath, ScanType type) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final reply = await _generate(
        type == ScanType.receipt ? receiptPrompt : medicineBoxPrompt,
        bytes,
        mimeTypeOf(imagePath),
      ).timeout(timeout);
      return parseReply(reply);
    } catch (e) {
      debugPrint('[scan] Firebase AI read failed, using fallback: $e');
      final backup = fallback;
      if (backup == null) rethrow;
      return ScanReading.fromText(await backup.readText(imagePath), type);
    }
  }

  /// Turns the model's JSON reply into a [ScanReading].
  ///
  /// Throws [FormatException] when the reply is not the expected JSON, so
  /// [read] falls back to the on-device reader.
  @visibleForTesting
  static ScanReading parseReply(String? reply) {
    final body = (reply ?? '')
        .replaceAll(RegExp(r'^```[a-z]*\s*$', multiLine: true), '')
        .trim();
    if (body.isEmpty) return const ScanReading();
    final json = jsonDecode(body);
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Expected a JSON object');
    }

    final lines = <ScannedLine>[];
    for (final raw in (json['items'] as List?) ?? const []) {
      if (raw is! Map) continue;
      final name = _text(raw['name']);
      if (name == null) continue;
      final quantity = raw['quantity'];
      lines.add(
        ScannedLine(
          name: name,
          quantity: quantity is num && quantity > 0
              ? quantity.toDouble()
              : null,
          unit: _text(raw['unit']),
          lot: _text(raw['lot']),
          expiry: _text(raw['expiry']),
        ),
      );
    }
    return ScanReading(
      supplier: _text(json['supplier']),
      lines: lines,
      rawText: (_text(json['text']) ?? '')
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .join('\n'),
    );
  }

  /// Trimmed string value, or null when missing, blank or "null".
  static String? _text(Object? value) {
    if (value == null) return null;
    final s = value.toString().trim();
    return s.isEmpty || s.toLowerCase() == 'null' ? null : s;
  }

  @visibleForTesting
  static String mimeTypeOf(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic')) return 'image/heic';
    return 'image/jpeg';
  }
}
