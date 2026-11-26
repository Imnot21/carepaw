import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:carepaw/core/firebase/caller_scope.dart';
import 'package:carepaw/core/firebase/firestore_schema.dart';

/// "Something changed" signals for the screens that show Firestore data.
///
/// Each stream fires once per change to the documents a screen lists, after
/// the first snapshot (the screen already loaded that one itself). Blocs
/// react by quietly running their last load again, so a booking made on one
/// phone shows on the clinic screen without a manual refresh.
///
/// Every query is scoped exactly like the repository reads: pet-owner callers
/// filter on their own id so Firestore rules can prove the listen, and the
/// clinic side listens unscoped. A listen the rules refuse simply ends; the
/// screen still works and pull-to-refresh still reloads it.
class LiveChanges {
  LiveChanges(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _col(String name) =>
      _firestore.collection(name);

  /// Bookings the caller can see: their own, or every booking for the clinic.
  Stream<void> appointments() => _signal(
    CallerScope.forOwner(
      _col(FirestoreSchema.appointments),
      ownerField: FirestoreSchema.ownerId,
    ),
  );

  /// Pets the caller can see: their own, or every pet for the clinic.
  Stream<void> pets() => _signal(
    CallerScope.forOwner(
      _col(FirestoreSchema.pets),
      ownerField: FirestoreSchema.ownerId,
    ),
  );

  /// One pet's medical records.
  Stream<void> medicalRecords(int petId) => _signal(
    CallerScope.forOwner(
      _col(FirestoreSchema.medicalRecords)
          .where(FirestoreSchema.petId, isEqualTo: petId),
      ownerField: FirestoreSchema.petOwnerId,
    ),
  );

  /// Clinic stock: items and their batches. Clinic side only.
  Stream<void> inventory() => _merge([
    _signal(_col(FirestoreSchema.inventoryItems)),
    _signal(_col(FirestoreSchema.inventoryBatches)),
  ]);

  /// The queue. Readable by every signed-in user.
  Stream<void> queue() => _signal(_col(FirestoreSchema.queueEntries));

  /// The caller's own notifications.
  Stream<void> notifications() => _signal(
    _col(FirestoreSchema.notifications)
        .where(FirestoreSchema.userId, isEqualTo: CallerScope.appId),
  );

  /// The clinic dashboard counts: bookings, queue and stock.
  Stream<void> clinicPulse() =>
      _merge([appointments(), queue(), inventory()]);

  /// Fires on every snapshot after the first. Errors (a refused listen, a
  /// dropped connection) end the stream quietly instead of reaching the UI.
  static Stream<void> _signal(Query<Map<String, dynamic>> query) {
    return query
        .snapshots()
        .skip(1)
        .map<void>((_) {})
        .handleError((Object e) => debugPrint('[live] listen ended: $e'));
  }

  static Stream<void> _merge(List<Stream<void>> streams) {
    return Stream<void>.multi((controller) {
      final subs = [
        for (final s in streams)
          s.listen(controller.add, onError: (Object _) {}),
      ];
      controller.onCancel = () async {
        for (final sub in subs) {
          await sub.cancel();
        }
      };
    });
  }
}
