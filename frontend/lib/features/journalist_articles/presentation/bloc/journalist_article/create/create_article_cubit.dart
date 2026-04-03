import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/features/journalist_articles/domain/entities/journalist_article.dart';
import 'package:news_app_clean_architecture/features/journalist_articles/domain/usecases/create_article.dart';
import 'package:news_app_clean_architecture/features/journalist_articles/domain/usecases/upload_thumbnail.dart';

import '../../../../../../core/resources/data_state.dart';
import '../../../../data/data_sources/remote/journalist_firestore_service.dart';
import '../../../../domain/usecases/update_article.dart';
import 'create_article_state.dart';

class CreateArticleCubit extends Cubit<CreateArticleState> {
  final JournalistFirestoreService _firestoreService;
  final UploadJournalistThumbnailUseCase _uploadThumbnail;
  final CreateJournalistArticleUseCase _createArticle;
  final UpdateJournalistArticleUseCase _updateArticle;

  CreateArticleCubit(
    this._firestoreService,
    this._uploadThumbnail,
    this._createArticle,
    this._updateArticle,
  ) : super(const CreateArticleInitial());

  Future<void> submit({
    required String title,
    required String content,
    required String authorName,
    required String category, // <-- NUEVO
    required Uint8List thumbnailBytes,
    required String thumbnailContentType,
    bool publishNow = false, // NEW
  }) async {
    emit(const CreateArticleLoading());

    try {
      final articleId = _firestoreService.newArticleId();

      final uploadState = await _uploadThumbnail(
        params: UploadThumbnailParams(
          articleId: articleId,
          bytes: thumbnailBytes,
          contentType: thumbnailContentType,
        ),
      );

      if (uploadState is DataFailed || uploadState.data == null) {
        emit(const CreateArticleError('Thumbnail upload failed'));
        return;
      }

      final now = DateTime.now();

      final entity = JournalistArticleEntity(
        id: articleId,
        title: title.trim(),
        content: content.trim(),
        status: 'draft',
        authorName: authorName.trim(),
        thumbnailPath: uploadState.data!,
        category: category,
        publishedAt: null,
        likeCount: 0,
        commentCount: 0,
        createdAt: now,
        updatedAt: now,
      );

      final createState = await _createArticle(params: entity);
      if (createState is DataFailed) {
        emit(const CreateArticleError('Firestore create failed'));
        return;
      }

      if (publishNow) {
        await _firestoreService.publishArticle(articleId);
      }

      emit(CreateArticleSuccess(articleId));
    } catch (e) {
      emit(CreateArticleError(e.toString()));
    }
  }

  Future<void> submitEdit({
    required JournalistArticleEntity existing,
    required String title,
    required String content,
    required String authorName,
    Uint8List? thumbnailBytes, // opcional
    String? thumbnailContentType, // opcional
    bool publishNow = false,
  }) async {
    emit(const CreateArticleLoading());

    try {
      String thumbnailPath = existing.thumbnailPath;

      // Si el user escogió thumbnail nuevo, lo subimos
      if (thumbnailBytes != null && thumbnailContentType != null) {
        final uploadState = await _uploadThumbnail(
          params: UploadThumbnailParams(
            articleId: existing.id,
            bytes: thumbnailBytes,
            contentType: thumbnailContentType,
          ),
        );

        if (uploadState is DataFailed || uploadState.data == null) {
          emit(const CreateArticleError('Thumbnail upload failed'));
          return;
        }

        thumbnailPath = uploadState.data!;
      }

      final updated = JournalistArticleEntity(
        id: existing.id,
        title: title.trim(),
        content: content.trim(),
        status: existing.status, // sigue siendo draft hasta que publiques
        authorName: authorName.trim(),
        thumbnailPath: thumbnailPath,
        publishedAt: existing.publishedAt,
        category: existing.category, // Asegúrate de incluir la categoría
        likeCount: existing.likeCount,
        commentCount: existing.commentCount,
        createdAt: existing.createdAt, // NO se toca
        updatedAt: DateTime.now(), // sí se actualiza
      );

      // Necesitas el use case de update:
      final updateState = await _updateArticle(params: updated);
      if (updateState is DataFailed) {
        emit(const CreateArticleError('Firestore update failed'));
        return;
      }

      if (publishNow) {
        await _firestoreService.publishArticle(existing.id);
      }

      emit(CreateArticleSuccess(existing.id));
    } catch (e) {
      emit(CreateArticleError(e.toString()));
    }
  }
}
