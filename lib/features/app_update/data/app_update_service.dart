import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:ota_update/ota_update.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:carepaw/features/app_update/domain/app_release.dart';
import 'page_reload_stub.dart'
    if (dart.library.js_interop) 'page_reload_web.dart';

/// Progress of an in-app update.
class UpdateProgress {
  /// 0..1 while the installer downloads; null once it hands over to Android.
  final double? fraction;

  /// Set when the update stopped; a message the person can read.
  final String? error;

  const UpdateProgress.downloading(double this.fraction) : error = null;
  const UpdateProgress.installing() : fraction = null, error = null;
  const UpdateProgress.failed(String this.error) : fraction = null;

  bool get isInstalling => fraction == null && error == null;
}

/// Finds newer builds and installs them.
///
/// Android: reads the latest GitHub release of the public CarePaw repo and
/// installs its APK through the system installer (the person still taps
/// Install; Android never updates an app silently).
/// Web: compares the deployed `version.json` with the version this tab
/// loaded, and updates by reloading the page.
class AppUpdateService {
  AppUpdateService({http.Client? client, this.repo = defaultRepo})
    : _client = client ?? http.Client();

  static const defaultRepo = 'Imnot21/carepaw';

  final http.Client _client;
  final String repo;
  String? _webLoadedVersion;

  /// Whether this platform can update itself from inside the app.
  static bool get supported =>
      kIsWeb || defaultTargetPlatform == TargetPlatform.android;

  /// The version currently running.
  Future<String> currentVersion() async {
    if (kIsWeb) {
      // package_info on web re-reads version.json from the server, which is
      // already the *new* version after a deploy. Pin the version this tab
      // started with instead.
      return _webLoadedVersion ??= await _deployedWebVersion() ??
          (await PackageInfo.fromPlatform()).version;
    }
    return (await PackageInfo.fromPlatform()).version;
  }

  /// The newest published release, or null when it cannot be read.
  Future<AppRelease?> latest() async {
    if (kIsWeb) {
      final v = await _deployedWebVersion();
      return v == null ? null : AppRelease(version: v);
    }
    final res = await _client
        .get(
          Uri.parse('https://api.github.com/repos/$repo/releases/latest'),
          headers: const {'Accept': 'application/vnd.github+json'},
        )
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) return null;
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final assets = (json['assets'] as List? ?? const [])
        .cast<Map<String, dynamic>>();
    final apk = assets
        .map((a) => a['browser_download_url'] as String?)
        .whereType<String>()
        .where((u) => u.toLowerCase().endsWith('.apk'))
        .firstOrNull;
    return AppRelease(
      version: AppVersion.clean(json['tag_name'] as String? ?? ''),
      notes: (json['body'] as String? ?? '').trim(),
      downloadUrl: apk,
    );
  }

  /// Downloads and opens the installer (Android) or reloads (web).
  Stream<UpdateProgress> install(AppRelease release) async* {
    if (kIsWeb) {
      reloadPage();
      return;
    }
    final url = release.downloadUrl;
    if (url == null) {
      yield const UpdateProgress.failed(
        'This release has no Android installer attached.',
      );
      return;
    }
    try {
      await for (final event in OtaUpdate().execute(
        url,
        destinationFilename: 'CarePaw-v${release.version}.apk',
      )) {
        switch (event.status) {
          case OtaStatus.DOWNLOADING:
            final pct = double.tryParse(event.value ?? '') ?? 0;
            yield UpdateProgress.downloading((pct / 100).clamp(0, 1));
          case OtaStatus.INSTALLING:
          case OtaStatus.INSTALLATION_DONE:
            yield const UpdateProgress.installing();
          case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
            yield const UpdateProgress.failed(
              'Allow CarePaw to install apps, then try again.',
            );
          case OtaStatus.ALREADY_RUNNING_ERROR:
            yield const UpdateProgress.failed(
              'An update is already downloading.',
            );
          default:
            yield const UpdateProgress.failed(
              'The update could not be downloaded. Check your connection '
              'and try again.',
            );
        }
      }
    } catch (_) {
      yield const UpdateProgress.failed(
        'The update could not be downloaded. Check your connection and try '
        'again.',
      );
    }
  }

  Future<String?> _deployedWebVersion() async {
    try {
      final uri = Uri.base.resolve(
        'version.json?t=${DateTime.now().millisecondsSinceEpoch}',
      );
      final res = await _client.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      return json['version'] as String?;
    } catch (_) {
      return null;
    }
  }
}
