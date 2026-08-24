import 'package:equatable/equatable.dart';
import 'package:carepaw/features/pets/domain/entities/pet.dart';
import 'package:carepaw/core/errors/failures.dart';

/// Base class for all pet states.
abstract class PetState extends Equatable {
  const PetState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any pet operations.
class PetInitial extends PetState {
  const PetInitial();
}

/// Loading state during pet operations.
class PetLoading extends PetState {
  const PetLoading();
}

/// State with loaded pets list.
class PetsLoaded extends PetState {
  final List<Pet> pets;

  const PetsLoaded(this.pets);

  @override
  List<Object?> get props => [pets];
}

/// State when a pet operation succeeded.
class PetOperationSuccess extends PetState {
  final String message;

  const PetOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

/// State when a single pet is loaded.
class PetDetailLoaded extends PetState {
  final Pet pet;

  const PetDetailLoaded(this.pet);

  @override
  List<Object?> get props => [pet];
}

/// Error state with failure information.
class PetError extends PetState {
  final Failure failure;

  const PetError(this.failure);

  @override
  List<Object?> get props => [failure];
}