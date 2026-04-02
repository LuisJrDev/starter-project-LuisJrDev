import 'package:equatable/equatable.dart';

class JournalistArticleEntity extends Equatable {
  final String id;
  final String title;
  final String content;
  final String status; // "draft" | "published"
  final String authorName;
  final String thumbnailPath; // e.g. media/articles/<id>/thumbnail.jpg
  final DateTime createdAt;
  final DateTime updatedAt;

  const JournalistArticleEntity({
    required this.id,
    required this.title,
    required this.content,
    required this.status,
    required this.authorName,
    required this.thumbnailPath,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object> get props => [
    id,
    title,
    content,
    status,
    authorName,
    thumbnailPath,
    createdAt,
    updatedAt,
  ];
}
