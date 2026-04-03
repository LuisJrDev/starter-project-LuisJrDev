// lib/features/journalist_articles/domain/usecases/watch_articles.dart
import '../entities/journalist_article.dart';
import '../repository/journalist_article_repository.dart';

class WatchJournalistArticlesUseCase {
  final JournalistArticleRepository _repository;

  WatchJournalistArticlesUseCase(this._repository);

  Stream<List<JournalistArticleEntity>> call() => _repository.watchArticles();
}
