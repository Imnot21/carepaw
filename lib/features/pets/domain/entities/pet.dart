import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';

/// Pet entity - domain layer representation
class Pet extends Equatable {
  final int? id;
  final int ownerId;
  final String name;
  final PetSpecies species;
  final String? breed;
  final DateTime? birthDate;
  final double? weightKg;
  final String? color;
  final String? microchipId;
  final String? avatarUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Pet({
    this.id,
    required this.ownerId,
    required this.name,
    required this.species,
    this.breed,
    this.birthDate,
    this.weightKg,
    this.color,
    this.microchipId,
    this.avatarUrl,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Calculate pet age in years
  int? get ageInYears {
    if (birthDate == null) return null;
    final now = DateTime.now();
    int age = now.year - birthDate!.year;
    if (now.month < birthDate!.month || (now.month == birthDate!.month && now.day < birthDate!.day)) {
      age--;
    }
    return age;
  }

  /// Check if pet is a puppy/kitten (under 1 year)
  bool get isYoung => ageInYears != null && ageInYears! < 1;

  /// Check if pet is senior (7+ years for dogs/cats)
  bool get isSenior {
    final age = ageInYears;
    if (age == null) return false;
    return age >= 7;
  }

  @override
  List<Object?> get props => [
        id,
        ownerId,
        name,
        species,
        breed,
        birthDate,
        weightKg,
        color,
        microchipId,
        avatarUrl,
        isActive,
        createdAt,
        updatedAt,
      ];

  Pet copyWith({
    int? id,
    int? ownerId,
    String? name,
    PetSpecies? species,
    String? breed,
    DateTime? birthDate,
    double? weightKg,
    String? color,
    String? microchipId,
    String? avatarUrl,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Pet(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      species: species ?? this.species,
      breed: breed ?? this.breed,
      birthDate: birthDate ?? this.birthDate,
      weightKg: weightKg ?? this.weightKg,
      color: color ?? this.color,
      microchipId: microchipId ?? this.microchipId,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Pet species enum
enum PetSpecies {
  dog('DOG'),
  cat('CAT'),
  bird('BIRD'),
  rabbit('RABBIT'),
  reptile('REPTILE'),
  other('OTHER');

  final String value;
  const PetSpecies(this.value);

  static PetSpecies fromString(String value) {
    return PetSpecies.values.firstWhere(
      (species) => species.value == value,
      orElse: () => PetSpecies.other,
    );
  }

  String get displayName {
    switch (this) {
      case PetSpecies.dog:
        return 'Dog';
      case PetSpecies.cat:
        return 'Cat';
      case PetSpecies.bird:
        return 'Bird';
      case PetSpecies.rabbit:
        return 'Rabbit';
      case PetSpecies.reptile:
        return 'Reptile';
      case PetSpecies.other:
        return 'Other';
    }
  }

  Color get accentColor {
    switch (this) {
      case PetSpecies.dog:
        return AppColors.dogAccent;
      case PetSpecies.cat:
        return AppColors.catAccent;
      case PetSpecies.bird:
        return AppColors.birdAccent;
      case PetSpecies.rabbit:
        return AppColors.rabbitAccent;
      case PetSpecies.reptile:
        return AppColors.reptileAccent;
      case PetSpecies.other:
        return AppColors.otherAccent;
    }
  }
}