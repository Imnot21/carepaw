import 'package:equatable/equatable.dart';
import 'package:carepaw/features/scanning/domain/entities/scan_record.dart';

/// Base class for all scan events.
abstract class ScanEvent extends Equatable {
  const ScanEvent();

  @override
  List<Object?> get props => [];
}

/// Load all scan records.
class LoadScanRecords extends ScanEvent {
  const LoadScanRecords();

  @override
  List<Object?> get props => [];
}

/// Load scan records by type.
class LoadScanRecordsByType extends ScanEvent {
  final ScanType scanType;

  const LoadScanRecordsByType(this.scanType);

  @override
  List<Object?> get props => [scanType];
}

/// Load pending scan records.
class LoadPendingScans extends ScanEvent {
  const LoadPendingScans();

  @override
  List<Object?> get props => [];
}

/// Load a single scan record with details.
class LoadScanRecordDetails extends ScanEvent {
  final int recordId;

  const LoadScanRecordDetails(this.recordId);

  @override
  List<Object?> get props => [recordId];
}

/// Create a new scan record (from camera/gallery).
class CreateScanRecord extends ScanEvent {
  final ScanType scanType;
  final String imagePath;

  const CreateScanRecord({
    required this.scanType,
    required this.imagePath,
  });

  @override
  List<Object?> get props => [scanType, imagePath];
}

/// Process OCR for a scan record.
class ProcessScanOcr extends ScanEvent {
  final int recordId;

  const ProcessScanOcr(this.recordId);

  @override
  List<Object?> get props => [recordId];
}

/// Confirm a scan record (user verified OCR results).
class ConfirmScanRecord extends ScanEvent {
  final int recordId;
  final String? corrections;

  const ConfirmScanRecord({
    required this.recordId,
    this.corrections,
  });

  @override
  List<Object?> get props => [recordId, corrections];
}

/// Reject a scan record.
class RejectScanRecord extends ScanEvent {
  final int recordId;
  final String reason;

  const RejectScanRecord({
    required this.recordId,
    required this.reason,
  });

  @override
  List<Object?> get props => [recordId, reason];
}

/// Retry OCR processing.
class RetryOcrProcessing extends ScanEvent {
  final int recordId;

  const RetryOcrProcessing(this.recordId);

  @override
  List<Object?> get props => [recordId];
}

/// Delete a scan record.
class DeleteScanRecord extends ScanEvent {
  final int recordId;

  const DeleteScanRecord(this.recordId);

  @override
  List<Object?> get props => [recordId];
}