import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../../core/resources/data_state.dart';
import '../../domain/entities/journalist_article.dart';
import '../../domain/repository/journalist_article_repository.dart';
import '../data_sources/remote/journalist_firestore_service.dart';
import '../data_sources/remote/journalist_storage_service.dart';
import '../models/journalist_article.dart';

class JournalistArticleRepositoryImpl implements JournalistArticleRepository {
  final JournalistFirestoreService _firestoreService;
  final JournalistStorageService _storageService;

  JournalistArticleRepositoryImpl(this._firestoreService, this._storageService);

  @override
  Stream<List<JournalistArticleEntity>> watchPublishedArticles() {
    return _firestoreService.watchPublishedArticles();
  }

  @override
  Stream<List<JournalistArticleEntity>> watchArticles() {
    return _firestoreService.watchArticles();
  }

  DioException _wrapAsDioException(Object e, String path) {
    return DioException(
      error: e,
      requestOptions: RequestOptions(path: path),
      type: DioExceptionType.unknown,
    );
  }

  @override
  Stream<List<Map<String, dynamic>>> watchComments(String articleId) {
    return _firestoreService.watchComments(articleId);
  }

  @override
  Future<void> addComment({
    required String articleId,
    required String deviceId,
    required String authorName,
    required String uid,
    required String text,
  }) {
    return _firestoreService.addComment(
      articleId: articleId,
      deviceId: deviceId,
      authorName: authorName,
      uid: uid,
      text: text,
    );
  }

  @override
  Stream<List<JournalistArticleEntity>> watchMyArticles(String authorId) {
    return _firestoreService.watchMyArticles(authorId);
  }

  @override
  Stream<List<JournalistArticleEntity>> watchMyPublishedArticles(
    String authorId,
  ) {
    return _firestoreService.watchMyPublishedArticles(authorId);
  }

  @override
  Future<DataState<List<JournalistArticleEntity>>> getArticles() async {
    try {
      final models = await _firestoreService.getArticles();
      return DataSuccess(models);
    } catch (e) {
      return DataFailed(_wrapAsDioException(e, '/articles'));
    }
  }

  @override
  String newArticleId() {
    return _firestoreService.newArticleId();
  }

  @override
  Future<DataState<void>> updateArticle(JournalistArticleEntity article) async {
    try {
      final model = JournalistArticleModel(
        id: article.id,
        title: article.title,
        content: article.content,
        status: article.status,
        authorId: article.authorId,
        authorName: article.authorName,
        thumbnailPath: article.thumbnailPath,
        category: article.category,
        publishedAt: article.publishedAt,
        createdAt: article.createdAt,
        updatedAt: article.updatedAt,
      );

      await _firestoreService.updateArticle(model);
      return const DataSuccess(null);
    } catch (e) {
      return DataFailed(_wrapAsDioException(e, '/articles/update'));
    }
  }

  @override
  Future<DataState<void>> deleteArticle(
    String articleId, {
    required String thumbnailPath,
  }) async {
    try {
      await _firestoreService.deleteArticle(articleId);

      try {
        await _storageService.deleteByPath(thumbnailPath);
      } catch (_) {}

      return const DataSuccess(null);
    } catch (e) {
      return DataFailed(_wrapAsDioException(e, '/articles/delete'));
    }
  }

  @override
  Future<bool> isLiked({required String articleId, required String uid}) {
    return _firestoreService.isLiked(articleId: articleId, uid: uid);
  }

  @override
  Future<void> toggleLike({required String articleId, required String uid}) {
    return _firestoreService.toggleLike(articleId: articleId, uid: uid);
  }

  @override
  Future<DataState<String>> uploadThumbnail({
    required String articleId,
    required Uint8List bytes,
    required String contentType,
  }) async {
    try {
      final path = await _storageService.uploadThumbnail(
        articleId: articleId,
        bytes: bytes,
        contentType: contentType,
      );
      return DataSuccess(path);
    } catch (e) {
      return DataFailed(_wrapAsDioException(e, '/storage/upload'));
    }
  }

  @override
  Future<DataState<void>> createArticle(JournalistArticleEntity article) async {
    try {
      final model = JournalistArticleModel(
        id: article.id,
        title: article.title,
        content: article.content,
        status: article.status,
        authorId: article.authorId,
        authorName: article.authorName,
        thumbnailPath: article.thumbnailPath,
        category: article.category,
        publishedAt: article.publishedAt,
        createdAt: article.createdAt,
        updatedAt: article.updatedAt,
      );

      await _firestoreService.createArticle(model);
      return const DataSuccess(null);
    } catch (e) {
      return DataFailed(_wrapAsDioException(e, '/articles/create'));
    }
  }

  @override
  Future<DataState<void>> publishArticle(String articleId) async {
    try {
      await _firestoreService.publishArticle(articleId);
      return const DataSuccess(null);
    } catch (e) {
      return DataFailed(_wrapAsDioException(e, '/articles/publish'));
    }
  }

  @override
  Future<DataState<List<JournalistArticleEntity>>>
  getPublishedArticles() async {
    try {
      final models = await _firestoreService.getPublishedArticles();
      return DataSuccess(models);
    } catch (e) {
      return DataFailed(_wrapAsDioException(e, '/articles/published'));
    }
  }
}
