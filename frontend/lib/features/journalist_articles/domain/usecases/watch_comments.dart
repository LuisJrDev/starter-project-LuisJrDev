import '../repository/journalist_article_repository.dart';

class WatchCommentsUseCase {
  final JournalistArticleRepository _repo;
  WatchCommentsUseCase(this._repo);

  Stream<List<Map<String, dynamic>>> call(String articleId) {
    return _repo.watchComments(articleId);
  }
}
