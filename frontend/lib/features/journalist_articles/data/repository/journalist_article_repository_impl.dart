import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/journalist_articles/data/data_sources/remote/journalist_firestore_service.dart';
import 'package:news_app_clean_architecture/features/journalist_articles/data/data_sources/remote/journalist_storage_service.dart';
import 'package:news_app_clean_architecture/features/journalist_articles/data/models/journalist_article.dart';
import 'package:news_app_clean_architecture/features/journalist_articles/domain/entities/journalist_article.dart';
import 'package:news_app_clean_architecture/features/journalist_articles/domain/repository/journalist_article_repository.dart';

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

  @override
  Future<DataState<List<JournalistArticleEntity>>> getArticles() async {
    try {
      final models = await _firestoreService.getArticles();
      return DataSuccess(models);
    } catch (e) {
      return DataFailed(
        DioError(
          error: e,
          type: DioErrorType.other,
          requestOptions: RequestOptions(path: '/articles'),
        ),
      );
    }
  }

  @override
  Future<DataState<void>> updateArticle(JournalistArticleEntity article) async {
    try {
      final model = JournalistArticleModel(
        id: article.id,
        title: article.title,
        content: article.content,
        status: article.status,
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
      return DataFailed(
        DioError(
          error: e,
          type: DioErrorType.other,
          requestOptions: RequestOptions(path: '/articles/update'),
        ),
      );
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
        await _firestoreService.deleteByPath(thumbnailPath);
      } catch (_) {}

      return const DataSuccess(null);
    } catch (e) {
      return DataFailed(
        DioError(
          error: e,
          type: DioErrorType.other,
          requestOptions: RequestOptions(path: '/articles/delete'),
        ),
      );
    }
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
      return DataFailed(
        DioError(
          error: e,
          type: DioErrorType.other,
          requestOptions: RequestOptions(path: '/storage/upload'),
        ),
      );
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
        authorName: article.authorName,
        category: article.category,
        thumbnailPath: article.thumbnailPath,
        publishedAt: article.publishedAt,
        createdAt: article.createdAt,
        updatedAt: article.updatedAt,
      );

      await _firestoreService.createArticle(model);
      return const DataSuccess(null);
    } catch (e) {
      return DataFailed(
        DioError(
          error: e,
          type: DioErrorType.other,
          requestOptions: RequestOptions(path: '/articles/create'),
        ),
      );
    }
  }

  @override
  Future<DataState<void>> publishArticle(String articleId) async {
    try {
      await _firestoreService.publishArticle(articleId);
      return const DataSuccess(null);
    } catch (e) {
      return DataFailed(
        DioError(
          error: e,
          type: DioErrorType.other,
          requestOptions: RequestOptions(path: '/articles/publish'),
        ),
      );
    }
  }

  @override
  Future<DataState<List<JournalistArticleEntity>>>
  getPublishedArticles() async {
    try {
      final models = await _firestoreService.getPublishedArticles();
      return DataSuccess(models);
    } catch (e) {
      return DataFailed(
        DioError(
          error: e,
          type: DioErrorType.other,
          requestOptions: RequestOptions(path: '/articles/published'),
        ),
      );
    }
  }
}
