import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/core/usecase/usecase.dart';
import '../entities/journalist_article.dart';
import '../repository/journalist_article_repository.dart';

class GetPublishedJournalistArticlesUseCase
    implements UseCase<DataState<List<JournalistArticleEntity>>, void> {
  final JournalistArticleRepository _repository;

  GetPublishedJournalistArticlesUseCase(this._repository);

  @override
  Future<DataState<List<JournalistArticleEntity>>> call({void params}) {
    return _repository.getPublishedArticles();
  }
}
