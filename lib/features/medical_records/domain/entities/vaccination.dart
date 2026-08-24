import 'package:equatable/equatable.dart';
import 'package:carepaw/features/pets/domain/entities/pet.dart';
import 'package:carepaw/features/authentication/domain/entities/user.dart';

/// Vaccination entity - domain layer representation
class Vaccination extends Equatable {
  final int? id;
  final int petId;
  final int veterinarianId;
  final String vaccineName;
  final String? manufacturer;
  final String? batchNumber;
  final DateTime administeredAt;
  final DateTime? nextDueAt;
  final String? notes;
  final DateTime createdAt;

  const Vaccination({
    this.id,
    required this.petId,
    required this.veterinarianId,
    required this.vaccineName,
    this.manufacturer,
    this.batchNumber,
    required this.administeredAt,
    this.nextDueAt,
    this.notes,
    required this.createdAt,
  });

  /// Check if vaccination is due soon (within 30 days)
  bool get isDueSoon {
    if (nextDueAt == null) return false;
    final now = DateTime.now();
    final thirtyDaysLater = now.add(const Duration(days: 30));
    return nextDueAt!.isAfter(now) && nextDueAt!.isBefore(thirtyDaysLater);
  }

  /// Check if vaccination is overdue
  bool get isOverdue {
    if (nextDueAt == null) return false;
    return nextDueAt!.isBefore(DateTime.now());
  }

  /// Check if vaccination has a next due date
  bool get hasNextDueDate => nextDueAt != null;

  @override
  List<Object?> get props => [
        id,
        petId,
        veterinarianId,
        vaccineName,
        manufacturer,
        batchNumber,
        administeredAt,
        nextDueAt,
        notes,
        createdAt,
      ];

  Vaccination copyWith({
    int? id,
    int? petId,
    int? veterinarianId,
    String? vaccineName,
    String? manufacturer,
    String? batchNumber,
    DateTime? administeredAt,
    DateTime? nextDueAt,
    String? notes,
    DateTime? createdAt,
  }) {
    return Vaccination(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      veterinarianId: veterinarianId ?? this.veterinarianId,
      vaccineName: vaccineName ?? this.vaccineName,
      manufacturer: manufacturer ?? this.manufacturer,
      batchNumber: batchNumber ?? this.batchNumber,
      administeredAt: administeredAt ?? this.administeredAt,
      nextDueAt: nextDueAt ?? this.nextDueAt,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Vaccination with related details
class VaccinationWithDetails extends Equatable {
  final Vaccination vaccination;
  final Pet pet;
  final User veterinarian;

  const VaccinationWithDetails({
    required this.vaccination,
    required this.pet,
    required this.veterinarian,
  });

  @override
  List<Object?> get props => [vaccination, pet, veterinarian];
}