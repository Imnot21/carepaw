import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:carepaw/core/errors/error_handler.dart';
import 'package:carepaw/core/errors/failures.dart';
import 'package:carepaw/core/firebase/firebase_auth_error_mapper.dart';
import 'package:carepaw/core/firebase/firestore_schema.dart';
import 'package:carepaw/core/firebase/user_doc_mapper.dart';
import 'package:carepaw/core/firebase/user_id_sequence.dart';
import 'package:carepaw/core/di/dependency_injection.dart';
import 'package:carepaw/features/audit/domain/entities/audit_log.dart';
import 'package:carepaw/features/audit/domain/repositories/audit_log_repository.dart';
import 'package:carepaw/features/users/domain/repositories/user_repository.dart';
import 'package:carepaw/features/authentication/domain/entities/user.dart' as domain;

/// User repository implementation - data layer (Firestore-backed).
///
/// Implements [UserRepository] with Cloud Firestore's `users/{uid}` collection
/// as the source of truth. The domain layer keys users by an app-facing `int`
/// `id`; it is stored in the document and located via a `id` equality query.
/// `User.firebaseUid` is the Firestore document ID / Firebase Auth UID.
///
/// The former local drift repository (`UserRepositoryImpl`) is intentionally
/// set aside and no longer wired.
class FirestoreUserRepository implements UserRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;
  final UserIdSequence _userIdSequence;

  FirestoreUserRepository({
    required FirebaseFirestore firestore,
    required FirebaseAuth firebaseAuth,
    required UserIdSequence userIdSequence,
  })  : _firestore = firestore,
        _firebaseAuth = firebaseAuth,
        _userIdSequence = userIdSequence;

  CollectionReference<Map<String, dynamic>> get _users => _firestore
      .collection(FirestoreSchema.users);

  // ============ BaseRepository<User, int> ============

  @override
  Future<domain.User?> findById(int id) async {
    final snapshot = await _users.where(FirestoreSchema.id, isEqualTo: id).limit(1).get();
    if (snapshot.docs.isEmpty) {
      return null;
    }
    return _docToUser(snapshot.docs.first);
  }

  @override
  Future<List<domain.User>> findAll() async {
    final snapshot = await _users.get();
    return snapshot.docs
        .map(_docToUser)
        .where((u) => u.isActive)
        .toList();
  }

  @override
  Future<domain.User> save(domain.User entity) async {
    if (entity.firebaseUid == null || entity.firebaseUid!.isEmpty) {
      throw StateError('Cannot save a user without a firebaseUid.');
    }
    var toWrite = entity;
    if (toWrite.id == null) {
      // Assign a globally-unique app-facing int id via the cloud counter.
      toWrite = toWrite.copyWith(id: await _userIdSequence.next());
    }
    await _users.doc(toWrite.firebaseUid!).set(UserDocMapper.toData(toWrite));
    return toWrite;
  }

  @override
  Future<void> delete(int id) => softDelete(id);

  @override
  Future<bool> exists(int id) async => await findById(id) != null;

  // ============ SoftDeleteRepository<User, int> ============

  @override
  Future<void> softDelete(int id) async {
    final doc = await _findDocByIntId(id);
    if (doc == null) return;
    await doc.reference.update({
      FirestoreSchema.isActive: false,
      FirestoreSchema.updatedAt: DateTime.now(),
    });
  }

  @override
  Future<void> restore(int id) async {
    final doc = await _findDocByIntId(id);
    if (doc == null) return;
    await doc.reference.update({
      FirestoreSchema.isActive: true,
      FirestoreSchema.updatedAt: DateTime.now(),
    });
  }

  @override
  Future<List<domain.User>> findAllIncludingDeleted() async {
    final snapshot = await _users.get();
    return snapshot.docs.map(_docToUser).toList();
  }

  // ============ StreamRepository<User, int> ============

  @override
  Stream<domain.User?> watchById(int id) {
    return _users
        .where(FirestoreSchema.id, isEqualTo: id)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return _docToUser(snapshot.docs.first);
    });
  }

  @override
  Stream<List<domain.User>> watchAll() {
    return _users
        .where(FirestoreSchema.isActive, isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_docToUser).toList());
  }

  // ============ UserRepository ============

  @override
  Future<domain.User?> findByEmail(String email) async {
    final snapshot = await _users
        .where(FirestoreSchema.email, isEqualTo: email)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return _docToUser(snapshot.docs.first);
  }

  @override
  Future<List<domain.User>> findByRole(domain.UserRole role) async {
    final snapshot = await _users
        .where(FirestoreSchema.role, isEqualTo: role.value)
        .get();
    return snapshot.docs.map(_docToUser).toList();
  }

  /// Append an audit log entry for a sensitive user operation (best-effort).
  ///
  /// A failure here must never fail the originating user operation, so the
  /// write is swallowed and the method returns normally. This satisfies the
  /// "Always log sensitive operations - audit trail required" constraint
  /// without coupling account/role/activation success to the audit audit store.
  Future<void> _writeAudit({
    required String action,
    required domain.User targetUser,
    Map<String, dynamic>? oldValues,
    Map<String, dynamic>? newValues,
  }) async {
    try {
      // Actor is the currently signed-in admin (the one performing the op).
      final actorUid = _firebaseAuth.currentUser?.uid;
      var actorId = 0;
      if (actorUid != null) {
        actorId = await _findAppIdByFirebaseUid(actorUid) ?? 0;
      }
      if (actorId == 0) return;

      final auditRepository = getIt<AuditLogRepository>();
      await auditRepository.write(AuditLog(
        userId: actorId,
        action: action,
        entityType: 'USER',
        entityId: '${targetUser.id ?? ''}',
        oldValues: oldValues,
        newValues: newValues,
        createdAt: DateTime.now(),
      ));
    } catch (_) {
      // Best-effort: ignore audit write failures.
    }
  }

  Future<int?> _findAppIdByFirebaseUid(String firebaseUid) async {
    final snapshot = await _users.where(FirestoreSchema.firebaseUid, isEqualTo: firebaseUid).limit(1).get();
    if (snapshot.docs.isEmpty) return null;
    return (snapshot.docs.first.data()[FirestoreSchema.id] as num?)?.toInt();
  }

  @override
  Future<List<domain.User>> findVeterinarians() => findByRole(domain.UserRole.veterinarian);

  @override
  Future<List<domain.User>> search(String query) async {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return findAll();
    final snapshot = await _users.get();
    return snapshot.docs
        .map(_docToUser)
        .where((u) =>
            u.isActive &&
            (u.fullName.toLowerCase().contains(normalized) ||
                u.email.toLowerCase().contains(normalized)))
        .toList();
  }

  @override
  Future<void> updateActivity(int userId) async {
    final doc = await _findDocByIntId(userId);
    if (doc == null) return;
    await doc.reference.update({FirestoreSchema.updatedAt: DateTime.now()});
  }

  @override
  Future<domain.User> updateProfile(int userId, {
    String? fullName,
    String? phone,
    String? avatarUrl,
  }) async {
    final existing = await findById(userId);
    if (existing == null) {
      throw Exception('User not found');
    }
    final updated = existing.copyWith(
      fullName: fullName ?? existing.fullName,
      phone: phone ?? existing.phone,
      avatarUrl: avatarUrl ?? existing.avatarUrl,
      updatedAt: DateTime.now(),
    );
    await save(updated);
    return updated;
  }

  @override
  Future<domain.User> changeRole(int userId, domain.UserRole newRole) async {
    final existing = await findById(userId);
    if (existing == null) {
      throw Exception('User not found');
    }
    final updated = existing.copyWith(
      role: newRole,
      updatedAt: DateTime.now(),
    );
    final oldValues = <String, dynamic>{'role': existing.role.value};
    final newValues = <String, dynamic>{'role': newRole.value};
    await save(updated);
    await _writeAudit(
      action: 'USER_ROLE_CHANGE',
      targetUser: updated,
      oldValues: oldValues,
      newValues: newValues,
    );
    return updated;
  }

  @override
  Future<domain.User> setActive(int userId, bool isActive) async {
    final existing = await findById(userId);
    if (existing == null) {
      throw Exception('User not found');
    }
    final updated = existing.copyWith(
      isActive: isActive,
      updatedAt: DateTime.now(),
    );
    await save(updated);
    await _writeAudit(
      action: 'USER_ACTIVE_TOGGLE',
      targetUser: updated,
      oldValues: <String, dynamic>{'isActive': existing.isActive},
      newValues: <String, dynamic>{'isActive': isActive},
    );
    return updated;
  }

  @override
  Future<void> deleteUser(int userId) async {
    final existing = await findById(userId);
    if (existing == null) {
      throw Exception('User not found');
    }
    final uid = existing.firebaseUid;
    if (uid == null || uid.isEmpty) {
      throw Exception('User has no Firebase UID and cannot be deleted.');
    }

    // The client SDK cannot revoke another user's Auth credential, so the
    // actual deletion (Auth revocation + Firestore doc removal + audit) is
    // performed by the backend `deleteUser` Cloud Function under the Admin SDK.
    final idToken = await _firebaseAuth.currentUser?.getIdToken();
    if (idToken == null) {
      throw const UnauthorizedFailure(
        message: 'Sign in to delete this user.',
      );
    }

    // Post the raw HTTPS callable protocol. This is deliberately a plain
    // HTTP POST rather than the FlutterFire `httpsCallable` client: the
    // pinned `firebase_functions` package is the Dart *authoring* SDK, which
    // exposes no runtime callable API, and pinning an extra wrapper here would
    // add a redundant web-affecting dependency just for one call.
    final projectId = _firestore.app.options.projectId;
    final uri = Uri.parse(
      'https://deleteuser-$projectId.uc.r.appspot.com/deleteUser',
    );
    final http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: <String, String>{
              HttpHeaders.contentTypeHeader: 'application/json',
              HttpHeaders.authorizationHeader: 'Bearer $idToken',
            },
            body: jsonEncode(<String, Object>{'uid': uid}),
          )
          .timeout(const Duration(seconds: 30));
    } on SocketException {
      throw const NoConnectionFailure(
        message: 'Could not reach the server. Check your connection and try again.',
      );
    } on TimeoutException {
      throw const TimeoutFailure();
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _mapDeleteUserHttpError(response.statusCode);
    }
  }

  @override
  Future<int> countByRole(domain.UserRole role) async {
    final snapshot = await _users
        .where(FirestoreSchema.role, isEqualTo: role.value)
        .get();
    return snapshot.docs.length;
  }

  @override
  Future<int> getActiveCount() async {
    final snapshot = await _users
        .where(FirestoreSchema.isActive, isEqualTo: true)
        .get();
    return snapshot.docs.length;
  }

  @override
  Future<domain.User> createAccount({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    required domain.UserRole role,
  }) async {
    try {
      final credentials = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final fireUser = credentials.user;
      if (fireUser == null) {
        throw const UnexpectedFailure(message: 'Failed to create account.');
      }

      final newId = await _userIdSequence.next();
      final now = DateTime.now();
      final created = domain.User(
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
      try {
        await _users.doc(fireUser.uid).set(UserDocMapper.toData(created));
      } catch (_) {
        // Firestore write failed (e.g. rules deny it). Roll back the Auth user
        // so we don't leave an orphaned account, and keep the admin signed in.
        try {
          await fireUser.delete();
        } catch (_) {}
        rethrow;
      }
      await _writeAudit(
        action: 'USER_CREATE',
        targetUser: created,
        newValues: <String, dynamic>{'role': role.value, 'email': email},
      );
      return created;
    } on Failure {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw mapFirebaseAuthException(e);
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  // ============ Sync-aware operations (Firestore is the store) ============

  @override
  Future<domain.User> createWithSync(domain.User entity, String tableName) async =>
      save(entity);

  @override
  Future<domain.User> updateWithSync(domain.User entity, String tableName) async =>
      save(entity);

  @override
  Future<void> deleteWithSync(int id, String tableName) async => softDelete(id);

  // ============ Private helpers ============

  domain.User _docToUser(DocumentSnapshot<Map<String, dynamic>> doc) {
    return UserDocMapper.fromData(doc.data() ?? const {}, doc.id);
  }

  /// Find the first Firestore document whose app-facing int `id` matches.
  Future<DocumentSnapshot<Map<String, dynamic>>?> _findDocByIntId(int id) async {
    final snapshot = await _users.where(FirestoreSchema.id, isEqualTo: id).limit(1).get();
    if (snapshot.docs.isEmpty) return null;
    return snapshot.docs.first;
  }

  /// Map a non-2xx `deleteUser` HTTP status to a user-friendly [Failure].
  ///
  /// The Cloud Function reports each failure mode with a distinct status
  /// code (mirroring its own guard checks), so we surface the right message
  /// without leaking server internals.
  Failure _mapDeleteUserHttpError(int status) {
    switch (status) {
      case HttpStatus.unauthorized:
        return const UnauthorizedFailure(
          message: 'Your session has expired. Please log in again.',
        );
      case HttpStatus.forbidden:
        return const UnauthorizedFailure(
          message: 'Only administrators can delete accounts.',
        );
      case HttpStatus.notFound:
        return const NotFoundFailure(message: 'User not found.');
      case HttpStatus.conflict:
        return const UnexpectedFailure(
          message: 'Cannot delete this account. It may be your own account '
              'or the last administrator.',
        );
      default:
        return ServerFailure(message: 'Server error. Please try again later.');
    }
  }
}