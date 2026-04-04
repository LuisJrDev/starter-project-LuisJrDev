// lib/features/journalist_articles/presentation/bloc/journalist_article/list/article_list_cubit.dart
import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/entities/journalist_article.dart';
import '../../../../domain/usecases/watch_articles.dart';
import 'article_list_state.dart';

class ArticleListCubit extends Cubit<ArticleListState> {
  final WatchJournalistArticlesUseCase _watchArticles;
  StreamSubscription<List<JournalistArticleEntity>>? _sub;

  ArticleListCubit(this._watchArticles) : super(const ArticleListLoading());

  void start(String authorId) {
    emit(const ArticleListLoading());

    _sub?.cancel();
    _sub = _watchArticles(authorId).listen(
      (articles) => emit(ArticleListLoaded(articles)),
      onError: (_) => emit(const ArticleListError('Failed to load articles')),
    );
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
