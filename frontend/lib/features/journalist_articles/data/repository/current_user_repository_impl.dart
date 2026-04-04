import '../../domain/repository/current_user_repository.dart';
import '../data_sources/remote/current_user_firebase_service.dart';

class CurrentUserRepositoryImpl implements CurrentUserRepository {
  final CurrentUserFirebaseService _service;
  CurrentUserRepositoryImpl(this._service);

  @override
  CurrentUser? currentUser() {
    final u = _service.currentUser();
    if (u == null) return null;
    return CurrentUser(uid: u.uid, email: u.email, displayName: u.displayName);
  }
}
