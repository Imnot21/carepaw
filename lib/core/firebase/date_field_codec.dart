import 'package:cloud_firestore/cloud_firestore.dart';

/// Encoding helpers for reading/writing [DateTime] values in Firestore.
///
/// Firestore stores timestamps as `Timestamp`. Writing a raw Dart `DateTime`
/// is not reliably converted by the SDK, so values are normalized with
/// [toFirestoreDate] on write and [fromFirestoreDate] on read (accepting
/// `Timestamp`, `DateTime` or ISO-8601 `String` for robustness).
class DateFieldCodec {
  DateFieldCodec._();

  /// Encode a nullable [DateTime] as a Firestore `Timestamp` (or `null`).
  static Timestamp? toFirestoreDate(DateTime? value) {
    return value == null ? null : Timestamp.fromDate(value);
  }

  /// Decode a Firestore value back into a nullable [DateTime].
  static DateTime? fromFirestoreDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}