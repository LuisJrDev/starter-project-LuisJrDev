import '../../../../core/resources/data_state.dart';
import '../entities/journalist_article.dart';
import '../repository/journalist_article_repository.dart';

class UpdateJournalistArticleUseCase {
  final JournalistArticleRepository _repository;

  UpdateJournalistArticleUseCase(this._repository);

  Future<DataState<void>> call({required JournalistArticleEntity params}) {
    return _repository.updateArticle(params);
  }
}
