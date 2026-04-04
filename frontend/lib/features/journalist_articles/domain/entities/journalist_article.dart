import 'package:equatable/equatable.dart';

class JournalistArticleEntity extends Equatable {
  final String id;
  final String title;
  final String content;
  final String status;
  final String authorName;
  final String authorId;
  final String thumbnailPath;
  final DateTime? publishedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String category;

  final int likeCount;
  final int commentCount;

  const JournalistArticleEntity({
    required this.id,
    required this.title,
    required this.content,
    required this.status,
    required this.authorName,
    required this.authorId,
    required this.thumbnailPath,
    required this.category,
    this.publishedAt,
    required this.createdAt,
    required this.updatedAt,
    this.likeCount = 0,
    this.commentCount = 0,
  });

  JournalistArticleEntity copyWith({
    String? title,
    String? content,
    String? status,
    String? authorName,
    String? authorId,
    String? thumbnailPath,
    DateTime? publishedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? category,
    int? likeCount,
    int? commentCount,
  }) {
    return JournalistArticleEntity(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      status: status ?? this.status,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      publishedAt: publishedAt ?? this.publishedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      category: category ?? this.category,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    content,
    status,
    authorId,
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
