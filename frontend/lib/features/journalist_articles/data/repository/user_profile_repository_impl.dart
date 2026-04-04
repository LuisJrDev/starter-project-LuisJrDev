import '../../domain/repository/user_profile_repository.dart';
import '../data_sources/remote/user_profile_firestore_service_ja.dart';

class UserProfileRepositoryImpl implements UserProfileRepository {
  final UserProfileFirestoreServiceJA _service;
  UserProfileRepositoryImpl(this._service);

  @override
  Future<String?> getName(String uid) => _service.getName(uid);
}
