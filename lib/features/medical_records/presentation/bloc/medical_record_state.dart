import 'package:equatable/equatable.dart';
import 'package:carepaw/features/medical_records/domain/entities/medical_record.dart';
import 'package:carepaw/core/errors/failures.dart';

/// Base class for all medical record states.
abstract class MedicalRecordState extends Equatable {
  const MedicalRecordState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any operations.
class MedicalRecordInitial extends MedicalRecordState {
  const MedicalRecordInitial();
}

/// Loading state during operations.
class MedicalRecordLoading extends MedicalRecordState {
  const MedicalRecordLoading();
}

/// State with loaded medical records list.
class MedicalRecordsLoaded extends MedicalRecordState {
  final List<MedicalRecord> records;

  const MedicalRecordsLoaded(this.records);

  @override
  List<Object?> get props => [records];
}

/// State with loaded medical records filtered by type.
class MedicalRecordsByTypeLoaded extends MedicalRecordState {
  final List<MedicalRecord> records;
  final MedicalRecordType recordType;

  const MedicalRecordsByTypeLoaded(this.records, this.recordType);

  @override
  List<Object?> get props => [records, recordType];
}

/// State with loaded recent records.
class RecentRecordsLoaded extends MedicalRecordState {
  final List<MedicalRecordWithDetails> records;

  const RecentRecordsLoaded(this.records);

  @override
  List<Object?> get props => [records];
}

/// State with a single record detail loaded.
class MedicalRecordDetailLoaded extends MedicalRecordState {
  final MedicalRecordWithDetails record;

  const MedicalRecordDetailLoaded(this.record);

  @override
  List<Object?> get props => [record];
}

/// State when an operation succeeded.
class MedicalRecordOperationSuccess extends MedicalRecordState {
  final String message;

  const MedicalRecordOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

/// Error state with failure information.
class MedicalRecordError extends MedicalRecordState {
  final Failure failure;

  const MedicalRecordError(this.failure);

  @override
  List<Object?> get props => [failure];
}
