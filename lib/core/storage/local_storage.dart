import 'package:shared_preferences/shared_preferences.dart';

/// Local storage service using SharedPreferences.
///
/// Provides a type-safe interface for storing and retrieving
/// simple key-value pairs locally on the device.
class LocalStorage {
  LocalStorage._();
  static SharedPreferences? _prefs;

  /// Initialize local storage
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Ensure storage is initialized
  static SharedPreferences get _instance {
    if (_prefs == null) {
      throw StateError(
        'LocalStorage not initialized. Call LocalStorage.init() first.',
      );
    }
    return _prefs!;
  }

  // ============ String Operations ============

  /// Save a string value
  static Future<bool> setString(String key, String value) {
    return _instance.setString(key, value);
  }

  /// Get a string value
  static String? getString(String key) {
    return _instance.getString(key);
  }

  // ============ Int Operations ============

  /// Save an integer value
  static Future<bool> setInt(String key, int value) {
    return _instance.setInt(key, value);
  }

  /// Get an integer value
  static int? getInt(String key) {
    return _instance.getInt(key);
  }

  // ============ Double Operations ============

  /// Save a double value
  static Future<bool> setDouble(String key, double value) {
    return _instance.setDouble(key, value);
  }

  /// Get a double value
  static double? getDouble(String key) {
    return _instance.getDouble(key);
  }

  // ============ Bool Operations ============

  /// Save a boolean value
  static Future<bool> setBool(String key, bool value) {
    return _instance.setBool(key, value);
  }

  /// Get a boolean value
  static bool? getBool(String key) {
    return _instance.getBool(key);
  }

  // ============ String List Operations ============

  /// Save a list of strings
  static Future<bool> setStringList(String key, List<String> value) {
    return _instance.setStringList(key, value);
  }

  /// Get a list of strings
  static List<String>? getStringList(String key) {
    return _instance.getStringList(key);
  }

  // ============ General Operations ============

  /// Check if a key exists
  static bool containsKey(String key) {
    return _instance.containsKey(key);
  }

  /// Get all keys
  static Set<String> getKeys() {
    return _instance.getKeys();
  }

  /// Remove a value
  static Future<bool> remove(String key) {
    return _instance.remove(key);
  }

  /// Clear all stored values
  static Future<bool> clear() {
    return _instance.clear();
  }

  // ============ Auth Convenience Methods ============

  /// Get stored user ID
  static int? getUserId() {
    return getInt(StorageKeys.userId);
  }

  /// Set user ID
  static Future<bool> setUserId(int userId) {
    return setInt(StorageKeys.userId, userId);
  }

  /// Get stored user role
  static String? getUserRole() {
    return getString(StorageKeys.userRole);
  }

  /// Set user role
  static Future<bool> setUserRole(String role) {
    return setString(StorageKeys.userRole, role);
  }

  /// Check if user is logged in
  static bool isLoggedIn() {
    return getBool(StorageKeys.isLoggedIn) ?? false;
  }

  /// Set logged in status
  static Future<bool> setLoggedIn(bool value) {
    return setBool(StorageKeys.isLoggedIn, value);
  }

  /// Clear all auth-related data
  static Future<void> clearAuthData() async {
    await remove(StorageKeys.authToken);
    await remove(StorageKeys.refreshToken);
    await remove(StorageKeys.userId);
    await remove(StorageKeys.userRole);
    await remove(StorageKeys.isLoggedIn);
  }
}

/// Common storage keys used throughout the app
abstract class StorageKeys {
  StorageKeys._();

  // Auth
  static const String authToken = 'auth_token';
  static const String refreshToken = 'refresh_token';
  static const String userId = 'user_id';
  static const String userRole = 'user_role';
  static const String isLoggedIn = 'is_logged_in';

  // Theme
  static const String themeMode = 'theme_mode';
  static const String isDarkMode = 'is_dark_mode';

  // Locale
  static const String locale = 'locale';

  // User Preferences
  static const String notificationEnabled = 'notification_enabled';
  static const String appointmentReminders = 'appointment_reminders';
  static const String queueUpdates = 'queue_updates';

  // Onboarding
  static const String hasSeenOnboarding = 'has_seen_onboarding';

  // Cache
  static const String lastSyncTime = 'last_sync_time';
  static const String cachedPets = 'cached_pets';
  static const String cachedAppointments = 'cached_appointments';
}
