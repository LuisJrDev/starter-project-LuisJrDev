import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/journalist_article.dart';

class JournalistArticleModel extends JournalistArticleEntity {
  const JournalistArticleModel({
    required super.id,
    required super.title,
    required super.content,
    required super.category,
    required super.status,
    required super.authorId, // <-- NUEVO
    required super.authorName,
    required super.thumbnailPath,
    required super.publishedAt,
    required super.createdAt,
    required super.updatedAt,
    super.likeCount = 0,
    super.commentCount = 0,
  });

  factory JournalistArticleModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return JournalistArticleModel(
      id: doc.id,
      title: (data['title'] as String?) ?? '',
      content: (data['content'] as String?) ?? '',
      status: (data['status'] as String?) ?? 'draft',
      authorId: (data['authorId'] as String?) ?? '', // <-- NUEVO
      authorName: (data['authorName'] as String?) ?? '',
      thumbnailPath: (data['thumbnailPath'] as String?) ?? '',
      category: (data['category'] as String?) ?? 'General',
      publishedAt: (data['publishedAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likeCount: ((data['likeCount'] as num?) ?? 0).toInt(),
      commentCount: ((data['commentCount'] as num?) ?? 0).toInt(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'content': content,
      'status': status,
      'authorId': authorId, // <-- NUEVO
      'authorName': authorName,
      'thumbnailPath': thumbnailPath,
      if (publishedAt != null) 'publishedAt': Timestamp.fromDate(publishedAt!),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'category': category,
      'likeCount': likeCount,
      'commentCount': commentCount,
    };
  }
}
