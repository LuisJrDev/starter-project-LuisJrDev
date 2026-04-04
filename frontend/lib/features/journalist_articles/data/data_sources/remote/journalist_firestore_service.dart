import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/entities/journalist_article.dart';
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

  Future<void> updateArticle(JournalistArticleModel model) async {
    await _articles.doc(model.id).update(model.toFirestore());
  }

  Future<void> publishArticle(String articleId) async {
    final now = Timestamp.fromDate(DateTime.now());
    await _articles.doc(articleId).update({
      'status': 'published',
      'publishedAt': now,
      'updatedAt': now,
    });
  }

  Future<List<JournalistArticleModel>> getPublishedArticles() async {
    final snapshot = await _articles
        .where('status', isEqualTo: 'published')
        .orderBy('publishedAt', descending: true)
        .get();

    return snapshot.docs
        .map((d) => JournalistArticleModel.fromFirestore(d))
        .toList();
  }

  String newArticleId() {
    return _articles.doc().id;
  }

  Future<void> deleteArticle(String articleId) async {
    await _articles.doc(articleId).delete();
  }

  DocumentReference<Map<String, dynamic>> _articleDoc(String articleId) =>
      _articles.doc(articleId);

  DocumentReference<Map<String, dynamic>> _reactionDoc({
    required String articleId,
    required String uid,
  }) => _articleDoc(articleId).collection('reactions').doc(uid);

  CollectionReference<Map<String, dynamic>> _commentsCol(String articleId) =>
      _articleDoc(articleId).collection('comments');

  Future<bool> isLiked({required String articleId, required String uid}) async {
    final doc = await _reactionDoc(articleId: articleId, uid: uid).get();
    return doc.exists;
  }

  Stream<List<JournalistArticleModel>> watchArticles() {
    return _articles
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => JournalistArticleModel.fromFirestore(doc))
              .toList(),
        );
  }

  Stream<List<JournalistArticleModel>> watchPublishedArticles() {
    return _articles
        .where('status', isEqualTo: 'published')
        .orderBy('publishedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => JournalistArticleModel.fromFirestore(doc))
              .toList(),
        );
  }

  Future<void> toggleLike({
    required String articleId,
    required String uid,
  }) async {
    final articleRef = _articleDoc(articleId);
    final reactionRef = _reactionDoc(articleId: articleId, uid: uid);

    await _firestore.runTransaction((tx) async {
      final reactionSnap = await tx.get(reactionRef);

      if (reactionSnap.exists) {
        tx.delete(reactionRef);
        tx.update(articleRef, {
          'likeCount': FieldValue.increment(-1),
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      } else {
        tx.set(reactionRef, {
          'uid': uid,
          'type': 'like',
          'createdAt': Timestamp.fromDate(DateTime.now()),
        });
        tx.update(articleRef, {
          'likeCount': FieldValue.increment(1),
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      }
    });
  }

  Future<void> addComment({
    required String articleId,
    required String deviceId,
    required String authorName,
    required String uid,
    required String text,
  }) async {
    final articleRef = _articleDoc(articleId);
    final commentRef = _commentsCol(articleId).doc();

    final now = Timestamp.fromDate(DateTime.now());

    await _firestore.runTransaction((tx) async {
      tx.set(commentRef, {
        'uid': uid,
        'deviceId': deviceId,
        'authorName': authorName,
        'text': text,
        'createdAt': now,
      });

      tx.update(articleRef, {
        'commentCount': FieldValue.increment(1),
        'updatedAt': now,
      });
    });
  }

  Stream<List<Map<String, dynamic>>> watchComments(String articleId) {
    return _commentsCol(articleId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  Stream<List<JournalistArticleEntity>> watchMyArticles(String authorId) {
    return _articles
        .where('authorId', isEqualTo: authorId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map(JournalistArticleModel.fromFirestore).toList(),
        );
  }

  Stream<List<JournalistArticleEntity>> watchMyPublishedArticles(
    String authorId,
  ) {
    return _articles
        .where('authorId', isEqualTo: authorId)
        .where('status', isEqualTo: 'published')
        .orderBy('publishedAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map(JournalistArticleModel.fromFirestore).toList(),
        );
  }
}
