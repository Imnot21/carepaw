import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../../firebase_options.dart' as firebase_options;

/// Firebase initialization and configuration.
///
/// Handles:
/// - Firebase Core initialization
/// - App Check configuration (reCAPTCHA v3 on web, Play Integrity or debug on
///   Android; off unless enabled with --dart-define)
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
      if (errorString.contains('core/duplicate-app') ||
          errorString.contains('duplicate-app')) {
        // Firebase already initialized by google-services.json, configure App Check anyway
        await _configureAppCheck();
        _configureFirestore();
        _initialized = true;
      } else {
        rethrow;
      }
    }
  }

  /// reCAPTCHA v3 site key for the web build. Pass it at build time:
  /// `--dart-define=APP_CHECK_WEB_KEY=<site key>`. Empty keeps App Check off
  /// on web (a wrong key breaks every Auth and Firestore call).
  static const String _webSiteKey = String.fromEnvironment('APP_CHECK_WEB_KEY');

  /// Android provider: `playIntegrity` (needs the app linked in Google Play
  /// Console) or `debug` (each test phone prints a debug token to logcat
  /// that must be added in Firebase console > App Check). Empty keeps it off.
  static const String _androidMode = String.fromEnvironment('APP_CHECK_ANDROID');

  /// Whether this build sends App Check tokens.
  static bool get appCheckEnabled => kIsWeb
      ? _webSiteKey.isNotEmpty
      : defaultTargetPlatform == TargetPlatform.android &&
          (_androidMode == 'playIntegrity' || _androidMode == 'debug');

  /// Configure App Check (proves requests come from the real CarePaw app).
  ///
  /// Off unless the build passes a provider through `--dart-define` (see the
  /// two constants above), so a plain `flutter run` keeps working. Keep
  /// enforcement OFF in the Firebase console until the metrics there show
  /// verified requests from every platform you ship, or that platform is
  /// locked out.
  static Future<void> _configureAppCheck() async {
    if (!appCheckEnabled) return;
    try {
      if (kIsWeb) {
        await FirebaseAppCheck.instance.activate(
          webProvider: ReCaptchaV3Provider(_webSiteKey),
        );
      } else {
        await FirebaseAppCheck.instance.activate(
          androidProvider: _androidMode == 'debug'
              ? AndroidProvider.debug
              : AndroidProvider.playIntegrity,
        );
      }
    } catch (e) {
      // While unenforced, a failed token only means "unverified" in the
      // console. Never block start-up over it.
      debugPrint('App Check activation failed: $e');
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
