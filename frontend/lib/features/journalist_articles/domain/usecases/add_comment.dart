import '../repository/journalist_article_repository.dart';

class AddCommentParams {
  final String articleId;
  final String deviceId;
  final String authorName;
  final String uid;
  final String text;

  const AddCommentParams({
    required this.articleId,
    required this.deviceId,
    required this.authorName,
    required this.uid,
    required this.text,
  });
}

class AddCommentUseCase {
  final JournalistArticleRepository _repo;
  AddCommentUseCase(this._repo);

  Future<void> call({required AddCommentParams params}) {
    return _repo.addComment(
      articleId: params.articleId,
      deviceId: params.deviceId,
      authorName: params.authorName,
      uid: params.uid,
      text: params.text,
    );
  }
}
