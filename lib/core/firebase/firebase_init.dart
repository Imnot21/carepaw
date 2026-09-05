import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import '../../firebase_options.dart' as firebase_options;

/// Firebase initialization and configuration.
///
/// Handles:
/// - Firebase Core initialization
/// - App Check configuration (debug provider for dev, Play Integrity/DeviceCheck for prod)
/// - Firestore settings (offline persistence enabled by default)
class FirebaseInit {
  FirebaseInit._();

  static bool _initialized = false;

  /// Initialize Firebase with appropriate configuration.
  ///
  /// Must be called before using any Firebase services.
  /// Safe to call multiple times.
  static Future<void> initialize() async {
    if (_initialized) return;

    // Check if Firebase is already initialized (e.g., via google-services.json on Android)
    // We need to check this BEFORE trying to initialize
    try {
      final apps = Firebase.apps;
      if (apps.isNotEmpty) {
        // Firebase already initialized, just configure App Check
        await _configureAppCheck();
        _configureFirestore();
        _initialized = true;
        return;
      }
    } catch (_) {
      // If even checking apps throws, Firebase might already be initialized
    }

    // Try to initialize Firebase Core
    try {
      await Firebase.initializeApp(
        options: firebase_options.DefaultFirebaseOptions.currentPlatform,
      );

      // Configure App Check
      await _configureAppCheck();

      // Configure Firestore settings
      _configureFirestore();

      _initialized = true;
    } catch (e) {
      // Handle case where Firebase auto-initializes during check
      // or already initialized via google-services.json
      final errorString = e.toString();
      if (errorString.contains('core/duplicate-app') || errorString.contains('duplicate-app')) {
        // Firebase already initialized by google-services.json, configure App Check anyway
        await _configureAppCheck();
        _configureFirestore();
        _initialized = true;
      } else {
        rethrow;
      }
    }
  }

  /// Configure App Check for security.
  ///
  /// - Debug: Uses debug provider (prints token to console for emulator testing)
  /// - Release Android: Play Integrity
  /// - Release iOS: DeviceCheck
  static Future<void> _configureAppCheck() async {
    if (kDebugMode) {
      // Debug provider - allows testing with Firebase Emulators
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.debug,
        appleProvider: AppleProvider.debug,
        webProvider: ReCaptchaV3Provider('debug-key'),
      );
    } else {
      // Production providers
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.playIntegrity,
        appleProvider: AppleProvider.deviceCheck,
        webProvider: ReCaptchaV3Provider('YOUR_RECAPTCHA_SITE_KEY'),
      );
    }
  }

  /// Configure Firestore settings.
  ///
  /// - Offline persistence: Enabled by default (caches data locally)
  /// - Cache size: 100MB default
  /// - SSL: Enforced
  static void _configureFirestore() {
    // Firestore settings are configured per-instance
    // Offline persistence is enabled by default in FlutterFire
    // Additional configuration can be done here if needed
  }

  /// Check if Firebase is initialized.
  static bool get isInitialized => _initialized;

  /// Reset initialization state (for testing).
  static void resetForTesting() {
    _initialized = false;
  }
}