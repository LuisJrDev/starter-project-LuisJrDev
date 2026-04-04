import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/features/auth/data/data_sources/remote/user_profile_firestore_service.dart';
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

  final FirebaseAuth _auth;
  final UserProfileFirestoreService _profile;

  CreateArticleCubit(
    this._firestoreService,
    this._uploadThumbnail,
    this._createArticle,
    this._updateArticle,
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
        authorId: authorId, // <-- NUEVO
        authorName: authorName, // <-- automático
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
    Uint8List? thumbnailBytes,
    String? thumbnailContentType,
    bool publishNow = false,
  }) async {
    emit(const CreateArticleLoading());

    try {
      // seguridad: autor siempre el del artículo, no editable desde UI
      // (y rules también lo van a validar)
      final authorId = existing.authorId;
      final authorName = existing.authorName;

      String thumbnailPath = existing.thumbnailPath;

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
        await _firestoreService.publishArticle(existing.id);
      }

      emit(CreateArticleSuccess(existing.id));
    } catch (e) {
      emit(CreateArticleError(e.toString()));
    }
  }
}
