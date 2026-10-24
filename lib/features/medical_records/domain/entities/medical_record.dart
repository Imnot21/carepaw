import 'package:equatable/equatable.dart';
import 'package:carepaw/features/pets/domain/entities/pet.dart';
import 'package:carepaw/features/authentication/domain/entities/user.dart';
import 'package:carepaw/features/appointments/domain/entities/appointment.dart';

/// Medical record entity - domain layer representation
class MedicalRecord extends Equatable {
  final int? id;
  final int petId;
  final int veterinarianId;
  final int? appointmentId;
  final MedicalRecordType recordType;
  final String title;
  final String? description;
  final String? diagnosis;
  final String? treatment;
  final String? medications;
  final String? attachments;
  final DateTime recordedAt;
  final DateTime createdAt;

  /// Id of the earlier record this one corrects, or null for an original
  /// entry. Records are append-only: a mistake is fixed by adding a new
  /// record that points back here, never by editing the old one.
  final int? supersedesId;

  /// Why the earlier record was corrected. Set only on corrections.
  final String? correctionReason;

  const MedicalRecord({
    this.id,
    required this.petId,
    required this.veterinarianId,
    this.appointmentId,
    this.recordType = MedicalRecordType.visit,
    required this.title,
    this.description,
    this.diagnosis,
    this.treatment,
    this.medications,
    this.attachments,
    required this.recordedAt,
    required this.createdAt,
    this.supersedesId,
    this.correctionReason,
  });

  /// Whether this record corrects an earlier one.
  bool get isCorrection => supersedesId != null;

  /// Check if this is a vaccination record
  bool get isVaccination => recordType == MedicalRecordType.vaccination;

  /// Check if this is an allergy record
  bool get isAllergy => recordType == MedicalRecordType.allergy;

  /// Check if this is a lab result
  bool get isLabResult => recordType == MedicalRecordType.labResult;

  /// Check if this is a visit record
  bool get isVisit => recordType == MedicalRecordType.visit;

  @override
  List<Object?> get props => [
    id,
    petId,
    veterinarianId,
    appointmentId,
    recordType,
    title,
    description,
    diagnosis,
    treatment,
    medications,
    attachments,
    recordedAt,
    createdAt,
    supersedesId,
    correctionReason,
  ];

  MedicalRecord copyWith({
    int? id,
    int? petId,
    int? veterinarianId,
    int? appointmentId,
    MedicalRecordType? recordType,
    String? title,
    String? description,
    String? diagnosis,
    String? treatment,
    String? medications,
    String? attachments,
    DateTime? recordedAt,
    DateTime? createdAt,
    int? supersedesId,
    String? correctionReason,
  }) {
    return MedicalRecord(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      veterinarianId: veterinarianId ?? this.veterinarianId,
      appointmentId: appointmentId ?? this.appointmentId,
      recordType: recordType ?? this.recordType,
      title: title ?? this.title,
      description: description ?? this.description,
      diagnosis: diagnosis ?? this.diagnosis,
      treatment: treatment ?? this.treatment,
      medications: medications ?? this.medications,
      attachments: attachments ?? this.attachments,
      recordedAt: recordedAt ?? this.recordedAt,
      createdAt: createdAt ?? this.createdAt,
      supersedesId: supersedesId ?? this.supersedesId,
      correctionReason: correctionReason ?? this.correctionReason,
    );
  }
}

/// Medical record type enum
///
/// [deworming] covers deworming treatments (thesis paper lists deworming in
/// the required medical history).
enum MedicalRecordType {
  visit('VISIT'),
  vaccination('VACCINATION'),
  deworming('DEWORMING'),
  surgery('SURGERY'),
  labResult('LAB_RESULT'),
  prescription('PRESCRIPTION'),
  note('NOTE'),
  allergy('ALLERGY');

  final String value;
  const MedicalRecordType(this.value);

  static MedicalRecordType fromString(String value) {
    return MedicalRecordType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => MedicalRecordType.visit,
    );
  }

  String get displayName {
    switch (this) {
      case MedicalRecordType.visit:
        return 'Visit';
      case MedicalRecordType.vaccination:
        return 'Vaccination';
      case MedicalRecordType.deworming:
        return 'Deworming';
      case MedicalRecordType.surgery:
        return 'Surgery';
      case MedicalRecordType.labResult:
        return 'Lab Result';
      case MedicalRecordType.prescription:
        return 'Prescription';
      case MedicalRecordType.note:
        return 'Note';
      case MedicalRecordType.allergy:
        return 'Allergy';
    }
  }
}

/// Medical record with related details
class MedicalRecordWithDetails extends Equatable {
  final MedicalRecord record;
  final Pet pet;
  final User veterinarian;
  final Appointment? appointment;

  const MedicalRecordWithDetails({
    required this.record,
    required this.pet,
    required this.veterinarian,
    this.appointment,
  });

  @override
  List<Object?> get props => [record, pet, veterinarian, appointment];
}
