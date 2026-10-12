import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carepaw/core/storage/local_storage.dart';

/// Role-aware query scoping for Firestore reads.
///
/// Firestore security rules only authorize a list query when the query's own
/// filters prove the rule for every document it could return. Doc-id lookups
/// such as `where('id', isEqualTo: x)` prove nothing about ownership, so a
/// pet-owner query additionally filters on the record's owner id. The rules
/// can then verify `ownerId == getCurrentUserId()` against the query itself.
///
/// Clinic roles (staff, veterinarians, admins) satisfy their rules purely from
/// the auth token, so their queries are left unscoped.
class CallerScope {
  CallerScope._();

  static const String _petOwnerRole = 'PET_OWNER';

  /// Whether the signed-in caller is a pet owner (vs clinic personnel).
  static bool get isPetOwner {
    try {
      return LocalStorage.getUserRole() == _petOwnerRole;
    } catch (_) {
      // Local storage not initialized yet — treat as non-owner so repository
      // calls during startup keep their previous (unscoped) behaviour.
      return false;
    }
  }

  /// The caller's app-facing integer user id, or -1 when unavailable.
  static int get appId {
    try {
      return LocalStorage.getUserId() ?? -1;
    } catch (_) {
      return -1;
    }
  }

  /// Adds an equality filter on [ownerField] for pet-owner callers; other roles
  /// already satisfy their rules unscoped and are returned unchanged.
  static Query<Map<String, dynamic>> forOwner(
    Query<Map<String, dynamic>> query, {
    required String ownerField,
  }) {
    if (!isPetOwner) return query;
    return query.where(ownerField, isEqualTo: appId);
  }
}