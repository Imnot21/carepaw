/// Reads printed text from a photo.
///
/// Implementations run on the device, so photos of receipts and medicine
/// boxes never leave the phone. The text is a suggestion only: a person
/// confirms every scan before it is trusted (CLAUDE.md rule 2).
abstract class OcrService {
  /// Returns all text found in the image at [imagePath], line by line.
  /// Returns an empty string when no text is found.
  Future<String> readText(String imagePath);
}
