import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carepaw/core/firebase/firestore_schema.dart';
import 'package:carepaw/features/authentication/domain/entities/user.dart';

/// Maps between Firestore `users/{uid}` documents and the domain [User].
///
/// Field names mirror the legacy Drift table via [FirestoreSchema]. The
/// document ID is the Firebase Auth UID and is projected onto
/// `User.firebaseUid`.
class UserDocMapper {
  UserDocMapper._();

  /// Build a domain [User] from Firestore document data + its doc ID.
  static User fromData(Map<String, dynamic> data, String firebaseUid) {
    final now = DateTime.now();
    return User(
      id: data[FirestoreSchema.id] as int?,
      firebaseUid: firebaseUid,
      email: (data[FirestoreSchema.email] as String?) ?? '',
      fullName: (data[FirestoreSchema.fullName] as String?) ?? '',
      phone: data[FirestoreSchema.phone] as String?,
      role: UserRole.fromString((data[FirestoreSchema.role] as String?) ?? ''),
      avatarUrl: data[FirestoreSchema.avatarUrl] as String?,
      isActive: (data[FirestoreSchema.isActive] as bool?) ?? true,
      createdAt: _toDateTime(data[FirestoreSchema.createdAt]) ?? now,
      updatedAt: _toDateTime(data[FirestoreSchema.updatedAt]) ?? now,
    );
  }

  /// Serialize a domain [User] to a Firestore document map.
  static Map<String, dynamic> toData(User user, {bool includeId = true}) {
    return {
      if (includeId) FirestoreSchema.id: user.id,
      FirestoreSchema.firebaseUid: user.firebaseUid,
      FirestoreSchema.email: user.email,
      FirestoreSchema.fullName: user.fullName,
      FirestoreSchema.phone: user.phone,
      FirestoreSchema.role: user.role.value,
      FirestoreSchema.avatarUrl: user.avatarUrl,
      FirestoreSchema.isActive: user.isActive,
      FirestoreSchema.createdAt: user.createdAt,
      FirestoreSchema.updatedAt: user.updatedAt,
    };
  }

  static DateTime? _toDateTime(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
