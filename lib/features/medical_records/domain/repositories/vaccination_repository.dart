import 'package:carepaw/core/repositories/base_repository.dart';
import 'package:carepaw/features/medical_records/domain/entities/vaccination.dart';

/// Vaccination repository interface - domain layer contract
abstract class VaccinationRepository
    implements
        StreamRepository<Vaccination, int>,
        PaginatedRepository<Vaccination, int>,
        BaseRepository<Vaccination, int> {
  /// Sync-aware operations
  @override
  Future<Vaccination> createWithSync(Vaccination entity, String tableName);
  @override
  Future<Vaccination> updateWithSync(Vaccination entity, String tableName);
  @override
  Future<void> deleteWithSync(int id, String tableName);

  /// Find all vaccinations for a pet
  Future<List<Vaccination>> findByPet(int petId);

  /// Watch vaccinations for a pet (real-time)
  Stream<List<Vaccination>> watchByPet(int petId);

  /// Find upcoming due vaccinations
  Future<List<Vaccination>> findDueSoon({int days = 30});

  /// Find overdue vaccinations
  Future<List<Vaccination>> findOverdue();

  /// Find vaccinations with details for a pet
  Future<List<VaccinationWithDetails>> findWithDetailsByPet(int petId);

  /// Create vaccination record
  Future<Vaccination> create(Vaccination vaccination);

  /// Update vaccination
  Future<Vaccination> update(Vaccination vaccination);

  /// Get count of due soon vaccinations for a pet
  Future<int> countDueSoon(int petId, {int days = 30});

  /// Get count of overdue vaccinations for a pet
  Future<int> countOverdue(int petId);
}
