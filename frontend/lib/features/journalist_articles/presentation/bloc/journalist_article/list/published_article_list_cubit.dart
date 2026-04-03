import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/entities/journalist_article.dart';
import '../../../../domain/usecases/watch_published_articles.dart';
import 'article_list_state.dart';

class PublishedArticleListCubit extends Cubit<ArticleListState> {
  final WatchPublishedJournalistArticlesUseCase _watchPublished;

  StreamSubscription<List<JournalistArticleEntity>>? _sub;

  PublishedArticleListCubit(this._watchPublished)
    : super(const ArticleListLoading());

  void start() {
    emit(const ArticleListLoading());

    _sub?.cancel();
    _sub = _watchPublished().listen(
      (articles) {
        emit(ArticleListLoaded(articles));
      },
      onError: (_) {
        emit(const ArticleListError('Failed to load published articles'));
      },
    );
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
