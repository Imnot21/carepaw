import 'package:carepaw/core/repositories/base_repository.dart';
import 'package:carepaw/features/authentication/domain/entities/user.dart';

/// User repository interface - domain layer contract
abstract class UserRepository extends SoftDeleteRepository<User, int> implements StreamRepository<User, int> {
  /// Find user by email
  Future<User?> findByEmail(String email);

  /// Find users by role
  Future<List<User>> findByRole(UserRole role);

  /// Find veterinarians
  Future<List<User>> findVeterinarians();

  /// Search users by name or email
  Future<List<User>> search(String query);

  /// Update user activity timestamp
  Future<void> updateActivity(int userId);

  /// Create a new account (admin only) backed by Firebase Auth + Firestore.
  ///
  /// Creates the Firebase Authentication credential and the Firestore
  /// `users/{uid}` document with the given role.
  Future<User> createAccount({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    required UserRole role,
  });

  /// Update user profile
  Future<User> updateProfile(int userId, {
    String? fullName,
    String? phone,
    String? avatarUrl,
  });

  /// Change user role (admin only)
  Future<User> changeRole(int userId, UserRole newRole);

  /// Activate/Deactivate user (admin only)
  Future<User> setActive(int userId, bool isActive);

  /// Get user count by role
  Future<int> countByRole(UserRole role);

  /// Get total active user count
  Future<int> getActiveCount();

  /// Sync-aware operations
  @override
  Future<User> createWithSync(User entity, String tableName);

  @override
  Future<User> updateWithSync(User entity, String tableName);

  @override
  Future<void> deleteWithSync(int id, String tableName);
}