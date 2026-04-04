// lib/features/journalist_articles/presentation/bloc/journalist_article/list/my_published_article_list_cubit.dart
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/entities/journalist_article.dart';
import '../../../../domain/usecases/watch_my_published_articles.dart';
import 'article_list_state.dart';

class MyPublishedArticleListCubit extends Cubit<ArticleListState> {
  final WatchMyPublishedJournalistArticlesUseCase _watchMyPublished;
  StreamSubscription<List<JournalistArticleEntity>>? _sub;

  MyPublishedArticleListCubit(this._watchMyPublished)
    : super(const ArticleListLoading());

  void start(String authorId) {
    emit(const ArticleListLoading());

    _sub?.cancel();
    _sub = _watchMyPublished(authorId).listen(
      (articles) => emit(ArticleListLoaded(articles)),
      onError: (_) =>
          emit(const ArticleListError('Failed to load published articles')),
    );
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
