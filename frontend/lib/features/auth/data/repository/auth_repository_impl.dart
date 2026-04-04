import '../../domain/entities/app_user.dart';
import '../../domain/repository/auth_repository.dart';
import '../data_sources/remote/firebase_auth_service.dart';
import '../data_sources/remote/user_profile_firestore_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthService _service;
  final UserProfileFirestoreService _profile;

  AuthRepositoryImpl(this._service, this._profile);

  AppUser _map(user) => AppUser(uid: user.uid, email: user.email);

  @override
  Stream<AppUser?> watchAuthState() {
    return _service.authStateChanges().map((u) => u == null ? null : _map(u));
  }

  @override
  Future<AppUser> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final cred = await _service.signIn(email: email, password: password);
    final u = cred.user;
    if (u == null) throw Exception('Sign-in failed (no user)');
    return _map(u);
  }

  @override
  Future<AppUser> signUpWithEmailPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    final cred = await _service.signUp(email: email, password: password);
    final u = cred.user;
    if (u == null) throw Exception('Sign-up failed (no user)');

    await _service.updateDisplayName(name);

    await _profile.createUserProfile(
      uid: u.uid,
      email: u.email ?? email,
      name: name,
    );

    return _map(u);
  }

  @override
  Future<void> signOut() => _service.signOut();

  @override
  AppUser? currentUser() {
    final u = _service.currentUser();
    if (u == null) return null;
    return _map(u);
  }
}
