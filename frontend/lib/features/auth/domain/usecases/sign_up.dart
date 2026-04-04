import '../entities/app_user.dart';
import '../repository/auth_repository.dart';

class SignUpUseCase {
  final AuthRepository _repo;
  SignUpUseCase(this._repo);

  Future<AppUser> call({
    required String email,
    required String password,
    required String name,
  }) {
    return _repo.signUpWithEmailPassword(
      email: email,
      password: password,
      name: name,
    );
  }
}
