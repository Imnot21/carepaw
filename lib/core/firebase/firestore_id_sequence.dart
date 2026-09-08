import 'package:cloud_firestore/cloud_firestore.dart';

/// Generic Firestore-backed sequence for the app-facing surrogate integer IDs.
///
/// The domain layer keys records by a plain `int` `id` while the source of
/// truth now lives in Firestore (where document IDs are strings). Each entity
/// type gets its own counter document (e.g. `counters/petIds`) so IDs stay
/// unique within their type. Uses a Firestore transaction so concurrent writes
/// can never hand out the same ID.
///
/// Mirrors [UserIdSequence] ([package:carepaw/core/firebase/user_id_sequence.dart])
/// as a reusable, parameterized variant.
class FirestoreIdSequence {
  FirestoreIdSequence(this._firestore, {required this._counterCollection, required this._counterDoc});

  final FirebaseFirestore _firestore;
  final String _counterCollection;
  final String _counterDoc;

  static const String _valueField = 'value';

  /// Returns the next unique app-facing integer ID for this entity type.
  Future<int> next() async {
    final docRef = _firestore.collection(_counterCollection).doc(_counterDoc);
    return _firestore.runTransaction((txn) async {
      final snapshot = await txn.get(docRef);
      final raw = snapshot.exists ? (snapshot.data()?[_valueField] as int?) : null;
      final current = raw ?? 0;
      final nextValue = current + 1;
      txn.set(docRef, {_valueField: nextValue});
      return nextValue;
    });
  }
}