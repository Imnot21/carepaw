/// Reads printed text from a photo.
///
/// The app reads with Gemini through Firebase AI Logic and falls back to
/// on-device ML Kit when that fails. The text is a suggestion only: a
/// person confirms every scan before it is trusted (CLAUDE.md rule 2).
abstract class OcrService {
  /// Returns all text found in the image at [imagePath], line by line.
  /// Returns an empty string when no text is found.
  Future<String> readText(String imagePath);
}
