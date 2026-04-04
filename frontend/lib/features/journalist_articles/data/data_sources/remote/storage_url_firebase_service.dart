import 'package:firebase_storage/firebase_storage.dart';

class StorageUrlFirebaseService {
  final FirebaseStorage _storage;
  StorageUrlFirebaseService(this._storage);

  Future<String> getDownloadUrl(String path) {
    return _storage.ref(path).getDownloadURL();
  }
}
