import 'dart:typed_data';

import '../../../../core/resources/data_state.dart';
import '../../../../core/usecase/usecase.dart';
import '../repository/journalist_article_repository.dart';

class UploadThumbnailParams {
  final String articleId;
  final Uint8List bytes;
  final String contentType;

  const UploadThumbnailParams({
    required this.articleId,
    required this.bytes,
    required this.contentType,
  });
}

class UploadJournalistThumbnailUseCase
    implements UseCase<DataState<String>, UploadThumbnailParams> {
  final JournalistArticleRepository _repository;

  UploadJournalistThumbnailUseCase(this._repository);

  @override
  Future<DataState<String>> call({UploadThumbnailParams? params}) {
    return _repository.uploadThumbnail(
      articleId: params!.articleId,
      bytes: params.bytes,
      contentType: params.contentType,
    );
  }
}
