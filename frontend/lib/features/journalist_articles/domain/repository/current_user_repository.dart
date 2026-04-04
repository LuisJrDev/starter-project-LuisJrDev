class CurrentUser {
  final String uid;
  final String? email;
  final String? displayName;

  const CurrentUser({required this.uid, this.email, this.displayName});
}

abstract class CurrentUserRepository {
  CurrentUser? currentUser();
}
