// lib/features/journalist_articles/domain/usecases/watch_my_published_articles.dart
import '../entities/journalist_article.dart';
import '../repository/journalist_article_repository.dart';

class WatchMyPublishedJournalistArticlesUseCase {
  final JournalistArticleRepository _repository;

  WatchMyPublishedJournalistArticlesUseCase(this._repository);

  Stream<List<JournalistArticleEntity>> call(String authorId) {
    return _repository.watchMyPublishedArticles(authorId);
  }
}
