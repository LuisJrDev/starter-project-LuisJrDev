import 'package:bloc/bloc.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/journalist_articles/domain/usecases/get_articles.dart';

import 'article_list_state.dart';

class ArticleListCubit extends Cubit<ArticleListState> {
  final GetJournalistArticlesUseCase _getArticles;

  ArticleListCubit(this._getArticles) : super(const ArticleListLoading());

  Future<void> load() async {
    emit(const ArticleListLoading());

    final state = await _getArticles();
    if (state is DataSuccess && state.data != null) {
      emit(ArticleListLoaded(state.data!));
      return;
    }

    emit(const ArticleListError('Failed to load articles'));
  }
}
