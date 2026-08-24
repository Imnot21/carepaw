import 'package:equatable/equatable.dart';
import 'package:carepaw/features/pets/domain/entities/pet.dart';

/// Base class for all pet events.
abstract class PetEvent extends Equatable {
  const PetEvent();

  @override
  List<Object?> get props => [];
}

/// Load all pets for the current user.
class LoadPets extends PetEvent {
  final int ownerId;

  const LoadPets({required this.ownerId});

  @override
  List<Object?> get props => [ownerId];
}

/// Create a new pet.
class CreatePet extends PetEvent {
  final Pet pet;

  const CreatePet({required this.pet});

  @override
  List<Object?> get props => [pet];
}

/// Update an existing pet.
class UpdatePet extends PetEvent {
  final Pet pet;

  const UpdatePet({required this.pet});

  @override
  List<Object?> get props => [pet];
}

/// Delete a pet (soft delete).
class DeletePet extends PetEvent {
  final int petId;

  const DeletePet({required this.petId});

  @override
  List<Object?> get props => [petId];
}

/// Update pet weight.
class UpdatePetWeight extends PetEvent {
  final int petId;
  final double weightKg;

  const UpdatePetWeight({required this.petId, required this.weightKg});

  @override
  List<Object?> get props => [petId, weightKg];
}

/// Search pets by name.
class SearchPets extends PetEvent {
  final int ownerId;
  final String query;

  const SearchPets({required this.ownerId, required this.query});

  @override
  List<Object?> get props => [ownerId, query];
}

/// Load a single pet by ID.
class LoadPetsById extends PetEvent {
  final int petId;

  const LoadPetsById(this.petId);

  @override
  List<Object?> get props => [petId];
}

/// Load all pets (for staff/admin).
class LoadAllPets extends PetEvent {
  const LoadAllPets();

  @override
  List<Object?> get props => [];
}

/// Search all pets by name (for staff/admin).
class SearchAllPets extends PetEvent {
  final String query;

  const SearchAllPets({required this.query});

  @override
  List<Object?> get props => [query];
}