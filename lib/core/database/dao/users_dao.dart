import 'package:drift/drift.dart';
import 'package:carepaw/core/database/database.dart';
import 'package:carepaw/core/database/tables.dart';

part 'users_dao.g.dart';

@DriftAccessor(tables: [Users])
class UsersDao extends DatabaseAccessor<CarePawDatabase> with _$UsersDaoMixin {
  UsersDao(super.db);

  // ============ Queries ============

  /// Get user by email
  Future<User?> getByEmail(String email) {
    return (select(users)..where((u) => u.email.equals(email))).getSingleOrNull();
  }

  /// Get user by ID
  Future<User?> getById(int id) {
    return (select(users)..where((u) => u.id.equals(id))).getSingleOrNull();
  }

  /// Get all active users
  Future<List<User>> getAllActive() {
    return (select(users)..where((u) => u.isActive.equals(true))).get();
  }

  /// Get users by role
  Future<List<User>> getByRole(String role) {
    return (select(users)..where((u) => u.role.equals(role))).get();
  }

  /// Get veterinarians
  Future<List<User>> getVeterinarians() {
    return getByRole('VETERINARIAN');
  }

  /// Search users by name
  Future<List<User>> searchByName(String query) {
    return (select(users)
          ..where((u) => u.fullName.like('%$query%') | u.email.like('%$query%')))
        .get();
  }

  // ============ Mutations ============

  /// Create a new user
  Future<int> createUser(UsersCompanion user) {
    return into(users).insert(user);
  }

  /// Update user
  Future<bool> updateUser(UsersCompanion user) {
    return update(users).replace(user);
  }

  /// Soft delete user
  Future<int> softDelete(int id) {
    return (update(users)..where((u) => u.id.equals(id)))
        .write(UsersCompanion(isActive: const Value(false)));
  }

  /// Update last login / activity
  Future<int> updateActivity(int id) {
    return (update(users)..where((u) => u.id.equals(id)))
        .write(UsersCompanion(updatedAt: Value(DateTime.now())));
  }

  /// Watch user by ID
  Stream<User?> watchById(int id) {
    return (select(users)..where((u) => u.id.equals(id))).watchSingleOrNull();
  }

  /// Watch all active users
  Stream<List<User>> watchAllActive() {
    return (select(users)..where((u) => u.isActive.equals(true))).watch();
  }
}