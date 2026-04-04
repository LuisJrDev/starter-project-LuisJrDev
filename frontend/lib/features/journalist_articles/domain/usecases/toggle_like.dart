import '../repository/journalist_article_repository.dart';

class ToggleArticleLikeUseCase {
  final JournalistArticleRepository _repo;
  ToggleArticleLikeUseCase(this._repo);

  Future<void> call({required String articleId, required String uid}) {
    return _repo.toggleLike(articleId: articleId, uid: uid);
  }
}
