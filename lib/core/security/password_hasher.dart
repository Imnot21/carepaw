import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';

/// Password hashing utility using Argon2 via PointyCastle.
///
/// Provides secure password hashing and verification.
/// Pure Dart implementation - no native dependencies.
class PasswordHasher {
  static const int _defaultTimeCost = 3;
  static const int _defaultMemoryCost = 65536; // 64 MB (in KB)
  static const int _defaultParallelism = 1;
  static const int _saltLength = 16;
  static const int _hashLength = 32;

  PasswordHasher._();

  /// Hash a plain-text password using Argon2id.
  ///
  /// Returns an Argon2 hash string in the format:
  /// $argon2id$v=19$m=65536,t=3,p=1$[base64(salt)]$[base64(hash)]
  /// The hash can be stored directly in the database.
  ///
  /// Example:
  /// ```dart
  /// final hash = PasswordHasher.hash('myPassword123');
  /// ```
  static String hash(
    String password, {
    int timeCost = _defaultTimeCost,
    int memoryCost = _defaultMemoryCost,
    int parallelism = _defaultParallelism,
  }) {
    // Generate random salt
    final random = Random.secure();
    final salt = Uint8List.fromList(
      List<int>.generate(_saltLength, (_) => random.nextInt(256)),
    );

    // Hash with Argon2id
    final argon2 = Argon2BytesGenerator();
    final params = Argon2Parameters(
      Argon2Parameters.ARGON2_id,
      salt,
      desiredKeyLength: _hashLength,
      iterations: timeCost,
      memory: memoryCost,
      lanes: parallelism,
      version: Argon2Parameters.ARGON2_VERSION_13,
    );
    argon2.init(params);

    final hashBytes = Uint8List(_hashLength);
    argon2.deriveKey(utf8.encode(password), 0, hashBytes, 0);

    // Format: $argon2id$v=19$m=65536,t=3,p=1$[base64(salt)]$[base64(hash)]
    final saltB64 = base64Encode(salt).replaceAll('=', '');
    final hashB64 = base64Encode(hashBytes).replaceAll('=', '');

    return '\$argon2id\$v=19\$m=$memoryCost,t=$timeCost,p=$parallelism\$$saltB64\$$hashB64';
  }

  /// Verify a plain-text password against an Argon2 hash.
  ///
  /// Returns `true` if the password matches the hash, `false` otherwise.
  /// Handles null or invalid hashes gracefully.
  ///
  /// Example:
  /// ```dart
  /// final isValid = PasswordHasher.verify('myPassword123', storedHash);
  /// ```
  static bool verify(String password, String hash) {
    if (hash.isEmpty || !hash.startsWith('\$argon2')) return false;

    try {
      // Parse hash: $argon2id$v=19$m=65536,t=3,p=1$[salt]$[hash]
      final parts = hash.split('\$');
      if (parts.length < 6) return false;

      // parts[0] = '', parts[1] = 'argon2id', parts[2] = 'v=19', parts[3] = 'm=65536,t=3,p=1', parts[4] = salt, parts[5] = hash
      final params = parts[3].split(',');
      int? memoryCost, timeCost, parallelism;

      for (final param in params) {
        final kv = param.split('=');
        if (kv.length == 2) {
          final value = int.tryParse(kv[1]);
          if (value != null) {
            switch (kv[0]) {
              case 'm':
                memoryCost = value;
                break;
              case 't':
                timeCost = value;
                break;
              case 'p':
                parallelism = value;
                break;
            }
          }
        }
      }

      if (memoryCost == null || timeCost == null || parallelism == null) {
        return false;
      }

      // Decode salt and expected hash
      final saltB64 = parts[4];
      final hashB64 = parts[5];

      final salt = base64Decode(_addPadding(saltB64));
      final expectedHash = base64Decode(_addPadding(hashB64));

      // Hash the provided password with the same parameters
      final argon2 = Argon2BytesGenerator();
      final params2 = Argon2Parameters(
        Argon2Parameters.ARGON2_id,
        salt,
        desiredKeyLength: _hashLength,
        iterations: timeCost,
        memory: memoryCost,
        lanes: parallelism,
        version: Argon2Parameters.ARGON2_VERSION_13,
      );
      argon2.init(params2);

      final actualHash = Uint8List(_hashLength);
      argon2.deriveKey(utf8.encode(password), 0, actualHash, 0);

      // Constant-time comparison
      return _constantTimeEquals(actualHash, expectedHash);
    } catch (_) {
      // Invalid hash format or other error
      return false;
    }
  }

  /// Check if a hash needs rehashing (e.g., parameters changed).
  ///
  /// Returns `true` if the hash was created with weaker parameters than current default.
  static bool needsRehash(
    String hash, {
    int timeCost = _defaultTimeCost,
    int memoryCost = _defaultMemoryCost,
    int parallelism = _defaultParallelism,
  }) {
    if (!hash.startsWith('\$argon2')) return true;

    try {
      final parts = hash.split('\$');
      if (parts.length < 4) return true;

      final params = parts[3].split(',');
      int? memCost, timeC, parallel;

      for (final param in params) {
        final kv = param.split('=');
        if (kv.length == 2) {
          final value = int.tryParse(kv[1]);
          if (value != null) {
            switch (kv[0]) {
              case 'm':
                memCost = value;
                break;
              case 't':
                timeC = value;
                break;
              case 'p':
                parallel = value;
                break;
            }
          }
        }
      }

      return memCost != null && memCost < memoryCost ||
          timeC != null && timeC < timeCost ||
          parallel != null && parallel < parallelism;
    } catch (_) {
      return true;
    }
  }

  /// Rehash a password if needed (e.g., after successful login with old params).
  ///
  /// Call this after verifying a password if you want to upgrade the hash.
  /// Returns the new hash if rehashing was performed, null otherwise.
  static String? maybeRehash(
    String password,
    String hash, {
    int timeCost = _defaultTimeCost,
    int memoryCost = _defaultMemoryCost,
    int parallelism = _defaultParallelism,
  }) {
    if (needsRehash(
      hash,
      timeCost: timeCost,
      memoryCost: memoryCost,
      parallelism: parallelism,
    )) {
      return PasswordHasher.hash(
        password,
        timeCost: timeCost,
        memoryCost: memoryCost,
        parallelism: parallelism,
      );
    }
    return null;
  }

  /// Add base64 padding if needed
  static String _addPadding(String str) {
    final padding = (4 - str.length % 4) % 4;
    return str + '=' * padding;
  }

  /// Constant-time comparison to prevent timing attacks
  static bool _constantTimeEquals(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }
}
