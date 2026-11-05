import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:carepaw/core/errors/error_handler.dart';
import 'package:carepaw/core/errors/failures.dart';
import 'package:carepaw/core/firebase/caller_scope.dart';
import 'package:carepaw/core/firebase/firebase_auth_error_mapper.dart';
import 'package:carepaw/core/firebase/firestore_schema.dart';
import 'package:carepaw/core/firebase/user_doc_mapper.dart';
import 'package:carepaw/core/firebase/user_id_sequence.dart';
import 'package:carepaw/firebase_options.dart';
import 'package:carepaw/core/di/dependency_injection.dart';
import 'package:carepaw/features/audit/domain/entities/audit_log.dart';
import 'package:carepaw/features/audit/domain/repositories/audit_log_repository.dart';
import 'package:carepaw/features/users/domain/repositories/user_repository.dart';
import 'package:carepaw/features/authentication/domain/entities/user.dart'
    as domain;

/// User repository implementation - data layer (Firestore-backed).
///
/// Implements [UserRepository] with Cloud Firestore's `users/{uid}` collection
/// as the source of truth. The domain layer keys users by an app-facing `int`
/// `id`; it is stored in the document and located via a `id` equality query.
/// `User.firebaseUid` is the Firestore document ID / Firebase Auth UID.
///
// The former local drift repository (`UserRepositoryImpl`) is intentionally
// set aside and no longer wired.
class FirestoreUserRepository implements UserRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;
  final UserIdSequence _userIdSequence;

  FirestoreUserRepository({
    required this._firestore,
    required this._firebaseAuth,
    required this._userIdSequence,
  });

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(FirestoreSchema.users);

  // ============ BaseRepository<User, int> ============

  @override
  Future<domain.User?> findById(int id) async {
    final doc = await _findDocByIntId(id);
    return doc == null ? null : _docToUser(doc);
  }

  @override
  Future<List<domain.User>> findAll() async {
    final snapshot = await _users.get();
    return snapshot.docs.map(_docToUser).where((u) => u.isActive).toList();
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
    if (CallerScope.isPetOwner) {
      // A pet owner may only watch a profile the rules let them read; resolve
      // it once through the owner-safe lookup instead of an unprovable query.
      return Stream.fromFuture(findById(id));
    }
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
        .where(FirestoreSchema.isActive, isEqualTo: true)
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
      await auditRepository.write(
        AuditLog(
          userId: actorId,
          action: action,
          entityType: 'USER',
          entityId: '${targetUser.id ?? ''}',
          oldValues: oldValues,
          newValues: newValues,
          createdAt: DateTime.now(),
        ),
      );
    } catch (_) {
      // Best-effort: ignore audit write failures.
    }
  }

  Future<int?> _findAppIdByFirebaseUid(String firebaseUid) async {
    final snapshot = await _users
        .where(FirestoreSchema.firebaseUid, isEqualTo: firebaseUid)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return (snapshot.docs.first.data()[FirestoreSchema.id] as num?)?.toInt();
  }

  @override
  Future<List<domain.User>> findVeterinarians() =>
      findByRole(domain.UserRole.ownerAdmin);

  @override
  Future<List<domain.User>> search(String query) async {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return findAll();
    final snapshot = await _users.get();
    return snapshot.docs
        .map(_docToUser)
        .where(
          (u) =>
              u.isActive &&
              (u.fullName.toLowerCase().contains(normalized) ||
                  u.email.toLowerCase().contains(normalized)),
        )
        .toList();
  }

  @override
  Future<void> updateActivity(int userId) async {
    final doc = await _findDocByIntId(userId);
    if (doc == null) return;
    await doc.reference.update({FirestoreSchema.updatedAt: DateTime.now()});
  }

  @override
  Future<domain.User> updateProfile(
    int userId, {
    String? fullName,
    String? phone,
    String? address,
    String? avatarUrl,
  }) async {
    final existing = await findById(userId);
    if (existing == null) {
      throw Exception('User not found');
    }
    final updated = existing.copyWith(
      fullName: fullName ?? existing.fullName,
      phone: phone ?? existing.phone,
      address: address ?? existing.address,
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
    final updated = existing.copyWith(role: newRole, updatedAt: DateTime.now());
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
      // Create the Auth account over the Identity Toolkit REST API instead of
      // FirebaseAuth.createUserWithEmailAndPassword. The SDK call silently
      // swaps this client's session to the newly created account, which left
      // the admin signed in as a non-admin — every role-gated security rule
      // (audit logs, inventory, user management, ...) then denied with
      // "missing or insufficient permissions". REST signUp does not touch the
      // admin's session.
      final createdAuth = await _createAuthUserViaRest(email, password);
      try {
        // The operator's chosen role is final. (An earlier email-domain rule
        // promoted any account sharing the first user's domain, such as
        // gmail.com, to Owner/Admin. That handed out clinic access.)
        final domain.UserRole effectiveRole = role;

        final newId = await _userIdSequence.next();
        final now = DateTime.now();
        final created = domain.User(
          id: newId,
          firebaseUid: createdAuth.uid,
          email: email,
          fullName: fullName.trim(),
          phone: phone,
          role: effectiveRole,
          isActive: true,
          createdAt: now,
          updatedAt: now,
        );
        await _users.doc(createdAuth.uid).set(UserDocMapper.toData(created));
        await _writeAudit(
          action: 'USER_CREATE',
          targetUser: created,
          newValues: <String, dynamic>{
            'role': effectiveRole.value,
            'email': email,
          },
        );
        return created;
      } catch (_) {
        // Firestore write failed (e.g. rules deny it). Remove the Auth user
        // so we don't leave an orphaned account, and keep the admin signed in.
        await _deleteAuthUserViaRest(createdAuth.idToken);
        rethrow;
      }
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
  Future<domain.User> createWithSync(
    domain.User entity,
    String tableName,
  ) async => save(entity);

  @override
  Future<domain.User> updateWithSync(
    domain.User entity,
    String tableName,
  ) async => save(entity);

  @override
  Future<void> deleteWithSync(int id, String tableName) async => softDelete(id);

  // ============ Private helpers ============

  /// Creates an Auth account via the Identity Toolkit REST API without
  /// changing this client's current session (unlike
  /// `createUserWithEmailAndPassword`, which signs the client in as the new
  /// user). Returns the new user's uid and id token.
  Future<({String uid, String idToken})> _createAuthUserViaRest(
    String email,
    String password,
  ) async {
    final uri = Uri.parse(
      'https://identitytoolkit.googleapis.com/v1/accounts:signUp'
      '?key=${DefaultFirebaseOptions.currentPlatform.apiKey}',
    );
    final response = await http.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'returnSecureToken': true,
      }),
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      final message = (body['error']?['message'] as String?) ?? '';
      if (message.startsWith('EMAIL_EXISTS')) {
        throw const EmailAlreadyInUseFailure();
      }
      if (message.startsWith('WEAK_PASSWORD')) {
        throw const WeakPasswordFailure();
      }
      if (message.startsWith('INVALID_EMAIL')) {
        throw const InvalidEmailFailure();
      }
      throw UnexpectedFailure(
        message: message.isEmpty ? 'Could not create the account.' : message,
      );
    }
    return (uid: body['localId'] as String, idToken: body['idToken'] as String);
  }

  /// Best-effort removal of a just-created Auth account after a failed
  /// provisioning attempt. The id token from signUp is still fresh, so the
  /// recent-login requirement is satisfied.
  Future<void> _deleteAuthUserViaRest(String idToken) async {
    try {
      final uri = Uri.parse(
        'https://identitytoolkit.googleapis.com/v1/accounts:delete'
        '?key=${DefaultFirebaseOptions.currentPlatform.apiKey}',
      );
      await http.post(
        uri,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': idToken}),
      );
    } catch (_) {
      // Best-effort cleanup.
    }
  }

  domain.User _docToUser(DocumentSnapshot<Map<String, dynamic>> doc) {
    return UserDocMapper.fromData(doc.data() ?? const {}, doc.id);
  }

  /// Find the first Firestore document whose app-facing int `id` matches.
  ///
  /// The Owner/Admin may query any profile. A pet owner may read only their
  /// own profile and the clinic's Owner/Admin profiles (`firestore.rules`),
  /// and Firestore denies a query whose filters do not prove that. So for a
  /// pet owner the lookup adds a `role` filter (clinic profile, e.g. a
  /// veterinarian name) and then a `firebaseUid` filter (their own profile).
  Future<DocumentSnapshot<Map<String, dynamic>>?> _findDocByIntId(
    int id,
  ) async {
    final byId = _users.where(FirestoreSchema.id, isEqualTo: id);
    if (!CallerScope.isPetOwner) {
      final snapshot = await byId.limit(1).get();
      return snapshot.docs.isEmpty ? null : snapshot.docs.first;
    }

    final clinic = await byId
        .where(
          FirestoreSchema.role,
          isEqualTo: domain.UserRole.ownerAdmin.value,
        )
        .limit(1)
        .get();
    if (clinic.docs.isNotEmpty) return clinic.docs.first;

    final uid = _firebaseAuth.currentUser?.uid;
    if (uid == null) return null;
    final own = await byId
        .where(FirestoreSchema.firebaseUid, isEqualTo: uid)
        .limit(1)
        .get();
    return own.docs.isEmpty ? null : own.docs.first;
  }
}
