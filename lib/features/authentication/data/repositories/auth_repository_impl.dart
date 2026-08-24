import 'package:drift/drift.dart' show Value;
import 'package:carepaw/core/database/database.dart' as db;
import 'package:carepaw/core/database/dao/users_dao.dart';
import 'package:carepaw/core/security/password_hasher.dart';
import 'package:carepaw/core/security/secure_storage.dart';
import 'package:carepaw/core/storage/local_storage.dart';
import 'package:carepaw/features/authentication/domain/repositories/auth_repository.dart';
import 'package:carepaw/features/authentication/domain/entities/user.dart'
    as auth_entities;
import 'package:carepaw/core/errors/failures.dart';
import 'package:carepaw/core/errors/error_handler.dart';
import 'package:carepaw/core/utils/validators.dart';
import 'dart:async';
import 'dart:math';

/// Typedefs for cleaner code
typedef AuthResult = auth_entities.AuthResult;
typedef DomainUser = auth_entities.User;
typedef UserRole = auth_entities.UserRole;
typedef UsersCompanion = db.UsersCompanion;
typedef UserEntity = db.User; // Drift generated entity class

/// Private class for reset token data
class _ResetTokenData {
  final int userId;
  final DateTime expiresAt;

  _ResetTokenData(this.userId, this.expiresAt);
}

/// Authentication repository implementation - data layer.
///
/// Implements [AuthRepository] using:
/// - [UsersDao] for database operations
/// - [SecureStorage] for token storage
/// - [LocalStorage] for session flags
/// - [PasswordHasher] for password verification
class AuthRepositoryImpl implements AuthRepository {
  final UsersDao _usersDao;

  // Stream controller for auth state changes
  final _authStateController = StreamController<auth_entities.AuthResult?>.broadcast();

  // In-memory storage for password reset tokens (in production, use Redis or database)
  static final Map<String, _ResetTokenData> _resetTokens = {};

  AuthRepositoryImpl(
    db.CarePawDatabase database,
  ) : _usersDao = UsersDao(database);

  @override
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      // Find user by email
      final userEntity = await _usersDao.getByEmail(email);
      if (userEntity == null) {
        throw UserNotFoundFailure();
      }

      // Check if user is active
      if (!userEntity.isActive) {
        throw AccountLockedFailure();
      }

      // Verify password
      final isValid = PasswordHasher.verify(password, userEntity.passwordHash);
      if (!isValid) {
        throw InvalidCredentialsFailure();
      }

      // Update last activity
      await _usersDao.updateActivity(userEntity.id);

      // Generate tokens
      final authResult = _generateAuthResult(userEntity);

      // Store tokens securely
      await _storeTokens(authResult);

      // Update local storage flags
      await _setLocalSession(authResult.user);

      // Emit auth state
      _authStateController.add(authResult);

      // Rehash password if needed (upgrade cost factor)
      final newHash = PasswordHasher.maybeRehash(password, userEntity.passwordHash);
      if (newHash != null) {
        await _usersDao.updateUser(
          UsersCompanion(
            id: Value(userEntity.id),
            passwordHash: Value(newHash),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }

      return authResult;
    } on AuthFailure {
      rethrow;
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  @override
  Future<AuthResult> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    UserRole role = UserRole.petOwner,
  }) async {
    try {
      // Check if email already exists
      final existingUser = await _usersDao.getByEmail(email);
      if (existingUser != null) {
        throw EmailAlreadyInUseFailure();
      }

      // Validate password strength
      final passwordError = Validators.validatePassword(password);
      if (passwordError != null) {
        throw WeakPasswordFailure(message: passwordError);
      }

      // Hash password
      final passwordHash = PasswordHasher.hash(password);

      // Create user
      final userId = await _usersDao.createUser(
        UsersCompanion(
          email: Value(email),
          passwordHash: Value(passwordHash),
          fullName: Value(fullName),
          phone: Value(phone),
          role: Value(role.value),
          isActive: const Value(true),
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      );

      // Fetch created user
      final userEntity = await _usersDao.getById(userId);
      if (userEntity == null) {
        throw UnexpectedFailure(message: 'Failed to create user');
      }

      // Generate tokens
      final authResult = _generateAuthResult(userEntity);

      // Store tokens securely
      await _storeTokens(authResult);

      // Update local storage flags
      await _setLocalSession(authResult.user);

      // Emit auth state
      _authStateController.add(authResult);

      return authResult;
    } on AuthFailure {
      rethrow;
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  @override
  Future<void> logout() async {
    try {
      // Clear secure storage
      await SecureStorage.clearAuthData();

      // Clear local storage
      await LocalStorage.clearAuthData();

      // Emit unauthenticated state
      _authStateController.add(null);
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  @override
  Future<AuthResult?> getCurrentUser() async {
    try {
      // Read tokens from secure storage
      final accessToken = await SecureStorage.getAuthToken();
      final storedRefreshToken = await SecureStorage.getRefreshToken();

      if (accessToken == null || storedRefreshToken == null) {
        return null;
      }

      // Get user ID from local storage
      final userId = LocalStorage.getUserId();
      if (userId == null) {
        // No user ID, clear tokens and return null
        await SecureStorage.clearAuthData();
        await LocalStorage.clearAuthData();
        return null;
      }

      // Fetch user from database
      final userEntity = await _usersDao.getById(userId);
      if (userEntity == null || !userEntity.isActive) {
        // User not found or inactive, clear session
        await logout();
        return null;
      }

      // Check token expiry (simplified - in production use JWT with exp claim)
      // For now, we trust the refresh token expiry stored in secure storage
      final expiryString = await SecureStorage.read(SecureStorageKeys.tokenExpiry);
      if (expiryString != null) {
        final expiry = DateTime.tryParse(expiryString);
        if (expiry != null && DateTime.now().isAfter(expiry)) {
          // Tokens expired, try to refresh
          try {
            return await refreshToken();
          } catch (_) {
            await logout();
            return null;
          }
        }
      }

      // Generate new auth result with existing tokens
      final authResult = AuthResult(
        user: _toDomain(userEntity),
        accessToken: accessToken,
        refreshToken: storedRefreshToken,
        expiresAt: expiryString != null
            ? DateTime.parse(expiryString)
            : DateTime.now().add(const Duration(days: 30)),
      );

      // Emit auth state
      _authStateController.add(authResult);

      return authResult;
    } catch (e) {
      // On any error, clear session and return null
      await logout();
      return null;
    }
  }

  @override
  Future<AuthResult> refreshToken() async {
    try {
      final refreshToken = await SecureStorage.getRefreshToken();
      if (refreshToken == null) {
        throw SessionExpiredFailure();
      }

      // Get user ID
      final userId = LocalStorage.getUserId();
      if (userId == null) {
        throw SessionExpiredFailure();
      }

      // Verify user still exists and is active
      final userEntity = await _usersDao.getById(userId);
      if (userEntity == null || !userEntity.isActive) {
        throw SessionExpiredFailure();
      }

      // Generate new tokens
      final authResult = _generateAuthResult(userEntity);

      // Store new tokens
      await _storeTokens(authResult);

      // Emit auth state
      _authStateController.add(authResult);

      return authResult;
    } on AuthFailure {
      rethrow;
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final userId = LocalStorage.getUserId();
      if (userId == null) {
        throw SessionExpiredFailure();
      }

      final userEntity = await _usersDao.getById(userId);
      if (userEntity == null) {
        throw UserNotFoundFailure();
      }

      // Verify current password
      final isValid = PasswordHasher.verify(currentPassword, userEntity.passwordHash);
      if (!isValid) {
        throw InvalidCredentialsFailure();
      }

      // Validate new password
      final passwordError = Validators.validatePassword(newPassword);
      if (passwordError != null) {
        throw WeakPasswordFailure();
      }

      // Hash new password
      final newHash = PasswordHasher.hash(newPassword);

      // Update password in database
      await _usersDao.updateUser(
        UsersCompanion(
          id: Value(userId),
          passwordHash: Value(newHash),
          updatedAt: Value(DateTime.now()),
        ),
      );

      // Update activity
      await _usersDao.updateActivity(userId);
    } on AuthFailure {
      rethrow;
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  @override
  Future<void> forgotPassword(String email) async {
    try {
      // In a real implementation, this would:
      // 1. Generate a secure reset token
      // 2. Store it with expiry (e.g., 1 hour)
      // 3. Send email with reset link
      // 4. Log audit event

      // For now, we simulate by checking if user exists (but don't reveal it)
      final userEntity = await _usersDao.getByEmail(email);

      // Always succeed from user perspective (security: don't reveal email existence)
      // But log the attempt for audit
      if (userEntity != null) {
        // Generate a secure reset token
        final resetToken = _generateToken();
        final expiresAt = DateTime.now().add(const Duration(hours: 1));

        // Store token in memory (in production, use Redis/database)
        _resetTokens[resetToken] = _ResetTokenData(userEntity.id, expiresAt);

        // TODO: Implement actual email sending
        // await _emailService.sendPasswordReset(userEntity.email, resetToken);

        // For testing, print the token (in production, remove this)
        // print('Password reset token for ${userEntity.email}: $resetToken');
      }
    } catch (e) {
      // Don't throw - always succeed from user perspective
      // Log error internally
    }
  }

  @override
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      // Validate token
      final tokenData = _resetTokens[token];
      if (tokenData == null) {
        throw InvalidCredentialsFailure();
      }

      // Check if token is expired
      if (DateTime.now().isAfter(tokenData.expiresAt)) {
        _resetTokens.remove(token);
        throw InvalidCredentialsFailure();
      }

      // Validate new password
      final passwordError = Validators.validatePassword(newPassword);
      if (passwordError != null) {
        throw WeakPasswordFailure();
      }

      // Get user and update password
      final userEntity = await _usersDao.getById(tokenData.userId);
      if (userEntity == null) {
        throw UserNotFoundFailure();
      }

      // Hash new password
      final newHash = PasswordHasher.hash(newPassword);

      // Update password in database
      await _usersDao.updateUser(
        UsersCompanion(
          id: Value(userEntity.id),
          passwordHash: Value(newHash),
          updatedAt: Value(DateTime.now()),
        ),
      );

      // Remove used token
      _resetTokens.remove(token);

      // Clear any existing sessions (optional - force re-login)
      // await logout();
    } on AuthFailure {
      rethrow;
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  @override
  Stream<AuthResult?> get authStateStream => _authStateController.stream;

  /// Generate authentication result with tokens
  AuthResult _generateAuthResult(UserEntity userEntity) {
    final now = DateTime.now();
    final accessToken = _generateToken();
    final refreshToken = _generateToken();
    final expiresAt = now.add(const Duration(days: 30)); // Long-lived refresh token

    final domainUser = _toDomain(userEntity);

    return AuthResult(
      user: domainUser,
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: expiresAt,
    );
  }

  /// Generate a secure random token
  String _generateToken() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
  }

  /// Store tokens in secure storage
  Future<void> _storeTokens(AuthResult authResult) async {
    await SecureStorage.saveAuthToken(authResult.accessToken);
    await SecureStorage.saveRefreshToken(authResult.refreshToken);
    await SecureStorage.write(
      SecureStorageKeys.tokenExpiry,
      authResult.expiresAt.toIso8601String(),
    );
  }

  /// Set local session flags
  Future<void> _setLocalSession(DomainUser user) async {
    await LocalStorage.setUserId(user.id!);
    await LocalStorage.setUserRole(user.role.value);
    await LocalStorage.setLoggedIn(true);
  }

  /// Convert Drift entity to domain entity
  DomainUser _toDomain(UserEntity entity) {
    return DomainUser(
      id: entity.id,
      email: entity.email,
      fullName: entity.fullName,
      phone: entity.phone,
      role: UserRole.fromString(entity.role),
      avatarUrl: entity.avatarUrl,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Dispose resources
  void dispose() {
    _authStateController.close();
  }
}