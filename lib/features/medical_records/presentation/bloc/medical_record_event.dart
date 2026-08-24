import 'package:equatable/equatable.dart';
import 'package:carepaw/features/medical_records/domain/entities/medical_record.dart';

/// Base class for all medical record events.
abstract class MedicalRecordEvent extends Equatable {
  const MedicalRecordEvent();

  @override
  List<Object?> get props => [];
}

/// Load all medical records for a pet.
class LoadMedicalRecords extends MedicalRecordEvent {
  final int petId;

  const LoadMedicalRecords(this.petId);

  @override
  List<Object?> get props => [petId];
}

/// Load medical records filtered by type.
class LoadMedicalRecordsByType extends MedicalRecordEvent {
  final int petId;
  final MedicalRecordType recordType;

  const LoadMedicalRecordsByType(this.petId, this.recordType);

  @override
  List<Object?> get props => [petId, recordType];
}

/// Load a single medical record with details.
class LoadMedicalRecordDetails extends MedicalRecordEvent {
  final int recordId;

  const LoadMedicalRecordDetails(this.recordId);

  @override
  List<Object?> get props => [recordId];
}

/// Create a new visit record.
class CreateVisitRecord extends MedicalRecordEvent {
  final int petId;
  final int veterinarianId;
  final int? appointmentId;
  final String title;
  final String? description;
  final String? diagnosis;
  final String? treatment;
  final String? medications;
  final String? attachments;

  const CreateVisitRecord({
    required this.petId,
    required this.veterinarianId,
    this.appointmentId,
    required this.title,
    this.description,
    this.diagnosis,
    this.treatment,
    this.medications,
    this.attachments,
  });

  @override
  List<Object?> get props => [
    petId,
    veterinarianId,
    appointmentId,
    title,
    description,
    diagnosis,
    treatment,
    medications,
    attachments,
  ];
}

/// Create a new vaccination record.
class CreateVaccinationRecord extends MedicalRecordEvent {
  final int petId;
  final int veterinarianId;
  final int? appointmentId;
  final String title;
  final String? description;
  final String? medications;

  const CreateVaccinationRecord({
    required this.petId,
    required this.veterinarianId,
    this.appointmentId,
    required this.title,
    this.description,
    this.medications,
  });

  @override
  List<Object?> get props => [
    petId,
    veterinarianId,
    appointmentId,
    title,
    description,
    medications,
  ];
}

/// Create a new allergy record.
class CreateAllergyRecord extends MedicalRecordEvent {
  final int petId;
  final int veterinarianId;
  final String title;
  final String description;

  const CreateAllergyRecord({
    required this.petId,
    required this.veterinarianId,
    required this.title,
    required this.description,
  });

  @override
  List<Object?> get props => [petId, veterinarianId, title, description];
}

/// Create a new lab result record.
class CreateLabResultRecord extends MedicalRecordEvent {
  final int petId;
  final int veterinarianId;
  final int? appointmentId;
  final String title;
  final String description;

  const CreateLabResultRecord({
    required this.petId,
    required this.veterinarianId,
    this.appointmentId,
    required this.title,
    required this.description,
  });

  @override
  List<Object?> get props => [
    petId,
    veterinarianId,
    appointmentId,
    title,
    description,
  ];
}

/// Get recent medical records across all pets.
class LoadRecentRecords extends MedicalRecordEvent {
  final int limit;

  const LoadRecentRecords({this.limit = 20});

  @override
  List<Object?> get props => [limit];
}