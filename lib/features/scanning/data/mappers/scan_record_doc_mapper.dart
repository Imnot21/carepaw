import 'package:carepaw/core/firebase/date_field_codec.dart';
import 'package:carepaw/core/firebase/firestore_schema.dart';
import 'package:carepaw/features/scanning/domain/entities/scan_record.dart';

/// Maps between Firestore `scanRecords/{id}` documents and the domain [ScanRecord].
///
/// Field names mirror the Drift table via [FirestoreSchema]. The document ID
/// is the string form of `ScanRecord.id`.
class ScanRecordDocMapper {
  ScanRecordDocMapper._();

  /// Build a domain [ScanRecord] from Firestore document data.
  static ScanRecord fromData(Map<String, dynamic> data) {
    return ScanRecord(
      id: data[FirestoreSchema.id] as int?,
      scanType: ScanType.fromString((data[FirestoreSchema.scanType] as String?) ?? ''),
      imagePath: (data[FirestoreSchema.imagePath] as String?) ?? '',
      rawOcrText: data[FirestoreSchema.rawOcrText] as String?,
      extractedData: data[FirestoreSchema.extractedData] as String?,
      confidenceScore: (data[FirestoreSchema.confidenceScore] as num?)?.toDouble(),
      status: ScanStatus.fromString((data[FirestoreSchema.statusScan] as String?) ?? ''),
      confirmedBy: (data[FirestoreSchema.confirmedBy] as num?)?.toInt(),
      confirmedAt: DateFieldCodec.fromFirestoreDate(data[FirestoreSchema.confirmedAt]),
      corrections: data[FirestoreSchema.corrections] as String?,
      createdAt: DateFieldCodec.fromFirestoreDate(data[FirestoreSchema.createdAt]) ?? DateTime.now(),
    );
  }

  /// Serialize a domain [ScanRecord] to a Firestore document map.
  static Map<String, dynamic> toData(ScanRecord scan) {
    return {
      FirestoreSchema.id: scan.id,
      FirestoreSchema.scanType: scan.scanType.value,
      FirestoreSchema.imagePath: scan.imagePath,
      FirestoreSchema.rawOcrText: scan.rawOcrText,
      FirestoreSchema.extractedData: scan.extractedData,
      FirestoreSchema.confidenceScore: scan.confidenceScore,
      FirestoreSchema.statusScan: scan.status.value,
      FirestoreSchema.confirmedBy: scan.confirmedBy,
      FirestoreSchema.confirmedAt: DateFieldCodec.toFirestoreDate(scan.confirmedAt),
      FirestoreSchema.corrections: scan.corrections,
      FirestoreSchema.createdAt: DateFieldCodec.toFirestoreDate(scan.createdAt),
    };
  }
}