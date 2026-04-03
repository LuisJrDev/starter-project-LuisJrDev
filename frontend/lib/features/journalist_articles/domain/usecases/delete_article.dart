import '../../../../core/resources/data_state.dart';
import '../repository/journalist_article_repository.dart';

class DeleteArticleParams {
  final String articleId;
  final String thumbnailPath;

  const DeleteArticleParams({
    required this.articleId,
    required this.thumbnailPath,
  });
}

class DeleteJournalistArticleUseCase {
  final JournalistArticleRepository _repo;
  DeleteJournalistArticleUseCase(this._repo);

  Future<DataState<void>> call({required DeleteArticleParams params}) {
    return _repo.deleteArticle(
      params.articleId,
      thumbnailPath: params.thumbnailPath,
    );
  }
}
