/// Base repository interface defining common CRUD operations
/// This is the domain layer contract - no Drift dependencies
abstract class BaseRepository<T, ID> {
  /// Find an entity by its ID
  Future<T?> findById(ID id);

  /// Find all entities
  Future<List<T>> findAll();

  /// Save an entity (create or update)
  Future<T> save(T entity);

  /// Delete an entity by ID
  Future<void> delete(ID id);

  /// Check if entity exists
  Future<bool> exists(ID id);

  /// Sync-aware operations - implementations should queue changes for Firestore sync
  // These are optional overrides for repositories that need cloud sync
  Future<T> createWithSync(T entity, String tableName);
  Future<T> updateWithSync(T entity, String tableName);
  Future<void> deleteWithSync(ID id, String tableName);
}

/// Repository interface for entities with soft delete support
abstract class SoftDeleteRepository<T, ID> implements BaseRepository<T, ID> {
  /// Soft delete an entity (mark as inactive)
  Future<void> softDelete(ID id);

  /// Restore a soft-deleted entity
  Future<void> restore(ID id);

  /// Find all entities including soft-deleted ones
  Future<List<T>> findAllIncludingDeleted();
}

/// Repository interface for entities with streaming/real-time support
abstract class StreamRepository<T, ID> implements BaseRepository<T, ID> {
  /// Watch an entity by ID for real-time updates
  Stream<T?> watchById(ID id);

  /// Watch all entities for real-time updates
  Stream<List<T>> watchAll();
}

/// Pagination parameters
class PaginationParams {
  final int page;
  final int pageSize;
  final String? orderBy;
  final bool ascending;

  const PaginationParams({
    this.page = 1,
    this.pageSize = 20,
    this.orderBy,
    this.ascending = true,
  });

  int get offset => (page - 1) * pageSize;
}

/// Paginated result wrapper
class PaginatedResult<T> {
  final List<T> items;
  final int totalCount;
  final int page;
  final int pageSize;
  final int totalPages;

  PaginatedResult({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  }) : totalPages = (totalCount / pageSize).ceil();

  bool get hasNextPage => page < totalPages;
  bool get hasPreviousPage => page > 1;
}

/// Repository interface with pagination support
abstract class PaginatedRepository<T, ID> implements BaseRepository<T, ID> {
  /// Find entities with pagination
  Future<PaginatedResult<T>> findPaginated(PaginationParams params);
}
