import '../repository/storage_url_repository.dart';

class GetDownloadUrlUseCase {
  final StorageUrlRepository _repo;
  GetDownloadUrlUseCase(this._repo);

  Future<String> call(String path) => _repo.getDownloadUrl(path);
}
