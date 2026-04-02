import 'package:equatable/equatable.dart';
import '../../../../domain/entities/journalist_article.dart';

abstract class ArticleListState extends Equatable {
  const ArticleListState();

  @override
  List<Object?> get props => [];
}

class ArticleListLoading extends ArticleListState {
  const ArticleListLoading();
}

class ArticleListLoaded extends ArticleListState {
  final List<JournalistArticleEntity> articles;
  const ArticleListLoaded(this.articles);

  @override
  List<Object?> get props => [articles];
}

class ArticleListError extends ArticleListState {
  final String message;
  const ArticleListError(this.message);

  @override
  List<Object?> get props => [message];
}
