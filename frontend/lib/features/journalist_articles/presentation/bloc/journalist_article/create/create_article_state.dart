import 'package:equatable/equatable.dart';

abstract class CreateArticleState extends Equatable {
  const CreateArticleState();

  @override
  List<Object?> get props => [];
}

class CreateArticleInitial extends CreateArticleState {
  const CreateArticleInitial();
}

class CreateArticleLoading extends CreateArticleState {
  const CreateArticleLoading();
}

class CreateArticleSuccess extends CreateArticleState {
  final String articleId;
  const CreateArticleSuccess(this.articleId);

  @override
  List<Object?> get props => [articleId];
}

class CreateArticleError extends CreateArticleState {
  final String message;
  const CreateArticleError(this.message);

  @override
  List<Object?> get props => [message];
}
