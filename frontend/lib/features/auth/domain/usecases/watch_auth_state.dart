import '../entities/app_user.dart';
import '../repository/auth_repository.dart';

class WatchAuthStateUseCase {
  final AuthRepository _repo;
  WatchAuthStateUseCase(this._repo);

  Stream<AppUser?> call() => _repo.watchAuthState();
}
