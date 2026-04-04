import 'dart:typed_data';

import '../../../../core/resources/data_state.dart';
import '../entities/journalist_article.dart';

abstract class JournalistArticleRepository {
  Future<DataState<List<JournalistArticleEntity>>> getArticles();

  Future<DataState<String>> uploadThumbnail({
    required String articleId,
    required Uint8List bytes,
    required String contentType,
  });

  Stream<List<JournalistArticleEntity>> watchPublishedArticles();
  Stream<List<JournalistArticleEntity>> watchArticles();

  Stream<List<JournalistArticleEntity>> watchMyArticles(String authorId);
  Stream<List<JournalistArticleEntity>> watchMyPublishedArticles(
    String authorId,
  );

  Stream<List<Map<String, dynamic>>> watchComments(String articleId);

  Future<void> addComment({
    required String articleId,
    required String deviceId,
    required String authorName,
    required String uid,
    required String text,
  });

  Future<DataState<void>> createArticle(JournalistArticleEntity article);
  Future<DataState<void>> updateArticle(JournalistArticleEntity article);

  Future<DataState<void>> deleteArticle(
    String articleId, {
    required String thumbnailPath,
  });

  Future<bool> isLiked({required String articleId, required String uid});
  Future<void> toggleLike({required String articleId, required String uid});

  Future<DataState<void>> publishArticle(String articleId);
  Future<DataState<List<JournalistArticleEntity>>> getPublishedArticles();

  String newArticleId();
}
