import '../entities/app_user.dart';
import '../repository/auth_repository.dart';

class SignInUseCase {
  final AuthRepository _repo;
  SignInUseCase(this._repo);

  Future<AppUser> call({required String email, required String password}) {
    return _repo.signInWithEmailPassword(email: email, password: password);
  }
}
