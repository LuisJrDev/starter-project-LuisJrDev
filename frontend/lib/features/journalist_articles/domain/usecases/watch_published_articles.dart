// lib/features/journalist_articles/domain/usecases/watch_published_articles.dart
import '../entities/journalist_article.dart';
import '../repository/journalist_article_repository.dart';

class WatchPublishedJournalistArticlesUseCase {
  final JournalistArticleRepository _repository;

  WatchPublishedJournalistArticlesUseCase(this._repository);

  Stream<List<JournalistArticleEntity>> call() {
    return _repository.watchPublishedArticles(); // GLOBAL
  }
}
