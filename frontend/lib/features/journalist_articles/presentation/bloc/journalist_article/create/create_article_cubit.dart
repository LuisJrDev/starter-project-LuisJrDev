import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/resources/data_state.dart';
import '../../../../domain/entities/journalist_article.dart';
import '../../../../domain/usecases/create_article.dart';
import '../../../../domain/usecases/new_article_id.dart';
import '../../../../domain/usecases/publish_article.dart';
import '../../../../domain/usecases/resolve_author_name.dart';
import '../../../../domain/usecases/update_article.dart';
import '../../../../domain/usecases/upload_thumbnail.dart';
import 'create_article_state.dart';

class CreateArticleCubit extends Cubit<CreateArticleState> {
  final NewJournalistArticleIdUseCase _newId;
  final UploadJournalistThumbnailUseCase _uploadThumbnail;
  final CreateJournalistArticleUseCase _createArticle;
  final UpdateJournalistArticleUseCase _updateArticle;
  final PublishJournalistArticleUseCase _publishArticle;
  final ResolveAuthorNameUseCase _resolveAuthorName;

  CreateArticleCubit(
    this._newId,
    this._uploadThumbnail,
    this._createArticle,
    this._updateArticle,
    this._publishArticle,
    this._resolveAuthorName,
  ) : super(const CreateArticleInitial());

  Future<void> submit({
    required String title,
    required String content,
    required String category,
    required Uint8List thumbnailBytes,
    required String thumbnailContentType,
    bool publishNow = false,
  }) async {
    emit(const CreateArticleLoading());

    try {
      final (authorId, authorName) = await _resolveAuthorName();

      final articleId = _newId();

      final thumbnailPath = await _uploadThumbnailOrThrow(
        articleId: articleId,
        bytes: thumbnailBytes,
        contentType: thumbnailContentType,
      );

      final now = DateTime.now();

      final entity = JournalistArticleEntity(
        id: articleId,
        title: title.trim(),
        content: content.trim(),
        status: 'draft',
        authorId: authorId,
        authorName: authorName,
        thumbnailPath: thumbnailPath,
        category: category,
        publishedAt: null,
        likeCount: 0,
        commentCount: 0,
        createdAt: now,
        updatedAt: now,
      );

      await _createArticleOrThrow(entity);

      if (publishNow) {
        await _publishArticleOrThrow(articleId);
      }

      emit(CreateArticleSuccess(articleId));
    } catch (e) {
      emit(CreateArticleError(_toMessage(e)));
    }
  }

  Future<void> submitEdit({
    required JournalistArticleEntity existing,
    required String title,
    required String content,
    Uint8List? thumbnailBytes,
    String? thumbnailContentType,
    bool publishNow = false,
  }) async {
    emit(const CreateArticleLoading());

    try {
      final nextThumbnailPath = await _maybeUploadNewThumbnail(
        articleId: existing.id,
        existingThumbnailPath: existing.thumbnailPath,
        bytes: thumbnailBytes,
        contentType: thumbnailContentType,
      );

      final updated = existing.copyWith(
        title: title.trim(),
        content: content.trim(),
        thumbnailPath: nextThumbnailPath,
        updatedAt: DateTime.now(),
      );

      await _updateArticleOrThrow(updated);

      if (publishNow) {
        await _publishArticleOrThrow(existing.id);
      }

      emit(CreateArticleSuccess(existing.id));
    } catch (e) {
      emit(CreateArticleError(_toMessage(e)));
    }
  }

  // -------------------------
  // Helpers (small + SRP)
  // -------------------------

  Future<String> _uploadThumbnailOrThrow({
    required String articleId,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final res = await _uploadThumbnail(
      params: UploadThumbnailParams(
        articleId: articleId,
        bytes: bytes,
        contentType: contentType,
      ),
    );

    if (res is DataFailed || res.data == null) {
      throw Exception('Thumbnail upload failed');
    }

    return res.data!;
  }

  Future<String> _maybeUploadNewThumbnail({
    required String articleId,
    required String existingThumbnailPath,
    required Uint8List? bytes,
    required String? contentType,
  }) async {
    final shouldUpload = bytes != null && contentType != null;
    if (!shouldUpload) return existingThumbnailPath;

    return _uploadThumbnailOrThrow(
      articleId: articleId,
      bytes: bytes,
      contentType: contentType,
    );
  }

  Future<void> _createArticleOrThrow(JournalistArticleEntity entity) async {
    final res = await _createArticle(params: entity);
    if (res is DataFailed) throw Exception('Firestore create failed');
  }

  Future<void> _updateArticleOrThrow(JournalistArticleEntity entity) async {
    final res = await _updateArticle(params: entity);
    if (res is DataFailed) throw Exception('Firestore update failed');
  }

  Future<void> _publishArticleOrThrow(String articleId) async {
    final res = await _publishArticle(params: articleId);
    if (res is DataFailed) throw Exception('Publish failed');
  }

  String _toMessage(Object e) {
    final s = e.toString();
    // Mantén mensajes cortos y consistentes para UI
    if (s.contains('Thumbnail upload failed')) return 'Thumbnail upload failed';
    if (s.contains('Firestore create failed')) return 'Firestore create failed';
    if (s.contains('Firestore update failed')) return 'Firestore update failed';
    if (s.contains('Publish failed')) return 'Publish failed';
    return s;
  }
}
