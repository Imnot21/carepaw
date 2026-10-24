import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:carepaw/features/scanning/domain/services/ocr_service.dart';

/// [OcrService] backed by Google ML Kit's on-device Latin text recognizer.
/// No network call is made; the model ships inside the app.
class MlKitOcrService implements OcrService {
  @override
  Future<String> readText(String imagePath) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(
        InputImage.fromFilePath(imagePath),
      );
      return result.text.trim();
    } finally {
      await recognizer.close();
    }
  }
}
