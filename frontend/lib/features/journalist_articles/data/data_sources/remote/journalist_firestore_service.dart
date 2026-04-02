import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/journalist_article.dart';

class JournalistFirestoreService {
  final FirebaseFirestore _firestore;

  JournalistFirestoreService(this._firestore);

  CollectionReference<Map<String, dynamic>> get _articles =>
      _firestore.collection('articles');

  Future<List<JournalistArticleModel>> getArticles() async {
    final snapshot = await _articles
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => JournalistArticleModel.fromFirestore(doc))
        .toList();
  }

  Future<void> createArticle(JournalistArticleModel model) async {
    await _articles.doc(model.id).set(model.toFirestore());
  }

  String newArticleId() {
    return _articles.doc().id;
  }
}
