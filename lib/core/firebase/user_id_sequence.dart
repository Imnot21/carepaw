import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore-backed sequence for the app-facing surrogate integer IDs.
///
/// The domain layer keys records by a plain `int` `id` while the source of
/// truth now lives in Firestore (where document IDs are strings). This counter
/// keeps the int IDs globally unique across the cloud without any local
/// database. Uses a Firestore transaction so concurrent account creation can
/// never hand out the same ID.
class UserIdSequence {
  UserIdSequence(this._firestore);

  final FirebaseFirestore _firestore;

  static const String _counterCollection = 'counters';
  static const String _counterDoc = 'userIds';
  static const String _valueField = 'value';

  /// Returns the next unique app-facing integer user ID.
  Future<int> next() async {
    final docRef = _firestore.collection(_counterCollection).doc(_counterDoc);
    return _firestore.runTransaction((txn) async {
      final snapshot = await txn.get(docRef);
      final raw = snapshot.exists
          ? (snapshot.data()?[_valueField] as int?)
          : null;
      final current = raw ?? 0;
      final nextValue = current + 1;
      txn.set(docRef, {_valueField: nextValue});
      return nextValue;
    });
  }

  /// Allocates the next id and writes the caller's own profile with it in
  /// one transaction.
  ///
  /// Firestore rules only accept a self-created profile whose `id` is the
  /// value this same transaction moved the counter to, so a client cannot
  /// claim another user's id (and with it their pets and records).
  /// [build] receives the new id and returns the profile document data.
  Future<int> createProfile(
    DocumentReference<Map<String, dynamic>> profileRef,
    Map<String, dynamic> Function(int id) build,
  ) {
    final counterRef =
        _firestore.collection(_counterCollection).doc(_counterDoc);
    return _firestore.runTransaction((txn) async {
      final snapshot = await txn.get(counterRef);
      final raw = snapshot.exists
          ? (snapshot.data()?[_valueField] as int?)
          : null;
      final nextValue = (raw ?? 0) + 1;
      txn.set(counterRef, {_valueField: nextValue});
      txn.set(profileRef, build(nextValue));
      return nextValue;
    });
  }
}
