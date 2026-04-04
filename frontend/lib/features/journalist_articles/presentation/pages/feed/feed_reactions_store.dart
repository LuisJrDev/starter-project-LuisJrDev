// lib/features/journalist_articles/presentation/pages/feed/feed_reactions_store.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../data/data_sources/remote/journalist_firestore_service.dart';

class FeedReactionsStore extends ChangeNotifier {
  final JournalistFirestoreService _firestore;
  final String _deviceId;
  final String _uid; // <-- NUEVO

  FeedReactionsStore(this._firestore, this._deviceId, this._uid); // <-- NUEVO

  final Map<String, bool> _liked = {};
  final Map<String, int> _likeCount = {};
  final Set<String> _loading = {};

  bool isLiked(String articleId, {bool fallback = false}) =>
      _liked[articleId] ?? fallback;

  int likeCount(String articleId, {required int fallback}) =>
      _likeCount[articleId] ?? fallback;

  bool isLoading(String articleId) => _loading.contains(articleId);

  Future<void> prime(List<String> articleIds) async {
    final toLoad = articleIds
        .where((id) => !_liked.containsKey(id) && !_loading.contains(id))
        .toList();
    if (toLoad.isEmpty) return;

    await Future.wait(
      toLoad.map((id) async {
        try {
          final liked = await _firestore.isLiked(articleId: id, uid: _uid);
          if (_loading.contains(id)) return;
          _liked[id] = liked;
        } catch (_) {}
      }),
    );

    notifyListeners();
  }

  void seedLikeCount(String articleId, int count) {
    _likeCount.putIfAbsent(articleId, () => count);
  }

  Future<void> toggleLike({required String articleId}) async {
    if (_loading.contains(articleId)) return;
    _loading.add(articleId);

    final wasLiked = _liked[articleId] ?? false;
    _liked[articleId] = !wasLiked;

    final current = _likeCount[articleId] ?? 0;
    _likeCount[articleId] = (wasLiked ? (current - 1) : (current + 1)).clamp(
      0,
      1 << 31,
    );

    notifyListeners();

    try {
      await _firestore.toggleLike(articleId: articleId, uid: _uid);
    } catch (e, st) {
      debugPrint('toggleLike failed for $articleId uid=$_uid -> $e');
      debugPrint('$st');

      _liked[articleId] = wasLiked;
      _likeCount[articleId] = current;
      notifyListeners();
    } finally {
      _loading.remove(articleId);
      notifyListeners();
    }
  }
}
