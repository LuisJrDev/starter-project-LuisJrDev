import 'dart:typed_data';

import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import '../entities/journalist_article.dart';

abstract class JournalistArticleRepository {
  Future<DataState<List<JournalistArticleEntity>>> getArticles();

  Future<DataState<String>> uploadThumbnail({
    required String articleId,
    required Uint8List bytes,
    required String contentType,
  });

  Future<DataState<void>> createArticle(JournalistArticleEntity article);
}
