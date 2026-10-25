import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:carepaw/features/scanning/data/services/firebase_ai_scan_reader.dart';
import 'package:carepaw/features/scanning/data/services/mlkit_ocr_service.dart';
import 'package:carepaw/features/scanning/domain/entities/scan_record.dart';
import 'package:carepaw/features/scanning/domain/services/scan_text_parser.dart';

/// Runs the real on-device ML Kit reader, so it needs an Android or iOS
/// device or emulator:
///
/// `flutter test integration_test/mlkit_ocr_test.dart -d <device-id>`
///
/// The label images are drawn here, so no photos are bundled. They are
/// clean print; a real phone photo of a box is still the final check.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final ocr = MlKitOcrService();

  testWidgets('reads a medicine box label', (tester) async {
    final path = await _labelImage('box', [
      'Amoxicillin 250mg',
      'Oral Suspension',
      'LOT: AMX2291',
      'EXP 12/2027',
    ]);

    final raw = await ocr.readText(path);
    debugPrint('[ocr] box:\n$raw');
    final f = ScanTextParser.parse(raw, ScanType.medicineBox);

    expect(f.values['Name'], contains('Amoxicillin'));
    expect(f.values['Lot / Batch'], 'AMX2291');
    expect(f.values['Expiry'], '12/2027');
    expect(f.confidence, 1.0);
  });

  testWidgets('reads small, tilted print on a grey label', (tester) async {
    final path = await _labelImage(
      'box-small',
      ['Doxycycline 100mg', 'Expiry Date', '2027-03-01', 'Batch No. D-88'],
      fontSize: 24,
      ink: const Color(0xFF333333),
      paper: const Color(0xFFE8E4DC),
      tilt: 4,
    );

    final raw = await ocr.readText(path);
    debugPrint('[ocr] box-small:\n$raw');
    final f = ScanTextParser.parse(raw, ScanType.medicineBox);

    expect(f.values['Name'], contains('Doxycycline'));
    expect(f.values['Expiry'], '2027-03-01');
    expect(f.values['Lot / Batch'], 'D-88');
  });

  testWidgets('reads a supplier receipt', (tester) async {
    final path = await _labelImage('receipt', [
      'Pila Vet Supply',
      '10/24/2026',
      'Subtotal 450.00',
      'VAT 54.00',
      'TOTAL PHP 504.00',
    ]);

    final raw = await ocr.readText(path);
    debugPrint('[ocr] receipt:\n$raw');
    final f = ScanTextParser.parse(raw, ScanType.receipt);

    expect(f.values['Store'], 'Pila Vet Supply');
    expect(f.values['Date'], '10/24/2026');
    expect(f.values['Total'], '504.00');
  });

  testWidgets('a blank photo gives no text, not a guess', (tester) async {
    final path = await _labelImage('blank', const []);

    expect(await ocr.readText(path), isEmpty);
  });

  testWidgets('when Gemini fails, the scan still reads on the device', (
    tester,
  ) async {
    final path = await _labelImage('offline', [
      'Amoxicillin 250mg',
      'LOT: AMX2291',
      'EXP 12/2027',
    ]);
    final reader = FirebaseAiScanReader(
      generate: (_, _, _) async =>
          throw const SocketException('No internet connection'),
      fallback: ocr,
    );

    final reading = await reader.read(path, ScanType.medicineBox);

    final line = reading.lines.single;
    expect(line.name, contains('Amoxicillin'));
    expect(line.lot, 'AMX2291');
    expect(line.expiry, '12/2027');
  });
}

/// Draws [lines] as printed text on a plain label and saves it as a PNG.
/// Returns the file path.
Future<String> _labelImage(
  String name,
  List<String> lines, {
  double fontSize = 40,
  Color ink = Colors.black,
  Color paper = Colors.white,
  double tilt = 0,
}) async {
  const width = 900;
  final height = 160 + (lines.length * fontSize * 1.6).round();
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)
    ..drawRect(
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      Paint()..color = paper,
    );

  if (lines.isNotEmpty) {
    final builder =
        ui.ParagraphBuilder(ui.ParagraphStyle(fontSize: fontSize, height: 1.4))
          ..pushStyle(ui.TextStyle(color: ink))
          ..addText(lines.join('\n'));
    final paragraph = builder.build()
      ..layout(const ui.ParagraphConstraints(width: width - 120));
    canvas
      ..translate(width / 2, height / 2)
      ..rotate(tilt * math.pi / 180)
      ..translate(-width / 2, -height / 2)
      ..drawParagraph(paragraph, const Offset(60, 60));
  }

  final image = await recorder.endRecording().toImage(width, height);
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File('${Directory.systemTemp.path}/ocr-$name.png');
  await file.writeAsBytes(png!.buffer.asUint8List());
  return file.path;
}
