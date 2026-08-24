import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

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

    // Initialize Firebase Core
    await Firebase.initializeApp(
      options: _getDefaultOptions(),
    );

    // Configure App Check
    await _configureAppCheck();

    // Configure Firestore settings
    _configureFirestore();

    _initialized = true;
  }

  /// Get default Firebase options.
  ///
  /// In production, these should come from `flutterfire configure` generated file.
  /// For now, we use placeholder values that will be replaced.
  static FirebaseOptions _getDefaultOptions() {
    if (kIsWeb) {
      return const FirebaseOptions(
        apiKey: 'YOUR_WEB_API_KEY',
        appId: 'YOUR_WEB_APP_ID',
        messagingSenderId: 'YOUR_SENDER_ID',
        projectId: 'YOUR_PROJECT_ID',
        authDomain: 'YOUR_PROJECT_ID.firebaseapp.com',
        storageBucket: 'YOUR_PROJECT_ID.appspot.com',
      );
    }

    // Android/iOS default - will be overridden by google-services.json / GoogleService-Info.plist
    return const FirebaseOptions(
      apiKey: 'PLACEHOLDER_API_KEY',
      appId: 'PLACEHOLDER_APP_ID',
      messagingSenderId: 'PLACEHOLDER_SENDER_ID',
      projectId: 'PLACEHOLDER_PROJECT_ID',
    );
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