import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/journalist_article.dart';

class JournalistArticleModel extends JournalistArticleEntity {
  const JournalistArticleModel({
    required super.id,
    required super.title,
    required super.content,
    required super.status,
    required super.authorName,
    required super.thumbnailPath,
    required super.createdAt,
    required super.updatedAt,
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
      authorName: (data['authorName'] as String?) ?? '',
      thumbnailPath: (data['thumbnailPath'] as String?) ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'content': content,
      'status': status,
      'authorName': authorName,
      'thumbnailPath': thumbnailPath,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
