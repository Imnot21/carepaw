import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carepaw/core/errors/error_handler.dart';
import 'package:carepaw/core/errors/failures.dart';
import 'package:carepaw/core/firebase/firebase_auth_error_mapper.dart';
import 'package:carepaw/core/firebase/firestore_schema.dart';
import 'package:carepaw/core/firebase/user_doc_mapper.dart';
import 'package:carepaw/core/firebase/user_id_sequence.dart';
import 'package:carepaw/core/security/secure_storage.dart';
import 'package:carepaw/core/storage/local_storage.dart';
import 'package:carepaw/core/utils/validators.dart';
import 'package:carepaw/features/authentication/domain/entities/user.dart' as auth_entities;
import 'package:carepaw/features/authentication/domain/repositories/auth_repository.dart';

typedef AuthResult = auth_entities.AuthResult;
typedef DomainUser = auth_entities.User;
typedef UserRole = auth_entities.UserRole;

/// Authentication repository implementation - data layer (Firebase-backed).
///
/// Implements [AuthRepository] using:
/// - `FirebaseAuth` for real email/password authentication and session
///   persistence (tokens are managed natively by the SDK)
/// - `Cloud Firestore` `users/{uid}` documents as the source of truth for
///   profiles, roles, and activation state
/// - [UserIdSequence] for globally-unique app-facing integer IDs (the domain
///   layer still keys records by `int` `id`).
///
/// The former local drift storage and password hashing are intentionally set
/// aside: authentication now runs entirely against Firebase.
class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final UserIdSequence _userIdSequence;

  // Stream controller for auth state changes (mirrors Firebase sign-in state)
  final _authStateController = StreamController<auth_entities.AuthResult?>.broadcast();

  AuthRepositoryImpl({
    required FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
    required UserIdSequence userIdSequence,
  })  : _firebaseAuth = firebaseAuth,
        _firestore = firestore,
        _userIdSequence = userIdSequence;

  @override
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final credentials = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final fireUser = credentials.user;
      if (fireUser == null) {
        throw const InvalidCredentialsFailure();
      }

      var domainUser = await _readCurrentUserDoc();

      // Auto-provision a Firestore profile for users who exist in Auth
      // but whose Firestore doc was never created (e.g. created via
      // Firebase Console, or registration's Firestore write failed).
      if (domainUser == null) {
        domainUser = await _autoProvisionFromAuthUser(fireUser);
        if (domainUser == null) {
          await _firebaseAuth.signOut();
          throw const UserNotFoundFailure(
            message:
                'No profile found for this account. '
                'Firestore security rules may be blocking writes. '
                'Deploy firestore.rules to your Firebase project.',
          );
        }
      }
      if (!domainUser.isActive) {
        await _firebaseAuth.signOut();
        throw const AccountLockedFailure();
      }

      final authResult = _buildAuthResult(domainUser, await fireUser.getIdToken());
      await _setLocalSession(domainUser);
      _authStateController.add(authResult);
      return authResult;
    } on AuthFailure {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw mapFirebaseAuthException(e);
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
      // Validate password strength before hitting the API
      final passwordError = Validators.validatePassword(password);
      if (passwordError != null) {
        throw WeakPasswordFailure(message: passwordError);
      }

      final credentials = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('Firebase Auth user created: ${credentials.user?.uid}');
      if (credentials.user == null) {
        throw const UnexpectedFailure(message: 'Failed to create Firebase Auth user');
      }
      final fireUser = credentials.user;
      if (fireUser == null) {
        throw const UnexpectedFailure(message: 'Failed to create account.');
      }

      // Assign a globally-unique app-facing int id and persist the cloud profile.
      final newId = await _userIdSequence.next();
      final now = DateTime.now();
      final domainUser = DomainUser(
        id: newId,
        firebaseUid: fireUser.uid,
        email: email,
        fullName: fullName.trim(),
        phone: phone,
        role: role,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );
      print('Creating domain user with data: $domainUser');
      print('Firebase UID: ${fireUser.uid}');
      print('Document ID: ${fireUser.uid}');
      try {
        try {
        print('Attempting to write user document to Firestore');
        print('Document data: ${UserDocMapper.toData(domainUser)}');
        final docRef = _firestore
            .collection(FirestoreSchema.users)
            .doc(fireUser.uid);
        await docRef.set(UserDocMapper.toData(domainUser));
        print('Successfully wrote user document to Firestore');
        // Verify the document was created
        final docSnapshot = await docRef.get();
        if (!docSnapshot.exists) {
          throw const UnexpectedFailure(message: 'Failed to verify Firestore document creation');
        }
        print('Verified document exists in Firestore');
        // Verify the document data matches what we wrote
        final writtenData = docSnapshot.data();
        final expectedData = UserDocMapper.toData(domainUser);
        if (writtenData != expectedData) {
          print('Warning: Written data does not match expected data');
          print('Expected: $expectedData');
          print('Actual: $writtenData');
        }
      } catch (e) {
        print('Error writing to Firestore: $e');
        if (e is FirebaseException) {
          print('Firebase error code: ${e.code}');
          print('Firebase error message: ${e.message}');
          // Provide more specific error messages based on Firebase error codes
          if (e.code == 'permission-denied') {
            print('Permission denied: Check Firestore rules and ensure the user is properly authenticated');
          } else if (e.code == 'invalid-argument') {
            print('Invalid argument: Check the document data and structure');
          } else if (e.code == 'not-found') {
            print('Not found: The document path may be incorrect');
          }
        }
        rethrow;
      }
      } catch (_) {
        // Firestore write failed (e.g. rules deny it). Roll back the just-created
        // Auth user so we don't leave an orphaned account that can never sign in.
        // Re-authenticate before deleting to ensure we have fresh credentials.
        try {
          final cred = EmailAuthProvider.credential(
            email: email,
            password: password,
          );
          await fireUser.reauthenticateWithCredential(cred);
          await fireUser.delete();
        } catch (_) {
          // Best-effort cleanup; if this also fails the orphan is handled by
          // the auto-provision path on next login.
        }
        rethrow;
      }

      final authResult = _buildAuthResult(domainUser, await fireUser.getIdToken());
      await _setLocalSession(domainUser);
      _authStateController.add(authResult);
      return authResult;
    } on AuthFailure {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw mapFirebaseAuthException(e);
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  @override
  Future<void> logout() async {
    await _firebaseAuth.signOut();
    await _clearLocalSession();
    _authStateController.add(null);
  }

  @override
  Future<AuthResult?> getCurrentUser() async {
    try {
      // Firebase Auth persists the session natively; this returns synchronously
      // from the locally restored state before any network round-trip.
      final current = _firebaseAuth.currentUser;
      if (current == null) {
        return null;
      }

      final domainUser = await _readCurrentUserDoc();
      if (domainUser == null || !domainUser.isActive) {
        // Session exists but the profile is missing or disabled -> sign out.
        await _firebaseAuth.signOut();
        await _clearLocalSession();
        return null;
      }

      final authResult = _buildAuthResult(domainUser, await current.getIdToken());
      await _setLocalSession(domainUser);
      _authStateController.add(authResult);
      return authResult;
    } catch (e) {
      // Never throw from session restore - return null instead.
      return null;
    }
  }

  @override
  Future<AuthResult> refreshToken() async {
    try {
      final current = _firebaseAuth.currentUser;
      if (current == null) {
        throw const SessionExpiredFailure();
      }

      // Force a fresh ID token; Firebase also auto-refreshes in the background.
      await current.reload();
      final domainUser = await _readCurrentUserDoc();
      if (domainUser == null || !domainUser.isActive) {
        throw const SessionExpiredFailure();
      }

      final authResult = _buildAuthResult(domainUser, await current.getIdToken(true));
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
      final current = _firebaseAuth.currentUser;
      if (current == null) {
        throw const SessionExpiredFailure();
      }

      // Validate new password before applying
      final passwordError = Validators.validatePassword(newPassword);
      if (passwordError != null) {
        throw WeakPasswordFailure(message: passwordError);
      }

      // Re-authenticate with the current password, then update.
      final email = current.email ?? '';
      await current.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: email, password: currentPassword),
      );
      await current.updatePassword(newPassword);
    } on AuthFailure {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw mapFirebaseAuthException(e);
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  @override
  Future<void> forgotPassword(String email) async {
    // Firebase sends the reset email. It does not reveal whether the email is
    // registered, so we surface only real errors (e.g. network).
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw mapFirebaseAuthException(e);
    }
  }

  @override
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    final passwordError = Validators.validatePassword(newPassword);
    if (passwordError != null) {
      throw WeakPasswordFailure(message: passwordError);
    }

    try {
      // `token` is the Firebase password-reset oobCode from the email link.
      await _firebaseAuth.confirmPasswordReset(code: token, newPassword: newPassword);
    } on FirebaseAuthException catch (e) {
      throw mapFirebaseAuthException(e);
    }
  }

  @override
  Stream<AuthResult?> get authStateStream => _authStateController.stream;

  // ============ Private helpers ============

  /// Read the current user's Firestore profile as a domain [DomainUser].
  Future<DomainUser?> _readCurrentUserDoc() async {
    final current = _firebaseAuth.currentUser;
    if (current == null) {
      return null;
    }
    final snapshot = await _firestore
        .collection(FirestoreSchema.users)
        .doc(current.uid)
        .get();
    if (!snapshot.exists) {
      return null;
    }
    return UserDocMapper.fromData(snapshot.data()!, current.uid);
  }

  /// Create a Firestore profile for an Auth user who has none.
  ///
  /// Used on first sign-in for accounts provisioned outside the app (Firebase
  /// Console, seed scripts) or left orphaned when a registration's Firestore
  /// write was blocked. Assigns [UserRole.admin] if this user should be
  /// considered an administrator based on email domain matching with the first
  /// user in the system, otherwise defaults to [UserRole.petOwner]. Returns
  /// `null` if the profile cannot be written (e.g. Firestore rules still deny
  /// it), so the caller can fail with an actionable message.
  Future<DomainUser?> _autoProvisionFromAuthUser(User fireUser) async {
    try {
      // Check if this is the first user in the system
      final bool isFirstUser = await _isFirstUser();

      UserRole effectiveRole;
      if (isFirstUser) {
        // First user gets ADMIN role
        effectiveRole = UserRole.admin;
      } else {
        // Not first user - check if email domain matches the first user's domain
        final bool shouldBeAdmin = await _shouldBeAdminBasedOnEmailDomain(fireUser.email ?? '');
        effectiveRole = shouldBeAdmin ? UserRole.admin : UserRole.petOwner;
      }

      final newId = await _userIdSequence.next();
      final now = DateTime.now();
      final domainUser = DomainUser(
        id: newId,
        firebaseUid: fireUser.uid,
        email: fireUser.email ?? '',
        fullName: fireUser.displayName?.trim().isNotEmpty == true
            ? fireUser.displayName!
            : (fireUser.email?.split('@').first ?? 'User'),
        role: effectiveRole,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );
      await _firestore
          .collection(FirestoreSchema.users)
          .doc(fireUser.uid)
          .set(UserDocMapper.toData(domainUser));
      return domainUser;
    } catch (_) {
      // Firestore write blocked (rules) or counter unavailable.
      return null;
    }
  }

  /// Check if this is the first user being created in the system.
  /// Returns true if no users exist yet in the Firestore users collection.
  Future<bool> _isFirstUser() async {
    final snapshot = await _firestore.collection(FirestoreSchema.users).limit(1).get();
    return snapshot.docs.isEmpty;
  }

  /// Check if a user should be an admin based on email domain matching
  /// with the first user in the system. Returns true if:
  /// 1. There is at least one user in the system (the first user)
  /// 2. The first user has an email address
  /// 3. The provided email has the same domain as the first user's email
  Future<bool> _shouldBeAdminBasedOnEmailDomain(String email) async {
    if (email.isEmpty || !email.contains('@')) {
      return false;
    }

    // Get the first user (by lowest ID, assuming they were created first)
    final firstUserSnapshot = await _firestore
        .collection(FirestoreSchema.users)
        .orderBy(FirestoreSchema.id, descending: false)
        .limit(1)
        .get();

    if (firstUserSnapshot.docs.isEmpty) {
      // No users found - should not happen if !isFirstUser, but handle gracefully
      return false;
    }

    final firstUserData = firstUserSnapshot.docs.first.data();
    final firstUserEmail = firstUserData[FirestoreSchema.email] as String?;

    if (firstUserEmail == null || firstUserEmail.isEmpty || !firstUserEmail.contains('@')) {
      // First user has no valid email
      return false;
    }

    // Extract domains
    final firstUserDomain = firstUserEmail.split('@').last.toLowerCase();
    final userDomain = email.split('@').last.toLowerCase();

    return firstUserDomain == userDomain;
  }

  AuthResult _buildAuthResult(DomainUser user, String? accessToken) {
    return AuthResult(
      user: user,
      // The Firebase SDK returns a null token only in a race with sign-out;
      // treat it as empty rather than failing the whole session.
      accessToken: accessToken ?? '',
      // The Firebase UID serves as the stable refresh identifier; the Firebase
      // SDK renews tokens automatically.
      refreshToken: user.firebaseUid ?? '',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
    );
  }

  Future<void> _setLocalSession(DomainUser user) async {
    if (user.id == null) return;
    await LocalStorage.setUserId(user.id!);
    await LocalStorage.setUserRole(user.role.value);
    await LocalStorage.setLoggedIn(true);
  }

  Future<void> _clearLocalSession() async {
    await LocalStorage.clearAuthData();
    await SecureStorage.clearAuthData();
  }

  /// Dispose resources (called on app shutdown, if ever needed).
  void dispose() {
    _authStateController.close();
  }
}