import '../repository/journalist_article_repository.dart';

class IsArticleLikedUseCase {
  final JournalistArticleRepository _repo;
  IsArticleLikedUseCase(this._repo);

  Future<bool> call({required String articleId, required String uid}) {
    return _repo.isLiked(articleId: articleId, uid: uid);
  }
}
