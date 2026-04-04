import '../repository/user_profile_repository.dart';
import 'get_current_user.dart';

class ResolveAuthorNameUseCase {
  final GetCurrentUserUseCase _currentUser;
  final UserProfileRepository _profiles;

  ResolveAuthorNameUseCase(this._currentUser, this._profiles);

  Future<(String uid, String authorName)> call() async {
    final user = _currentUser();
    if (user == null) throw Exception('Not authenticated');

    final fallback = (user.displayName?.trim().isNotEmpty ?? false)
        ? user.displayName!.trim()
        : (user.email?.trim().isNotEmpty ?? false)
        ? user.email!.trim()
        : 'Usuario';

    final name = await _profiles.getName(user.uid);
    final authorName = (name != null && name.trim().isNotEmpty)
        ? name
        : fallback;

    return (user.uid, authorName);
  }
}
