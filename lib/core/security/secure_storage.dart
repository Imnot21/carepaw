import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage service for sensitive data.
///
/// Uses platform-specific secure storage:
/// - iOS: Keychain
/// - Android: Encrypted SharedPreferences (AndroidOptions.encryptedSharedPreferences is now the default)
/// - Web: Not supported (throws UnsupportedError)
///
/// Use for storing sensitive data like:
/// - Authentication tokens
/// - API keys
/// - User credentials
class SecureStorage {
  SecureStorage._();
  static FlutterSecureStorage? _storage;

  /// Default storage configuration
  static const _defaultOptions = AndroidOptions(
    resetOnError: true,
    migrateOnAlgorithmChange: true,
  );

  /// Initialize secure storage
  static void init() {
    _storage = const FlutterSecureStorage(aOptions: _defaultOptions);
  }

  /// Ensure storage is initialized
  static FlutterSecureStorage get _instance {
    if (_storage == null) {
      throw StateError(
        'SecureStorage not initialized. Call SecureStorage.init() first.',
      );
    }
    return _storage!;
  }

  // ============ String Operations ============

  /// Save a value securely
  static Future<void> write(String key, String value) {
    return _instance.write(key: key, value: value);
  }

  /// Read a secure value
  static Future<String?> read(String key) {
    return _instance.read(key: key);
  }

  /// Check if a key exists
  static Future<bool> containsKey(String key) {
    return _instance.containsKey(key: key);
  }

  /// Delete a value
  static Future<void> delete(String key) {
    return _instance.delete(key: key);
  }

  /// Delete all stored values
  static Future<void> deleteAll() {
    return _instance.deleteAll();
  }

  /// Get all stored keys and values
  static Future<Map<String, String>> readAll() {
    return _instance.readAll();
  }

  // ============ Convenience Methods ============

  /// Save authentication token
  static Future<void> saveAuthToken(String token) {
    return write(SecureStorageKeys.authToken, token);
  }

  /// Get authentication token
  static Future<String?> getAuthToken() {
    return read(SecureStorageKeys.authToken);
  }

  /// Delete authentication token
  static Future<void> deleteAuthToken() {
    return delete(SecureStorageKeys.authToken);
  }

  /// Save refresh token
  static Future<void> saveRefreshToken(String token) {
    return write(SecureStorageKeys.refreshToken, token);
  }

  /// Get refresh token
  static Future<String?> getRefreshToken() {
    return read(SecureStorageKeys.refreshToken);
  }

  /// Delete refresh token
  static Future<void> deleteRefreshToken() {
    return delete(SecureStorageKeys.refreshToken);
  }

  /// Clear all authentication data
  static Future<void> clearAuthData() async {
    await deleteAuthToken();
    await deleteRefreshToken();
  }
}

/// Secure storage keys for sensitive data
abstract class SecureStorageKeys {
  SecureStorageKeys._();

  static const String authToken = 'auth_token';
  static const String refreshToken = 'refresh_token';
  static const String apiKey = 'api_key';
  static const String userPassword =
      'user_password'; // Only if absolutely necessary
  static const String tokenExpiry = 'token_expiry';
}
