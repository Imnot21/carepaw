import 'package:carepaw/core/repositories/base_repository.dart';
import 'package:carepaw/features/queue/domain/entities/queue_entry.dart';

/// Queue repository interface - domain layer contract
abstract class QueueRepository extends SoftDeleteRepository<QueueEntry, int>
    implements StreamRepository<QueueEntry, int>, PaginatedRepository<QueueEntry, int> {
  /// Sync-aware operations
  @override
  Future<QueueEntry> createWithSync(QueueEntry entity, String tableName);

  @override
  Future<QueueEntry> updateWithSync(QueueEntry entity, String tableName);

  @override
  Future<void> deleteWithSync(int id, String tableName);
  /// Find queue entry by appointment
  Future<QueueEntry?> findByAppointment(int appointmentId);

  /// Get current queue (waiting/called/in-room)
  Future<List<QueueEntryWithDetails>> getCurrentQueue();

  /// Watch current queue for real-time updates
  Stream<List<QueueEntryWithDetails>> watchCurrentQueue();

  /// Get next position in queue
  Future<int> getNextPosition();

  /// Call next patient
  Future<QueueEntry?> callNext();

  /// Move patient to room
  Future<QueueEntry> moveToRoom(int queueId);

  /// Complete queue entry
  Future<QueueEntry> complete(int queueId);

  /// Skip patient
  Future<QueueEntry> skip(int queueId);

  /// Reposition queue after changes
  Future<void> repositionQueue();

  /// Get queue entry with details
  Future<QueueEntryWithDetails?> findWithDetails(int queueId);
}