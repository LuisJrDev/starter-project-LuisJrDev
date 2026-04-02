import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:news_app_clean_architecture/features/journalist_articles/domain/entities/journalist_article.dart';
import 'package:news_app_clean_architecture/features/journalist_articles/domain/usecases/create_article.dart';
import 'package:news_app_clean_architecture/features/journalist_articles/domain/usecases/upload_thumbnail.dart';

import '../../../../../../core/resources/data_state.dart';
import '../../../../data/data_sources/remote/journalist_firestore_service.dart';
import 'create_article_state.dart';

class CreateArticleCubit extends Cubit<CreateArticleState> {
  final JournalistFirestoreService _firestoreService;
  final UploadJournalistThumbnailUseCase _uploadThumbnail;
  final CreateJournalistArticleUseCase _createArticle;

  CreateArticleCubit(
    this._firestoreService,
    this._uploadThumbnail,
    this._createArticle,
  ) : super(const CreateArticleInitial());

  Future<void> submit({
    required String title,
    required String content,
    required String authorName,
    required Uint8List thumbnailBytes,
    required String thumbnailContentType,
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
        createdAt: now,
        updatedAt: now,
      );

      final createState = await _createArticle(params: entity);
      if (createState is DataFailed) {
        emit(const CreateArticleError('Firestore create failed'));
        return;
      }

      emit(CreateArticleSuccess(articleId));
    } catch (e) {
      emit(CreateArticleError(e.toString()));
    }
  }
}
