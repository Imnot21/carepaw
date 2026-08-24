import 'package:equatable/equatable.dart';
import 'package:carepaw/features/scanning/domain/entities/scan_record.dart';
import 'package:carepaw/core/errors/failures.dart';

/// Base class for all scan states.
abstract class ScanState extends Equatable {
  const ScanState();

  @override
  List<Object?> get props => [];
}

/// Initial state.
class ScanInitial extends ScanState {
  const ScanInitial();
}

/// Loading state.
class ScanLoading extends ScanState {
  const ScanLoading();
}

/// Scan records loaded state.
class ScanRecordsLoaded extends ScanState {
  final List<ScanRecord> records;

  const ScanRecordsLoaded(this.records);

  @override
  List<Object?> get props => [records];
}

/// Scan records by type loaded state.
class ScanRecordsByTypeLoaded extends ScanState {
  final List<ScanRecord> records;
  final ScanType scanType;

  const ScanRecordsByTypeLoaded(this.records, this.scanType);

  @override
  List<Object?> get props => [records, scanType];
}

/// Pending scans loaded state.
class PendingScansLoaded extends ScanState {
  final List<ScanRecord> records;

  const PendingScansLoaded(this.records);

  @override
  List<Object?> get props => [records];
}

/// Scan record details loaded state.
class ScanRecordDetailLoaded extends ScanState {
  final ScanRecord record;

  const ScanRecordDetailLoaded(this.record);

  @override
  List<Object?> get props => [record];
}

/// OCR processing state.
class ScanOcrProcessing extends ScanState {
  final int recordId;

  const ScanOcrProcessing(this.recordId);

  @override
  List<Object?> get props => [recordId];
}

/// OCR processing complete state.
class ScanOcrCompleted extends ScanState {
  final ScanRecord record;

  const ScanOcrCompleted(this.record);

  @override
  List<Object?> get props => [record];
}

/// Scan confirmed state.
class ScanConfirmed extends ScanState {
  final String message;

  const ScanConfirmed(this.message);

  @override
  List<Object?> get props => [message];
}

/// Scan rejected state.
class ScanRejected extends ScanState {
  final String message;

  const ScanRejected(this.message);

  @override
  List<Object?> get props => [message];
}

/// Operation success state.
class ScanOperationSuccess extends ScanState {
  final String message;

  const ScanOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

/// Error state.
class ScanError extends ScanState {
  final Failure failure;

  const ScanError(this.failure);

  @override
  List<Object?> get props => [failure];
}