import 'package:equatable/equatable.dart';

/// A published build of CarePaw that the running app can move to.
class AppRelease extends Equatable {
  /// Plain version, e.g. `1.0.8` (no leading `v`).
  final String version;

  /// What changed, as written in the release notes. May be empty.
  final String notes;

  /// Direct link to the Android installer. Null on web, where a reload is
  /// the update.
  final String? downloadUrl;

  const AppRelease({
    required this.version,
    this.notes = '',
    this.downloadUrl,
  });

  @override
  List<Object?> get props => [version, notes, downloadUrl];
}

/// Compares dotted version strings such as `1.0.8`, `v1.0.10` or `1.0.8+9`.
abstract final class AppVersion {
  /// Strips a leading `v` and any `+build` suffix.
  static String clean(String raw) {
    var v = raw.trim();
    if (v.startsWith('v') || v.startsWith('V')) v = v.substring(1);
    final plus = v.indexOf('+');
    return plus == -1 ? v : v.substring(0, plus);
  }

  /// Negative when [a] is older than [b], zero when equal, positive when newer.
  static int compare(String a, String b) {
    List<int> parts(String v) => clean(v)
        .split(RegExp(r'[.-]'))
        .map((p) => int.tryParse(p) ?? 0)
        .toList();
    final x = parts(a), y = parts(b);
    final n = x.length > y.length ? x.length : y.length;
    for (var i = 0; i < n; i++) {
      final d = (i < x.length ? x[i] : 0) - (i < y.length ? y[i] : 0);
      if (d != 0) return d;
    }
    return 0;
  }

  /// True when [candidate] is a later version than [current].
  static bool isNewer(String candidate, String current) =>
      compare(candidate, current) > 0;
}
