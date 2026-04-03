import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/core/usecase/usecase.dart';
import '../repository/journalist_article_repository.dart';

class PublishJournalistArticleUseCase
    implements UseCase<DataState<void>, String> {
  final JournalistArticleRepository _repository;
  PublishJournalistArticleUseCase(this._repository);

  @override
  Future<DataState<void>> call({String? params}) {
    return _repository.publishArticle(params!);
  }
}
