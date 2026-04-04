import '../repository/journalist_article_repository.dart';

class NewJournalistArticleIdUseCase {
  final JournalistArticleRepository _repo;
  NewJournalistArticleIdUseCase(this._repo);

  String call() => _repo.newArticleId();
}
