import 'package:drift/drift.dart';
import 'package:carepaw/core/database/database.dart';
import 'package:carepaw/core/database/dao/users_dao.dart';
import 'package:carepaw/core/sync/sync_repository.dart';
import 'package:carepaw/features/users/domain/repositories/user_repository.dart';
import 'package:carepaw/features/authentication/domain/entities/user.dart' as domain;

/// User repository implementation - data layer
/// Converts between Drift entities and domain entities
class UserRepositoryImpl implements UserRepository {
  final UsersDao _dao;
  final SyncRepository syncRepo;

  UserRepositoryImpl(CarePawDatabase database, {required this.syncRepo})
      : _dao = UsersDao(database);

  @override
  Future<domain.User?> findById(int id) async {
    final entity = await _dao.getById(id);
    return entity != null ? _toDomain(entity) : null;
  }

  @override
  Future<List<domain.User>> findAll() async {
    final entities = await _dao.getAllActive();
    return entities.map(_toDomain).toList();
  }

  @override
  Future<domain.User> save(domain.User entity) async {
    final companion = _toCompanion(entity);
    if (entity.id == null) {
      final id = await _dao.createUser(companion);
      return entity.copyWith(id: id);
    } else {
      await _dao.updateUser(companion);
      return entity;
    }
  }

  @override
  Future<void> delete(int id) async {
    await _dao.softDelete(id);
  }

  @override
  Future<bool> exists(int id) async {
    final entity = await _dao.getById(id);
    return entity != null;
  }

  @override
  Future<void> softDelete(int id) async {
    await _dao.softDelete(id);
  }

  @override
  Future<void> restore(int id) async {
    await _dao.updateActivity(id); // Re-activate by updating
  }

  @override
  Future<List<domain.User>> findAllIncludingDeleted() async {
    // For now, just return all active users
    // Could add a method to DAO to get all including deleted
    return findAll();
  }

  @override
  Stream<domain.User?> watchById(int id) {
    return _dao.watchById(id).map((entity) => entity != null ? _toDomain(entity) : null);
  }

  @override
  Stream<List<domain.User>> watchAll() {
    return _dao.watchAllActive().map((entities) => entities.map(_toDomain).toList());
  }

  @override
  Future<domain.User?> findByEmail(String email) async {
    final entity = await _dao.getByEmail(email);
    return entity != null ? _toDomain(entity) : null;
  }

  @override
  Future<List<domain.User>> findByRole(domain.UserRole role) async {
    final entities = await _dao.getByRole(role.value);
    return entities.map(_toDomain).toList();
  }

  @override
  Future<List<domain.User>> findVeterinarians() async {
    final entities = await _dao.getVeterinarians();
    return entities.map(_toDomain).toList();
  }

  @override
  Future<List<domain.User>> search(String query) async {
    final entities = await _dao.searchByName(query);
    return entities.map(_toDomain).toList();
  }

  @override
  Future<void> updateActivity(int userId) async {
    await _dao.updateActivity(userId);
  }

  @override
  Future<domain.User> updateProfile(int userId, {
    String? fullName,
    String? phone,
    String? avatarUrl,
  }) async {
    final existing = await _dao.getById(userId);
    if (existing == null) {
      throw Exception('User not found');
    }

    final domainUser = _toDomain(existing);
    final updated = domainUser.copyWith(
      fullName: fullName ?? domainUser.fullName,
      phone: phone ?? domainUser.phone,
      avatarUrl: avatarUrl ?? domainUser.avatarUrl,
      updatedAt: DateTime.now(),
    );

    return save(updated);
  }

  @override
  Future<domain.User> changeRole(int userId, domain.UserRole newRole) async {
    final existing = await _dao.getById(userId);
    if (existing == null) {
      throw Exception('User not found');
    }

    final domainUser = _toDomain(existing);
    final updated = domainUser.copyWith(
      role: newRole,
      updatedAt: DateTime.now(),
    );

    return save(updated);
  }

  @override
  Future<domain.User> setActive(int userId, bool isActive) async {
    final existing = await _dao.getById(userId);
    if (existing == null) {
      throw Exception('User not found');
    }

    final domainUser = _toDomain(existing);
    final updated = domainUser.copyWith(
      isActive: isActive,
      updatedAt: DateTime.now(),
    );

    return save(updated);
  }

  @override
  Future<int> countByRole(domain.UserRole role) async {
    final entities = await findByRole(role);
    return entities.length;
  }

  @override
  Future<int> getActiveCount() async {
    final entities = await findAll();
    return entities.length;
  }

  // Private mapping methods

  domain.User _toDomain(User entity) {
    return domain.User(
      id: entity.id,
      email: entity.email,
      fullName: entity.fullName,
      phone: entity.phone,
      role: domain.UserRole.fromString(entity.role),
      avatarUrl: entity.avatarUrl,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  UsersCompanion _toCompanion(domain.User entity) {
    return UsersCompanion(
      id: entity.id != null ? Value(entity.id!) : const Value.absent(),
      email: Value(entity.email),
      passwordHash: const Value.absent(), // Not handled here
      fullName: Value(entity.fullName),
      phone: Value(entity.phone),
      role: Value(entity.role.value),
      avatarUrl: Value(entity.avatarUrl),
      isActive: Value(entity.isActive),
      createdAt: entity.id == null ? Value(entity.createdAt) : const Value.absent(),
      updatedAt: Value(entity.updatedAt),
    );
  }

  @override
  Future<domain.User> createAccount({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    required domain.UserRole role,
  }) async {
    // This drift-backed repository has been set aside in favor of the
    // Firebase-first implementation (FirestoreUserRepository).
    throw UnsupportedError(
      'createAccount is not supported by the local-drift repository. '
      'Use FirestoreUserRepository instead.',
    );
  }

  @override
  Future<domain.User> createWithSync(domain.User entity, String tableName) async {
    final saved = await save(entity);
    if (saved.id != null) {
      await syncRepo.queueForSync(
        tableName: tableName,
        recordId: saved.id!,
        operation: SyncOperation.insert,
        payload: {
          'id': saved.id,
          'email': entity.email,
          'fullName': entity.fullName,
          'phone': entity.phone,
          'role': entity.role.value,
          'avatarUrl': entity.avatarUrl,
          'isActive': entity.isActive,
          'createdAt': entity.createdAt.toIso8601String(),
          'updatedAt': entity.updatedAt.toIso8601String(),
        },
      );
    }
    return saved;
  }

  @override
  Future<domain.User> updateWithSync(domain.User entity, String tableName) async {
    final saved = await save(entity);
    if (saved.id != null) {
      await syncRepo.queueForSync(
        tableName: tableName,
        recordId: saved.id!,
        operation: SyncOperation.update,
        payload: {
          'id': saved.id,
          'email': entity.email,
          'fullName': entity.fullName,
          'phone': entity.phone,
          'role': entity.role.value,
          'avatarUrl': entity.avatarUrl,
          'isActive': entity.isActive,
          'createdAt': entity.createdAt.toIso8601String(),
          'updatedAt': entity.updatedAt.toIso8601String(),
        },
      );
    }
    return saved;
  }

  @override
  Future<void> deleteWithSync(int id, String tableName) async {
    await _dao.softDelete(id);
    await syncRepo.queueForSync(
      tableName: tableName,
      recordId: id,
      operation: SyncOperation.delete,
    );
  }
}