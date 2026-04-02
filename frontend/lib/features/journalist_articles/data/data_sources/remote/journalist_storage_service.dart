import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

class JournalistStorageService {
  final FirebaseStorage _storage;

  JournalistStorageService(this._storage);

  Future<String> uploadThumbnail({
    required String articleId,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final path = 'media/articles/$articleId/thumbnail.jpg';
    final ref = _storage.ref(path);

    await ref.putData(bytes, SettableMetadata(contentType: contentType));
    return path; // guardamos path, no URL
  }
}
