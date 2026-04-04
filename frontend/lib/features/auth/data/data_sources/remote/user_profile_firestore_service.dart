import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfileFirestoreService {
  final FirebaseFirestore _db;
  UserProfileFirestoreService(this._db);

  Future<void> createUserProfile({
    required String uid,
    required String email,
    required String name,
  }) {
    return _db.collection('users').doc(uid).set({
      'uid': uid,
      'email': email,
      'name': name,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<Map<String, dynamic>?> watchUserProfile(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((snap) => snap.data());
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final snap = await _db.collection('users').doc(uid).get();
    return snap.data();
  }
}
