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
        thumbnailPath: article.thumbnailPath,
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
}
