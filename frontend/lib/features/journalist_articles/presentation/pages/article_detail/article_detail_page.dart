import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../../core/resources/data_state.dart';
import '../../../../../core/utils/time_ago.dart';
import '../../../../../injection_container.dart';
import '../../../data/data_sources/local/saved_articles_local_store.dart';
import '../../../domain/entities/journalist_article.dart';
import '../../../domain/usecases/delete_article.dart';
import '../../controllers/saved_articles_controller.dart';
import 'reader_settings.dart';

import 'package:flutter_markdown/flutter_markdown.dart';

class ArticleDetailPage extends StatefulWidget {
  final JournalistArticleEntity article;
  final String thumbnailUrl;
  final SavedArticlesController saved;

  const ArticleDetailPage({
    super.key,
    required this.article,
    required this.thumbnailUrl,
    required this.saved,
  });

  @override
  State<ArticleDetailPage> createState() => _ArticleDetailPageState();
}

class _ArticleDetailPageState extends State<ArticleDetailPage> {
  final _scroll = ScrollController();
  double _progress = 0;

  ReaderSettings _settings = const ReaderSettings(
    fontScale: 1.0,
    preset: ReaderThemePreset.dark,
  );

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final max = _scroll.position.maxScrollExtent;
    final p = max <= 0 ? 0.0 : (_scroll.offset / max).clamp(0.0, 1.0);
    setState(() => _progress = p);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  int _readingMinutes(String text) {
    final words = text.trim().isEmpty
        ? 0
        : text.trim().split(RegExp(r'\s+')).length;
    // 200 wpm aprox.
    return math.max(1, (words / 200).ceil());
  }

  (Color bg, Color fg, Color muted) _palette(BuildContext context) {
    switch (_settings.preset) {
      case ReaderThemePreset.dark:
        return (const Color(0xFF0B0B0C), Colors.white, Colors.white70);
      case ReaderThemePreset.gray:
        return (
          const Color(0xFF111113),
          const Color(0xFFEDEDED),
          const Color(0xFFBDBDBD),
        );
      case ReaderThemePreset.sepia:
        return (
          const Color(0xFF1B1611),
          const Color(0xFFF3E9D8),
          const Color(0xFFD2C3AB),
        );
    }
  }

  SavedArticlePreview _preview() {
    final created = widget.article.createdAt;
    return SavedArticlePreview(
      id: widget.article.id,
      title: widget.article.title,
      authorName: widget.article.authorName,
      thumbnailPath: widget.article.thumbnailPath,
      createdAtMillis: created.millisecondsSinceEpoch,
      content: widget.article.content,
      category: widget.article.category,
    );
  }

  @override
  Widget build(BuildContext context) {
    final created = widget.article.publishedAt ?? widget.article.createdAt;
    final createdLabel = timeAgo(created);
    final minutes = _readingMinutes(widget.article.content);
    final (bg, fg, muted) = _palette(context);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final canDelete = uid != null && uid == widget.article.authorId;

    return Theme(
      // Tema local para modo lectura
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: bg,
        colorScheme: Theme.of(
          context,
        ).colorScheme.copyWith(surface: bg, onSurface: fg),
      ),
      child: Scaffold(
        body: Stack(
          children: [
            CustomScrollView(
              controller: _scroll,
              slivers: [
                SliverAppBar(
                  pinned: true,
                  expandedHeight: 260,
                  backgroundColor: bg,
                  foregroundColor: fg,
                  actions: [
                    IconButton(
                      tooltip: 'Reader settings',
                      icon: const Icon(Icons.tune),
                      onPressed: () async {
                        final next = await showReaderSettingsSheet(
                          context,
                          current: _settings,
                        );
                        if (next != null && mounted) {
                          setState(() => _settings = next);
                        }
                      },
                    ),
                    AnimatedBuilder(
                      animation: widget.saved,
                      builder: (context, _) {
                        final savedNow = widget.saved.isSavedSync(
                          widget.article.id,
                        );

                        return IconButton(
                          tooltip: savedNow
                              ? 'Remove bookmark'
                              : 'Save to read later',
                          icon: Icon(
                            savedNow ? Icons.bookmark : Icons.bookmark_border,
                          ),
                          onPressed: () async {
                            await widget.saved.toggle(_preview());

                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  savedNow
                                      ? 'Removed from Saved'
                                      : 'Saved for later',
                                ),
                                duration: const Duration(milliseconds: 900),
                              ),
                            );
                          },
                        );
                      },
                    ),
                    if (canDelete)
                      IconButton(
                        tooltip: 'Delete',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete article?'),
                              content: const Text(
                                'This action cannot be undone.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );

                          if (ok != true || !context.mounted) return;

                          final useCase = sl<DeleteJournalistArticleUseCase>();
                          final res = await useCase(
                            params: DeleteArticleParams(
                              articleId: widget.article.id,
                              thumbnailPath: widget.article.thumbnailPath,
                            ),
                          );

                          if (!context.mounted) return;

                          if (res is DataSuccess) {
                            Navigator.of(context).pop('deleted');
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Article deleted')),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Failed to delete')),
                            );
                          }
                        },
                      ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(widget.thumbnailUrl, fit: BoxFit.cover),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.transparent, Colors.black87],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
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
                            widget.article.category,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.article.title,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: fg,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Text(
                              '@${widget.article.authorName}',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: fg,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '• $minutes min',
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(color: muted),
                            ),
                            if (createdLabel.isNotEmpty) ...[
                              const SizedBox(width: 10),
                              Text(
                                '• $createdLabel',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.copyWith(color: muted),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 18),
                        MarkdownBody(
                          data: widget.article.content,
                          selectable: true,
                          styleSheet:
                              MarkdownStyleSheet.fromTheme(
                                Theme.of(context),
                              ).copyWith(
                                p: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      color: fg,
                                      height: 1.6,
                                      fontSize:
                                          (Theme.of(
                                                context,
                                              ).textTheme.bodyLarge?.fontSize ??
                                              16) *
                                          _settings.fontScale,
                                    ),
                                h2: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: fg,
                                      fontWeight: FontWeight.w800,
                                    ),
                                blockquote: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: fg.withValues(alpha: 0.85),
                                      height: 1.6,
                                      fontStyle: FontStyle.italic,
                                    ),
                                code: TextStyle(
                                  color: fg,
                                  backgroundColor: fg.withValues(alpha: 0.10),
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Progress bar (premium touch)
            Positioned(
              top: MediaQuery.of(context).padding.top,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                value: _progress,
                minHeight: 2,
                backgroundColor: Colors.transparent,
                color: fg.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
