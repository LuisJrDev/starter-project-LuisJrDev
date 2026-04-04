import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfileFirestoreServiceJA {
  final FirebaseFirestore _db;
  UserProfileFirestoreServiceJA(this._db);

  Future<String?> getName(String uid) async {
    final snap = await _db.collection('users').doc(uid).get();
    final data = snap.data();
    final name = (data?['name'] as String?)?.trim();
    if (name == null || name.isEmpty) return null;
    return name;
  }
}
