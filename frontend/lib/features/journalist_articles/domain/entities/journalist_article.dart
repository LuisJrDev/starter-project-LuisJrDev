import 'package:equatable/equatable.dart';

class JournalistArticleEntity extends Equatable {
  final String id;
  final String title;
  final String content;
  final String status; // "draft" | "published"
  final String authorName;
  final String thumbnailPath;
  final DateTime? publishedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String category;

  // NEW
  final int likeCount;
  final int commentCount;

  const JournalistArticleEntity({
    required this.id,
    required this.title,
    required this.content,
    required this.status,
    required this.authorName,
    required this.thumbnailPath,
    required this.category,
    this.publishedAt,
    required this.createdAt,
    required this.updatedAt,
    this.likeCount = 0,
    this.commentCount = 0,
  });

  @override
  List<Object?> get props => [
    id,
    title,
    content,
    status,
    authorName,
    thumbnailPath,
    publishedAt,
    category,
    createdAt,
    updatedAt,
    likeCount,
    commentCount,
  ];
}
