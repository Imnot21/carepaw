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

      final domainUser = await _readCurrentUserDoc();
      if (domainUser == null) {
        await _firebaseAuth.signOut();
        throw const UserNotFoundFailure(
          message: 'No profile found for this account. Please contact support.',
        );
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
      await _firestore
          .collection(FirestoreSchema.users)
          .doc(fireUser.uid)
          .set(UserDocMapper.toData(domainUser));

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