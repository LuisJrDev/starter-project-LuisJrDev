import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/core/usecase/usecase.dart';

import '../entities/journalist_article.dart';
import '../repository/journalist_article_repository.dart';

class CreateJournalistArticleUseCase
    implements UseCase<DataState<void>, JournalistArticleEntity> {
  final JournalistArticleRepository _repository;

  CreateJournalistArticleUseCase(this._repository);

  @override
  Future<DataState<void>> call({JournalistArticleEntity? params}) {
    return _repository.createArticle(params!);
  }
}
