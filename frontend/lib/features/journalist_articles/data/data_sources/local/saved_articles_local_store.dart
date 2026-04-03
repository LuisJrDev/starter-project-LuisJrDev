import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SavedArticlePreview {
  final String id;
  final String title;
  final String authorName;
  final String thumbnailPath;
  final String category;
  final int? createdAtMillis;

  // NUEVO:
  final String content;

  SavedArticlePreview({
    required this.id,
    required this.title,
    required this.authorName,
    required this.thumbnailPath,
    required this.createdAtMillis,
    required this.category,
    required this.content,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'authorName': authorName,
    'thumbnailPath': thumbnailPath,
    'category': category,
    'createdAtMillis': createdAtMillis,
    'content': content,
  };

  factory SavedArticlePreview.fromJson(Map<String, dynamic> json) {
    return SavedArticlePreview(
      id: json['id'] as String,
      title: json['title'] as String,
      category: (json['category'] as String?) ?? 'General',
      authorName: json['authorName'] as String,
      thumbnailPath: json['thumbnailPath'] as String,
      createdAtMillis: json['createdAtMillis'] as int?,
      content: (json['content'] as String?) ?? '',
    );
  }
}

class SavedArticlesLocalStore {
  static const _key = 'saved_articles_v1';

  Future<List<SavedArticlePreview>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];

    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return list.map(SavedArticlePreview.fromJson).toList();
  }

  Future<bool> isSaved(String articleId) async {
    final all = await getAll();
    return all.any((e) => e.id == articleId);
  }

  Future<void> toggle(SavedArticlePreview preview) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await getAll();

    final idx = all.indexWhere((e) => e.id == preview.id);
    if (idx >= 0) {
      all.removeAt(idx);
    } else {
      // insert al inicio
      all.insert(0, preview);
    }

    await prefs.setString(
      _key,
      jsonEncode(all.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> remove(String articleId) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await getAll();
    all.removeWhere((e) => e.id == articleId);

    await prefs.setString(
      _key,
      jsonEncode(all.map((e) => e.toJson()).toList()),
    );
  }
}
