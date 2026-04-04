import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/resources/data_state.dart';
import '../../../../../auth/data/data_sources/remote/user_profile_firestore_service.dart';
import '../../../../domain/entities/journalist_article.dart';
import '../../../../domain/usecases/create_article.dart';
import '../../../../domain/usecases/new_article_id.dart';
import '../../../../domain/usecases/publish_article.dart';
import '../../../../domain/usecases/update_article.dart';
import '../../../../domain/usecases/upload_thumbnail.dart';
import 'create_article_state.dart';

class CreateArticleCubit extends Cubit<CreateArticleState> {
  final NewJournalistArticleIdUseCase _newId;
  final UploadJournalistThumbnailUseCase _uploadThumbnail;
  final CreateJournalistArticleUseCase _createArticle;
  final UpdateJournalistArticleUseCase _updateArticle;
  final PublishJournalistArticleUseCase _publishArticle;

  final FirebaseAuth _auth;
  final UserProfileFirestoreService _profile;

  CreateArticleCubit(
    this._newId,
    this._uploadThumbnail,
    this._createArticle,
    this._updateArticle,
    this._publishArticle,
    this._auth,
    this._profile,
  ) : super(const CreateArticleInitial());

  Future<(String uid, String authorName)> _getAuthor() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final fallback = user.displayName ?? user.email ?? 'Unknown';

    try {
      final data = await _profile.getUserProfile(user.uid);
      final name = (data?['name'] as String?)?.trim();
      final authorName = (name != null && name.isNotEmpty) ? name : fallback;
      return (user.uid, authorName);
    } catch (_) {
      return (user.uid, fallback);
    }
  }

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
      final (authorId, authorName) = await _getAuthor();

      final articleId = _newId();

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
        authorId: authorId,
        authorName: authorName,
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
        final pubState = await _publishArticle(params: articleId);
        if (pubState is DataFailed) {
          emit(const CreateArticleError('Publish failed'));
          return;
        }
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
    Uint8List? thumbnailBytes,
    String? thumbnailContentType,
    bool publishNow = false,
  }) async {
    emit(const CreateArticleLoading());

    try {
      final authorId = existing.authorId;
      final authorName = existing.authorName;

      var thumbnailPath = existing.thumbnailPath;

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
        status: existing.status,
        authorId: authorId,
        authorName: authorName,
        thumbnailPath: thumbnailPath,
        publishedAt: existing.publishedAt,
        category: existing.category,
        likeCount: existing.likeCount,
        commentCount: existing.commentCount,
        createdAt: existing.createdAt,
        updatedAt: DateTime.now(),
      );

      final updateState = await _updateArticle(params: updated);
      if (updateState is DataFailed) {
        emit(const CreateArticleError('Firestore update failed'));
        return;
      }

      if (publishNow) {
        final pubState = await _publishArticle(params: existing.id);
        if (pubState is DataFailed) {
          emit(const CreateArticleError('Publish failed'));
          return;
        }
      }

      emit(CreateArticleSuccess(existing.id));
    } catch (e) {
      emit(CreateArticleError(e.toString()));
    }
  }
}
