import 'package:carepaw/core/repositories/base_repository.dart';
import 'package:carepaw/features/pets/domain/entities/pet.dart';

/// Pet repository interface - domain layer contract
abstract class PetRepository extends SoftDeleteRepository<Pet, int>
    implements StreamRepository<Pet, int>, PaginatedRepository<Pet, int> {
  /// Find all pets for an owner
  Future<List<Pet>> findByOwner(int ownerId);

  /// Watch pets for an owner (real-time)
  Stream<List<Pet>> watchByOwner(int ownerId);

  /// Search pets by name for an owner
  Future<List<Pet>> searchByName(int ownerId, String query);

  /// Find pet with owner info
  Future<Pet?> findWithOwner(int petId);

  /// Update pet weight
  Future<Pet> updateWeight(int petId, double weightKg);

  /// Get pet count for an owner
  Future<int> countByOwner(int ownerId);

  /// Get active pet count for an owner
  Future<int> countActiveByOwner(int ownerId);

  /// Search all pets by name (for staff/admin)
  Future<List<Pet>> searchAllByName(String query);

  /// Sync-aware operations
  @override
  Future<Pet> createWithSync(Pet entity, String tableName);

  @override
  Future<Pet> updateWithSync(Pet entity, String tableName);

  @override
  Future<void> deleteWithSync(int id, String tableName);
}