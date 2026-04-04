import 'package:firebase_auth/firebase_auth.dart';

class CurrentUserFirebaseService {
  final FirebaseAuth _auth;
  CurrentUserFirebaseService(this._auth);

  User? currentUser() => _auth.currentUser;
}
