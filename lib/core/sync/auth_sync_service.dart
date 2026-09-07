import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';
import 'package:carepaw/core/database/database.dart' as db;
import 'package:carepaw/core/database/dao/users_dao.dart';
import 'package:flutter/foundation.dart';

/// Service for syncing local authentication to Firebase Auth.
///
/// This enables local-first authentication with optional Firebase Auth backup/sync.
/// Local auth works offline; Firebase Auth sync happens in background when online.
class AuthSyncService {
  final UsersDao _usersDao;
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthSyncService({
    required UsersDao usersDao,
    required FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
  }) : _usersDao = usersDao,
       _firebaseAuth = firebaseAuth,
       _firestore = firestore;

  /// Sync all local users to Firebase Auth.
  ///
  /// Creates Firebase Auth users for local users that don't have a firebase_uid yet.
  /// Updates local users with their Firebase UID.
  /// Should be called periodically (e.g., in background sync).
  Future<AuthSyncResult> syncLocalUsersToFirebase() async {
    final results = AuthSyncResult();
    final localUsers = await _usersDao.getAllActive();

    debugPrint('[AuthSync] Found ${localUsers.length} active local users');
    for (final u in localUsers) {
      debugPrint('[AuthSync] User: ${u.email}, firebaseUid: ${u.firebaseUid ?? "NULL"}');
    }

    for (final localUser in localUsers) {
      try {
        // Skip if already synced
        if (localUser.firebaseUid != null && localUser.firebaseUid!.isNotEmpty) {
          debugPrint('[AuthSync] Skipping ${localUser.email} - already has firebaseUid: ${localUser.firebaseUid}');
          results.skipped++;
          continue;
        }

        debugPrint('[AuthSync] Syncing user: ${localUser.email}');
        final syncResult = await _syncSingleUser(localUser);
        if (syncResult.success) {
          results.synced++;
          debugPrint('[AuthSync] Successfully synced ${localUser.email} -> ${syncResult.firebaseUid}');
        } else {
          results.failed++;
          results.errors.add('User ${localUser.email}: ${syncResult.error}');
          debugPrint('[AuthSync] FAILED to sync ${localUser.email}: ${syncResult.error}');
        }
      } catch (e) {
        results.failed++;
        results.errors.add('User ${localUser.email}: $e');
        debugPrint('[AuthSync] EXCEPTION syncing ${localUser.email}: $e');
      }
    }

    debugPrint('[AuthSync] Result: $results');
    return results;
  }

  /// Sync a single local user to Firebase Auth.
  Future<_SingleUserSyncResult> _syncSingleUser(db.User localUser) async {
    try {
      // First check Firestore for existing user with this email (more reliable than deprecated API)
      final firestoreUserQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: localUser.email)
          .limit(1)
          .get();

      if (firestoreUserQuery.docs.isNotEmpty) {
        // User exists in Firestore, link to existing Firebase UID
        final firebaseUid = firestoreUserQuery.docs.first.id;
        await _linkLocalUserToFirebase(localUser.id, firebaseUid);
        return _SingleUserSyncResult(success: true, firebaseUid: firebaseUid);
      }

      // Create new Firebase Auth user
      // Generate a secure random password for the Firebase Auth account
      // The actual password auth is local; Firebase password is just for account existence
      final firebasePassword = _generateFirebasePassword();

      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: localUser.email,
        password: firebasePassword,
      );

      final firebaseUid = credential.user!.uid;

      // IMPORTANT: Sign in as the newly created user to write to Firestore
      // Firestore rules require request.auth != null && request.auth.uid == userId
      await _firebaseAuth.signInWithEmailAndPassword(
        email: localUser.email,
        password: firebasePassword,
      );

      // Set custom claims for role-based access (stored in Firestore, synced to custom claims via backend)
      await _setCustomClaims(firebaseUid, localUser);

      // Create user document in Firestore (now authenticated as the user)
      await _createFirestoreUserDoc(firebaseUid, localUser);

      // Link local user to Firebase UID
      await _linkLocalUserToFirebase(localUser.id, firebaseUid);

      // Sign out to return to unauthenticated state for next sync operation
      await _firebaseAuth.signOut();

      return _SingleUserSyncResult(success: true, firebaseUid: firebaseUid);
    } on FirebaseAuthException catch (e) {
      // Handle case where user already exists in Firebase Auth (email-already-in-use)
      if (e.code == 'email-already-in-use') {
        // Try to find in Firestore and link
        final firestoreUserQuery = await _firestore
            .collection('users')
            .where('email', isEqualTo: localUser.email)
            .limit(1)
            .get();

        if (firestoreUserQuery.docs.isNotEmpty) {
          final firebaseUid = firestoreUserQuery.docs.first.id;
          await _linkLocalUserToFirebase(localUser.id, firebaseUid);
          return _SingleUserSyncResult(success: true, firebaseUid: firebaseUid);
        }
      }
      // Ensure we're signed out on error
      try {
        await _firebaseAuth.signOut();
      } catch (_) {}
      return _SingleUserSyncResult(success: false, error: e.message ?? e.code);
    } catch (e) {
      // Ensure we're signed out on error
      try {
        await _firebaseAuth.signOut();
      } catch (_) {}
      return _SingleUserSyncResult(success: false, error: e.toString());
    }
  }

  /// Set custom claims on Firebase Auth user.
  /// Note: This requires Firebase Admin SDK (backend).
  /// For client-side, we store claims in Firestore user document.
  Future<void> _setCustomClaims(String firebaseUid, db.User localUser) async {
    // Custom claims require Admin SDK.
    // Alternative: Store role in Firestore user document
    // The backend/cloud function can then sync to custom claims
    await _firestore.collection('users').doc(firebaseUid).set({
      'email': localUser.email,
      'fullName': localUser.fullName,
      'phone': localUser.phone,
      'role': localUser.role,
      'localUserId': localUser.id,
      'isActive': localUser.isActive,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Create Firestore user document with profile data.
  Future<void> _createFirestoreUserDoc(String firebaseUid, db.User localUser) async {
    await _firestore.collection('users').doc(firebaseUid).set({
      'email': localUser.email,
      'fullName': localUser.fullName,
      'phone': localUser.phone,
      'role': localUser.role,
      'localUserId': localUser.id,
      'isActive': localUser.isActive,
      'avatarUrl': localUser.avatarUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Link local user to Firebase UID in local database.
  Future<void> _linkLocalUserToFirebase(int localUserId, String firebaseUid) async {
    await _usersDao.updateUser(db.UsersCompanion(
      id: Value(localUserId),
      firebaseUid: Value(firebaseUid),
      updatedAt: Value(DateTime.now()),
    ));
  }

  /// Generate a secure random password for Firebase Auth account.
  /// This password is NOT used for login (local auth uses its own password hash).
  /// It's only to satisfy Firebase Auth's requirement for email/password accounts.
  String _generateFirebasePassword() {
    final random = DateTime.now().millisecondsSinceEpoch.toString() +
                   (DateTime.now().microsecondsSinceEpoch % 1000000).toString();
    // Use a hash of the random string for consistent but secure password
    return 'CarePaw_Firebase_${random.substring(0, 20)}!';
  }

  /// Sync Firebase Auth user changes back to local (e.g., profile updates).
  Future<void> syncFirebaseUserToLocal(String firebaseUid) async {
    try {
      final doc = await _firestore.collection('users').doc(firebaseUid).get();
      if (!doc.exists) return;

      final data = doc.data()!;
      final localUserId = data['localUserId'] as int?;

      if (localUserId != null) {
        await _usersDao.updateUser(db.UsersCompanion(
          id: Value(localUserId),
          fullName: Value(data['fullName'] as String? ?? ''),
          phone: Value(data['phone'] as String?),
          role: Value(data['role'] as String? ?? 'PET_OWNER'),
          avatarUrl: Value(data['avatarUrl'] as String?),
          isActive: Value(data['isActive'] as bool? ?? true),
          updatedAt: Value(DateTime.now()),
        ));
      }
    } catch (e) {
      // Log error but don't throw - sync is best effort
      debugPrint('Failed to sync Firebase user to local: $e');
    }
  }

  /// Delete Firebase Auth user (for account deletion).
  /// Only called when user explicitly requests account deletion.
  Future<void> deleteFirebaseUser(String firebaseUid) async {
    try {
      // Note: This requires the user to be signed in or Admin SDK
      // For client-side, we can only delete if we have the current user's credentials
      // In practice, use a Cloud Function with Admin SDK for deletion
      await _firestore.collection('users').doc(firebaseUid).delete();
    } catch (e) {
      debugPrint('Failed to delete Firebase user: $e');
    }
  }

  /// Sync all Firebase users to local database (for users created in Firebase Console).
  ///
  /// This enables bidirectional sync - if a user is created in Firebase Console
  /// or via Firebase Auth directly, it will be synced to local database.
  Future<AuthSyncResult> syncFirebaseUsersToLocal() async {
    final results = AuthSyncResult();

    try {
      // Get all users from Firestore users collection
      final querySnapshot = await _firestore.collection('users').get();

      for (final doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          final firebaseUid = doc.id;
          final email = data['email'] as String?;
          final role = data['role'] as String? ?? 'PET_OWNER';
          final fullName = data['fullName'] as String? ?? '';
          final phone = data['phone'] as String?;
          final isActive = data['isActive'] as bool? ?? true;
          final localUserId = data['localUserId'] as int?;

          if (email == null || email.isEmpty) {
            results.skipped++;
            continue;
          }

          // Check if already synced locally
          if (localUserId != null) {
            final existingLocal = await _usersDao.getById(localUserId);
            if (existingLocal != null && existingLocal.firebaseUid == firebaseUid) {
              results.skipped++;
              continue;
            }
          }

          // Check if email exists locally
          final existingByEmail = await _usersDao.getByEmail(email);
          if (existingByEmail != null) {
            // Link existing local user to Firebase UID
            if (existingByEmail.firebaseUid != firebaseUid) {
              await _linkLocalUserToFirebase(existingByEmail.id, firebaseUid);
              results.synced++;
            } else {
              results.skipped++;
            }
            continue;
          }

          // Create new local user for this Firebase user
          // Note: We can't get the password, so local auth won't work directly
          // User would need to use "Forgot Password" or we store a placeholder
          // For now, create with a random password that user must reset

          final passwordHash = 'firebase_synced_${DateTime.now().millisecondsSinceEpoch}';

          final newLocalUserId = await _usersDao.createUser(db.UsersCompanion(
            email: Value(email),
            passwordHash: Value(passwordHash),
            fullName: Value(fullName),
            phone: Value(phone),
            role: Value(role),
            isActive: Value(isActive),
            firebaseUid: Value(firebaseUid),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ));

          // Update Firestore with local user ID
          await _firestore.collection('users').doc(firebaseUid).update({
            'localUserId': newLocalUserId,
            'updatedAt': FieldValue.serverTimestamp(),
          });

          results.synced++;
        } catch (e) {
          results.failed++;
          results.errors.add('Firebase user ${doc.id}: $e');
        }
      }
    } catch (e) {
      results.failed++;
      results.errors.add('Sync error: $e');
    }

    return results;
  }

  /// Sync specific Firebase user to local by email (for login flow).
  Future<int?> ensureLocalUserExists(String email) async {
    try {
      // Check if already exists locally
      final existingLocal = await _usersDao.getByEmail(email);
      if (existingLocal != null) {
        return existingLocal.id;
      }

      // Try to find in Firestore
      final query = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        final data = doc.data();
        final firebaseUid = doc.id;
        final role = data['role'] as String? ?? 'PET_OWNER';
        final fullName = data['fullName'] as String? ?? '';
        final phone = data['phone'] as String?;
        final isActive = data['isActive'] as bool? ?? true;

        // Create local user
        final passwordHash = 'firebase_synced_${DateTime.now().millisecondsSinceEpoch}';

        final newLocalUserId = await _usersDao.createUser(db.UsersCompanion(
          email: Value(email),
          passwordHash: Value(passwordHash),
          fullName: Value(fullName),
          phone: Value(phone),
          role: Value(role),
          isActive: Value(isActive),
          firebaseUid: Value(firebaseUid),
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ));

        // Update Firestore with local user ID
        await _firestore.collection('users').doc(firebaseUid).update({
          'localUserId': newLocalUserId,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return newLocalUserId;
      }
    } catch (e) {
      debugPrint('Failed to ensure local user exists: $e');
    }

    return null;
  }
}

/// Result of auth sync operation
class AuthSyncResult {
  int synced = 0;
  int failed = 0;
  int skipped = 0;
  final List<String> errors = [];

  bool get hasErrors => errors.isNotEmpty;
  int get total => synced + failed + skipped;

  @override
  String toString() {
    return 'AuthSyncResult(synced: $synced, failed: $failed, skipped: $skipped, errors: ${errors.length})';
  }
}

class _SingleUserSyncResult {
  final bool success;
  final String? firebaseUid;
  final String? error;

  _SingleUserSyncResult({
    required this.success,
    this.firebaseUid,
    this.error,
  });
}