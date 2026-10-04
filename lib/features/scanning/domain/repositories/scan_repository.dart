import 'package:carepaw/core/repositories/base_repository.dart';
import 'package:carepaw/features/scanning/domain/entities/scan_record.dart';

/// Scan record repository interface - domain layer contract
abstract class ScanRecordRepository
    extends SoftDeleteRepository<ScanRecord, int>
    implements
        StreamRepository<ScanRecord, int>,
        PaginatedRepository<ScanRecord, int> {
  /// Sync-aware operations
  @override
  Future<ScanRecord> createWithSync(ScanRecord entity, String tableName);

  @override
  Future<ScanRecord> updateWithSync(ScanRecord entity, String tableName);

  @override
  Future<void> deleteWithSync(int id, String tableName);

  /// Find scan records by type
  Future<List<ScanRecord>> findByType(ScanType scanType);

  /// Find scan records by status
  Future<List<ScanRecord>> findByStatus(ScanStatus status);

  /// Find pending scan records
  Future<List<ScanRecord>> findPending();

  /// Confirm scan record
  Future<ScanRecord> confirm(int id, int confirmedBy, String? corrections);

  /// Reject scan record
  Future<ScanRecord> reject(int id, int rejectedBy, String reason);

  /// Update extracted data
  Future<ScanRecord> updateExtractedData(int id, String extractedData);

  /// Update confidence score
  Future<ScanRecord> updateConfidence(int id, double confidenceScore);

  /// Get scan count by status
  Future<int> countByStatus(ScanStatus status);
}
