import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/resources/data_state.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/journalist_article.dart';
import '../../domain/usecases/delete_article.dart';
import '../bloc/journalist_article/list/article_list_cubit.dart';
import '../bloc/journalist_article/list/article_list_state.dart';
import '../bloc/journalist_article/list/published_article_list_cubit.dart';
import '../../domain/usecases/publish_article.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../pages/add_article/add_article_page.dart';
import '../pages/article_detail/article_detail_page.dart';
import '../controllers/saved_articles_controller.dart';

class MyArticlesSection extends StatefulWidget {
  final int initialTabIndex;
  final SavedArticlesController saved;

  const MyArticlesSection({
    super.key,
    this.initialTabIndex = 0,
    required this.saved,
  });

  @override
  State<MyArticlesSection> createState() => _MyArticlesSectionState();
}

class _MyArticlesSectionState extends State<MyArticlesSection>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  final Map<String, Future<String>> _urlFutures = {};

  Future<String> _getDownloadUrlCached(String path) {
    return _urlFutures.putIfAbsent(
      path,
      () => FirebaseStorage.instance.ref(path).getDownloadURL(),
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 2),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _publish(BuildContext innerContext, String articleId) async {
    final useCase = sl<PublishJournalistArticleUseCase>();
    final result = await useCase(params: articleId);

    if (!mounted) return;

    if (result is DataSuccess) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Article published')));

      _tabController.animateTo(1);

      // IMPORTANTE: usa innerContext (debajo del provider)
      innerContext.read<PublishedArticleListCubit>().start();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to publish')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<ArticleListCubit>()..start()),
        BlocProvider(create: (_) => sl<PublishedArticleListCubit>()..start()),
      ],
      child: Builder(
        builder: (innerContext) {
          return Column(
            children: [
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Drafts'),
                  Tab(text: 'Published'),
                  Tab(text: 'Saved'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Drafts
                    BlocBuilder<ArticleListCubit, ArticleListState>(
                      builder: (context, state) {
                        if (state is ArticleListLoading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (state is ArticleListError) {
                          return Center(child: Text(state.message));
                        }
                        if (state is ArticleListLoaded) {
                          final drafts = state.articles
                              .where((a) => a.status == 'draft')
                              .toList();

                          if (drafts.isEmpty) {
                            return const Center(child: Text('No drafts yet'));
                          }

                          return ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: drafts.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final a = drafts[index];
                              return _ArticleCardTile(
                                articleId: a.id,
                                title: a.title,
                                authorName: a.authorName,
                                statusLabel: 'Draft',
                                statusColor: Colors.orange,
                                thumbnailPath: a.thumbnailPath,
                                getUrl: _getDownloadUrlCached,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    FilledButton.tonal(
                                      onPressed: () =>
                                          _publish(innerContext, a.id),
                                      child: const Text('Publish'),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      tooltip: 'Delete',
                                      onPressed: () => _deleteArticle(
                                        innerContext: innerContext,
                                        articleId: a.id,
                                        thumbnailPath: a.thumbnailPath,
                                      ),
                                      icon: const Icon(Icons.delete_outline),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => AddArticlePage.edit(
                                        article: a,
                                        thumbnailUrlFuture:
                                            _getDownloadUrlCached(
                                              a.thumbnailPath,
                                            ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        }
                        return const SizedBox();
                      },
                    ),

                    // Published
                    BlocBuilder<PublishedArticleListCubit, ArticleListState>(
                      builder: (context, state) {
                        if (state is ArticleListLoading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (state is ArticleListError) {
                          return Center(child: Text(state.message));
                        }
                        if (state is ArticleListLoaded) {
                          if (state.articles.isEmpty) {
                            return const Center(
                              child: Text('No published yet'),
                            );
                          }

                          return ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: state.articles.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final a = state.articles[index];
                              return _ArticleCardTile(
                                articleId: a.id,
                                title: a.title,
                                authorName: a.authorName,
                                statusLabel: 'Published',
                                statusColor: Colors.green,
                                thumbnailPath: a.thumbnailPath,
                                getUrl: _getDownloadUrlCached,
                                trailing: IconButton(
                                  tooltip: 'Delete',
                                  onPressed: () => _deleteArticle(
                                    innerContext: innerContext,
                                    articleId: a.id,
                                    thumbnailPath: a.thumbnailPath,
                                  ),
                                  icon: const Icon(Icons.delete_outline),
                                ),
                                onTap: () async {
                                  final url = await _getDownloadUrlCached(
                                    a.thumbnailPath,
                                  );
                                  if (!context.mounted) return;

                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ArticleDetailPage(
                                        article: a,
                                        thumbnailUrl: url,
                                        saved: widget.saved,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                    // Saved
                    AnimatedBuilder(
                      animation: widget.saved,
                      builder: (context, _) {
                        if (!widget.saved.loaded) {
                          // por si aún no carga (primera vez)
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final savedItems = widget.saved.items;
                        if (savedItems.isEmpty) {
                          return const Center(
                            child: Text('No saved articles yet'),
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: savedItems.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final s = savedItems[index];

                            return _ArticleCardTile(
                              articleId: s.id,
                              title: s.title,
                              authorName: s.authorName,
                              statusLabel: 'Saved',
                              statusColor: Colors.blueGrey,
                              thumbnailPath: s.thumbnailPath,
                              getUrl: _getDownloadUrlCached,
                              trailing: IconButton(
                                tooltip: 'Remove',
                                onPressed: () => widget.saved.remove(s.id),
                                icon: const Icon(
                                  Icons.bookmark_remove_outlined,
                                ),
                              ),
                              onTap: () async {
                                final nav = Navigator.of(context);
                                final url = await _getDownloadUrlCached(
                                  s.thumbnailPath,
                                );
                                if (!context.mounted) return;

                                final created = s.createdAtMillis == null
                                    ? DateTime.now()
                                    : DateTime.fromMillisecondsSinceEpoch(
                                        s.createdAtMillis!,
                                      );

                                final article = JournalistArticleEntity(
                                  id: s.id,
                                  title: s.title,
                                  content: s.content,
                                  status: 'published',
                                  authorName: s.authorName,
                                  thumbnailPath: s.thumbnailPath,
                                  publishedAt: null,
                                  category: s.category,
                                  createdAt: created,
                                  updatedAt: created, // requerido por tu entity
                                  likeCount: 0,
                                  commentCount: 0,
                                );

                                nav.push(
                                  MaterialPageRoute(
                                    builder: (_) => ArticleDetailPage(
                                      article: article,
                                      thumbnailUrl: url,
                                      saved: widget.saved,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete article?'),
        content: const Text('This action cannot be undone.'),
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
    return ok ?? false;
  }

  Future<void> _deleteArticle({
    required BuildContext innerContext,
    required String articleId,
    required String thumbnailPath,
  }) async {
    final ok = await _confirmDelete(context);
    if (!ok) return;

    final useCase = sl<DeleteJournalistArticleUseCase>();
    final result = await useCase(
      params: DeleteArticleParams(
        articleId: articleId,
        thumbnailPath: thumbnailPath,
      ),
    );
    if (!mounted) return;

    if (result is DataSuccess) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Article deleted')));

      // refresca ambas tabs
      innerContext.read<ArticleListCubit>().start();
      innerContext.read<PublishedArticleListCubit>().start();

      // si estás en Published y borraste, te quedas; si borraste draft, igual ok
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to delete')));
    }
  }
}

class _ArticleCardTile extends StatelessWidget {
  final String articleId;
  final String title;
  final String authorName;
  final String statusLabel;
  final Color statusColor;
  final String thumbnailPath;
  final Future<String> Function(String path) getUrl;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _ArticleCardTile({
    required this.articleId,
    required this.title,
    required this.authorName,
    required this.statusLabel,
    required this.statusColor,
    required this.thumbnailPath,
    required this.getUrl,
    required this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            AspectRatio(
              aspectRatio: 16 / 9,
              child: FutureBuilder<String>(
                future: getUrl(thumbnailPath),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return Container(
                      color: scheme.surfaceContainerHighest.withValues(
                        alpha: 0.4,
                      ),
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  }

                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: snap.data!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: scheme.surfaceContainerHighest.withValues(
                            alpha: 0.4,
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: scheme.surfaceContainerHighest.withValues(
                            alpha: 0.4,
                          ),
                          child: const Icon(Icons.broken_image_outlined),
                        ),
                        fadeInDuration: const Duration(milliseconds: 120),
                      ),
                      // Status chip
                      Positioned(
                        left: 10,
                        top: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            statusLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Text
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '@$authorName',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(height: 12),
                    Align(alignment: Alignment.centerRight, child: trailing!),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
