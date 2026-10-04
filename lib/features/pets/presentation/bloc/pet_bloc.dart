import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carepaw/features/pets/domain/repositories/pet_repository.dart';
import 'package:carepaw/features/pets/presentation/bloc/pet_event.dart';
import 'package:carepaw/features/pets/presentation/bloc/pet_state.dart';
import 'package:carepaw/core/errors/failures.dart';

/// Pet BLoC for managing pet state.
///
/// Handles loading, creating, updating, deleting pets and weight tracking.
class PetBloc extends Bloc<PetEvent, PetState> {
  final PetRepository _petRepository;

  PetBloc({required PetRepository petRepository})
    : _petRepository = petRepository,
      super(const PetInitial()) {
    on<LoadPets>(_onLoadPets);
    on<CreatePet>(_onCreatePet);
    on<UpdatePet>(_onUpdatePet);
    on<DeletePet>(_onDeletePet);
    on<UpdatePetWeight>(_onUpdatePetWeight);
    on<SearchPets>(_onSearchPets);
    on<LoadPetsById>(_onLoadPetsById);
    on<LoadAllPets>(_onLoadAllPets);
    on<SearchAllPets>(_onSearchAllPets);
  }

  /// Load all pets for the current user.
  Future<void> _onLoadPets(LoadPets event, Emitter<PetState> emit) async {
    emit(const PetLoading());
    try {
      final pets = await _petRepository.findByOwner(event.ownerId);
      emit(PetsLoaded(pets));
    } on Failure catch (failure) {
      emit(PetError(failure));
    } catch (e) {
      emit(PetError(UnexpectedFailure(message: e.toString())));
    }
  }

  /// Create a new pet.
  Future<void> _onCreatePet(CreatePet event, Emitter<PetState> emit) async {
    emit(const PetLoading());
    try {
      final createdPet = await _petRepository.save(event.pet);
      emit(const PetOperationSuccess('Pet created successfully'));
      // Reload pets to show updated list
      final pets = await _petRepository.findByOwner(createdPet.ownerId);
      emit(PetsLoaded(pets));
    } on Failure catch (failure) {
      emit(PetError(failure));
    } catch (e) {
      emit(PetError(UnexpectedFailure(message: e.toString())));
    }
  }

  /// Update an existing pet.
  Future<void> _onUpdatePet(UpdatePet event, Emitter<PetState> emit) async {
    emit(const PetLoading());
    try {
      await _petRepository.save(event.pet);
      emit(const PetOperationSuccess('Pet updated successfully'));
      // Reload pets to show updated list
      final pets = await _petRepository.findByOwner(event.pet.ownerId);
      emit(PetsLoaded(pets));
    } on Failure catch (failure) {
      emit(PetError(failure));
    } catch (e) {
      emit(PetError(UnexpectedFailure(message: e.toString())));
    }
  }

  /// Delete a pet (soft delete).
  Future<void> _onDeletePet(DeletePet event, Emitter<PetState> emit) async {
    emit(const PetLoading());
    try {
      await _petRepository.softDelete(event.petId);
      emit(const PetOperationSuccess('Pet deleted successfully'));
      // Note: We don't know ownerId here, so the parent should reload
      // Or we could add ownerId to DeletePet event
    } on Failure catch (failure) {
      emit(PetError(failure));
    } catch (e) {
      emit(PetError(UnexpectedFailure(message: e.toString())));
    }
  }

  /// Update pet weight.
  Future<void> _onUpdatePetWeight(
    UpdatePetWeight event,
    Emitter<PetState> emit,
  ) async {
    emit(const PetLoading());
    try {
      final updatedPet = await _petRepository.updateWeight(
        event.petId,
        event.weightKg,
      );
      emit(const PetOperationSuccess('Weight updated successfully'));
      // Reload pets to show updated list
      final pets = await _petRepository.findByOwner(updatedPet.ownerId);
      emit(PetsLoaded(pets));
    } on Failure catch (failure) {
      emit(PetError(failure));
    } catch (e) {
      emit(PetError(UnexpectedFailure(message: e.toString())));
    }
  }

  /// Search pets by name.
  Future<void> _onSearchPets(SearchPets event, Emitter<PetState> emit) async {
    emit(const PetLoading());
    try {
      final pets = await _petRepository.searchByName(
        event.ownerId,
        event.query,
      );
      emit(PetsLoaded(pets));
    } on Failure catch (failure) {
      emit(PetError(failure));
    } catch (e) {
      emit(PetError(UnexpectedFailure(message: e.toString())));
    }
  }

  /// Load a single pet by ID.
  Future<void> _onLoadPetsById(
    LoadPetsById event,
    Emitter<PetState> emit,
  ) async {
    emit(const PetLoading());
    try {
      final pet = await _petRepository.findById(event.petId);
      if (pet != null) {
        emit(PetDetailLoaded(pet));
      } else {
        emit(const PetError(UnexpectedFailure(message: 'Pet not found')));
      }
    } on Failure catch (failure) {
      emit(PetError(failure));
    } catch (e) {
      emit(PetError(UnexpectedFailure(message: e.toString())));
    }
  }

  /// Load all pets (for staff/admin).
  Future<void> _onLoadAllPets(LoadAllPets event, Emitter<PetState> emit) async {
    emit(const PetLoading());
    try {
      final pets = await _petRepository.findAll();
      emit(PetsLoaded(pets));
    } on Failure catch (failure) {
      emit(PetError(failure));
    } catch (e) {
      emit(PetError(UnexpectedFailure(message: e.toString())));
    }
  }

  /// Search all pets by name (for staff/admin).
  Future<void> _onSearchAllPets(
    SearchAllPets event,
    Emitter<PetState> emit,
  ) async {
    emit(const PetLoading());
    try {
      final pets = await _petRepository.searchAllByName(event.query);
      emit(PetsLoaded(pets));
    } on Failure catch (failure) {
      emit(PetError(failure));
    } catch (e) {
      emit(PetError(UnexpectedFailure(message: e.toString())));
    }
  }
}
