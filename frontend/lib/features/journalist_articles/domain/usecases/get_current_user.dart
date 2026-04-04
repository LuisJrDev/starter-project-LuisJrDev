import '../repository/current_user_repository.dart';

class GetCurrentUserUseCase {
  final CurrentUserRepository _repo;
  GetCurrentUserUseCase(this._repo);

  CurrentUser? call() => _repo.currentUser();
}
