import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:carepaw/core/errors/error_handler.dart';
import 'package:carepaw/core/errors/failures.dart';
import 'package:carepaw/core/firebase/firebase_auth_error_mapper.dart';
import 'package:carepaw/core/firebase/firestore_schema.dart';
import 'package:carepaw/core/firebase/user_doc_mapper.dart';
import 'package:carepaw/core/firebase/user_id_sequence.dart';
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
    await save(updated);
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
      await _users.doc(fireUser.uid).set(UserDocMapper.toData(created));
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
}