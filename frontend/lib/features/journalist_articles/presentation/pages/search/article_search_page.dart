import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../../core/device/device_id_service.dart';
import '../../../../../../injection_container.dart';
import '../../../data/data_sources/remote/journalist_firestore_service.dart';
import '../../../domain/entities/journalist_article.dart';
import '../../controllers/saved_articles_controller.dart';
import '../article_detail/article_detail_page.dart';
import '../feed/feed_reactions_store.dart';

class ArticleSearchPage extends StatefulWidget {
  final SavedArticlesController saved;
  final FeedReactionsStore reactions; // <-- NUEVO

  const ArticleSearchPage({
    super.key,
    required this.saved,
    required this.reactions,
  });
  @override
  State<ArticleSearchPage> createState() => _ArticleSearchPageState();
}

class _ArticleSearchPageState extends State<ArticleSearchPage> {
  final _controller = TextEditingController();
  String _q = '';

  late final JournalistFirestoreService _firestore;
  late final DeviceIdService _deviceIdService;
  late final String _deviceId;
  late final FeedReactionsStore _reactions;

  // Cache de downloadURL por storage path
  final Map<String, Future<String>> _urlFutures = {};

  // Para no re-primear lo mismo en cada rebuild
  List<String> _primedIds = const [];

  @override
  void initState() {
    super.initState();
    _firestore = sl<JournalistFirestoreService>();

    _deviceIdService = sl<DeviceIdService>();
    _deviceId = _deviceIdService.getOrCreate();

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {}
    _reactions = FeedReactionsStore(_firestore, _deviceId, uid!);
  }

  @override
  void dispose() {
    _reactions.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<String> _getDownloadUrlCached(String path) {
    return _urlFutures.putIfAbsent(
      path,
      () => FirebaseStorage.instance.ref(path).getDownloadURL(),
    );
  }

  bool _matches(JournalistArticleEntity a, String q) {
    if (q.trim().isEmpty) return true;
    final s = q.toLowerCase().trim();

    return a.title.toLowerCase().contains(s) ||
        a.authorName.toLowerCase().contains(s) ||
        a.content.toLowerCase().contains(s);
  }

  void _primeIfNeeded(List<JournalistArticleEntity> articles) {
    final ids = articles.map((e) => e.id).toList(growable: false);
    if (listEquals(ids, _primedIds)) return;

    _primedIds = ids;
    unawaited(widget.reactions.prime(ids));
  }

  Future<void> _openDetail(JournalistArticleEntity a) async {
    final nav = Navigator.of(context);
    final url = await _getDownloadUrlCached(a.thumbnailPath);
    if (!mounted) return;

    nav.push(
      MaterialPageRoute(
        builder: (_) => ArticleDetailPage(
          article: a,
          thumbnailUrl: url,
          saved: widget.saved,
        ),
      ),
    );
  }

  Future<void> _share(JournalistArticleEntity article) async {
    final text =
        '${article.title}\n@${article.authorName}\n\n${article.content}';
    await Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: _SearchBarPill(
            controller: _controller,
            hint: 'Buscar noticias…',
            onChanged: (v) => setState(() => _q = v),
            onClear: () {
              _controller.clear();
              setState(() => _q = '');
            },
          ),
        ),
      ),
      body: StreamBuilder<List<JournalistArticleEntity>>(
        stream: _firestore.watchPublishedArticles(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting &&
              !snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Text(
                'Error: ${snap.error}',
                style: const TextStyle(color: Colors.white70),
              ),
            );
          }

          final all = snap.data ?? const <JournalistArticleEntity>[];

          final isQueryEmpty = _q.trim().isEmpty;
          final filtered = all.where((a) => _matches(a, _q)).toList();

          // Decide qué mostrar:
          // - Query vacío => "Lo último" (top 10)
          // - Query con texto => resultados filtrados
          final results = isQueryEmpty ? filtered.take(10).toList() : filtered;

          if (results.isEmpty) {
            return const Center(
              child: Text(
                'No results',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          // Prime del liked-state solo cuando cambie el set de resultados
          _primeIfNeeded(results);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
            children: [
              Text(
                isQueryEmpty ? 'Lo último en noticias' : 'Resultados',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.95),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),

              ...results.map(
                (a) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AnimatedBuilder(
                    animation: widget.reactions,
                    builder: (context, _) {
                      // Base del contador una sola vez
                      widget.reactions.seedLikeCount(a.id, a.likeCount);

                      final isLiked = widget.reactions.isLiked(
                        a.id,
                        fallback: false,
                      );
                      final likeCount = widget.reactions.likeCount(
                        a.id,
                        fallback: a.likeCount,
                      );

                      return _SearchResultCard(
                        article: a,
                        getUrl: _getDownloadUrlCached,
                        onTap: () => _openDetail(a),
                        isLiked: isLiked,
                        likeCount: likeCount,
                        onLike: () =>
                            widget.reactions.toggleLike(articleId: a.id),
                        onShare: () => _share(a),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 6),
              Divider(color: scheme.onSurface.withValues(alpha: 0.12)),
              const SizedBox(height: 12),
            ],
          );
        },
      ),
    );
  }
}

class _SearchBarPill extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBarPill({
    required this.controller,
    required this.hint,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(Icons.search, color: scheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: scheme.onSurfaceVariant),
                border: InputBorder.none,
                isDense: true,
              ),
              onChanged: onChanged,
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              if (value.text.isEmpty) return const SizedBox(width: 8);
              return IconButton(
                tooltip: 'Clear',
                onPressed: onClear,
                icon: const Icon(Icons.close, color: Colors.white70),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final JournalistArticleEntity article;
  final Future<String> Function(String path) getUrl;
  final VoidCallback onTap;

  final bool isLiked;
  final int likeCount;
  final VoidCallback onLike;
  final VoidCallback onShare;

  const _SearchResultCard({
    required this.article,
    required this.getUrl,
    required this.onTap,
    required this.isLiked,
    required this.likeCount,
    required this.onLike,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      color: const Color(0xFF111113),
      child: InkWell(
        onTap: onTap,
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              FutureBuilder<String>(
                future: getUrl(article.thumbnailPath),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return Container(
                      color: scheme.surfaceContainerHighest.withValues(
                        alpha: 0.25,
                      ),
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  }
                  return Image.network(snap.data!, fit: BoxFit.cover);
                },
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black87],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.55, 1.0],
                  ),
                ),
              ),

              Positioned(
                left: 12,
                right: 54,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Text(
                        article.category,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      article.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      article.authorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),

              Positioned(
                right: 8,
                bottom: 10,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: onLike,
                      icon: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? Colors.redAccent : Colors.white,
                      ),
                    ),
                    Text(
                      '$likeCount',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    IconButton(
                      onPressed: onShare,
                      icon: const Icon(
                        Icons.share_outlined,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
