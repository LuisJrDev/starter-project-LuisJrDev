import '../entities/app_user.dart';

abstract class AuthRepository {
  Stream<AppUser?> watchAuthState();

  Future<AppUser> signUpWithEmailPassword({
    required String email,
    required String password,
    required String name,
  });

  Future<AppUser> signInWithEmailPassword({
    required String email,
    required String password,
  });

  Future<void> signOut();

  AppUser? currentUser();
}
