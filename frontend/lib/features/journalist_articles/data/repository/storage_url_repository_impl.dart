import '../../domain/repository/storage_url_repository.dart';
import '../data_sources/remote/storage_url_firebase_service.dart';

class StorageUrlRepositoryImpl implements StorageUrlRepository {
  final StorageUrlFirebaseService _service;
  StorageUrlRepositoryImpl(this._service);

  @override
  Future<String> getDownloadUrl(String storagePath) {
    return _service.getDownloadUrl(storagePath);
  }
}
