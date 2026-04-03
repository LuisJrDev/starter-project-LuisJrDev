import 'package:flutter/foundation.dart';

import '../../data/data_sources/local/saved_articles_local_store.dart';

class SavedArticlesController extends ChangeNotifier {
  final SavedArticlesLocalStore _store;

  SavedArticlesController(this._store);

  List<SavedArticlePreview> _items = [];
  bool _loaded = false;

  List<SavedArticlePreview> get items => _items;
  bool get loaded => _loaded;

  Future<void> load() async {
    _items = await _store.getAll();
    _loaded = true;
    notifyListeners();
  }

  bool isSavedSync(String articleId) {
    return _items.any((e) => e.id == articleId);
  }

  Future<void> toggle(SavedArticlePreview preview) async {
    await _store.toggle(preview);
    await load();
  }

  Future<void> remove(String articleId) async {
    await _store.remove(articleId);
    await load();
  }
}
