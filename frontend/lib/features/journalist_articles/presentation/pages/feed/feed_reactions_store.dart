// lib/features/journalist_articles/presentation/pages/feed/feed_reactions_store.dart
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../data/data_sources/remote/journalist_firestore_service.dart';

class FeedReactionsStore extends ChangeNotifier {
  final JournalistFirestoreService _firestore;
  final String _deviceId;

  FeedReactionsStore(this._firestore, this._deviceId);

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
          final liked = await _firestore.isLiked(
            articleId: id,
            deviceId: _deviceId,
          );
          // Si empezó toggle mientras esperábamos, no lo pises
          if (_loading.contains(id)) return;
          _liked[id] = liked;
        } catch (_) {}
      }),
    );

    notifyListeners();
  }

  /// Set inicial de likeCount desde el modelo (una vez por sesión/pantalla)
  void seedLikeCount(String articleId, int count) {
    _likeCount.putIfAbsent(articleId, () => count);
  }

  Future<void> toggleLike({required String articleId}) async {
    if (_loading.contains(articleId)) return;
    _loading.add(articleId);

    final wasLiked = _liked[articleId] ?? false;
    _liked[articleId] = !wasLiked;

    // optimistic count
    final current = _likeCount[articleId] ?? 0;
    _likeCount[articleId] = (wasLiked ? (current - 1) : (current + 1)).clamp(
      0,
      1 << 31,
    );

    notifyListeners();

    try {
      await _firestore.toggleLike(articleId: articleId, deviceId: _deviceId);
    } catch (e, st) {
      debugPrint('toggleLike failed for $articleId deviceId=$_deviceId -> $e');
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
