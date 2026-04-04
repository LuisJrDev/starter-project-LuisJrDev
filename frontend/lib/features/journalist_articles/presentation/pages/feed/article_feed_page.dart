import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../../core/device/device_id_service.dart';
import '../../../../../core/widgets/app_toast.dart';
import '../../../../../injection_container.dart';
import '../../../domain/entities/journalist_article.dart';
import '../../../domain/usecases/add_comment.dart';
import '../../../domain/usecases/is_liked.dart';
import '../../../domain/usecases/toggle_like.dart';
import '../../../domain/usecases/watch_comments.dart';
import '../../bloc/journalist_article/list/article_list_state.dart';
import '../../bloc/journalist_article/list/published_article_list_cubit.dart';
import '../../controllers/saved_articles_controller.dart';
import '../../widgets/feed/comments_firestore_sheet.dart';
import '../../widgets/feed/feed_card.dart';
import '../../widgets/feed/feed_top_bar.dart';
import '../article_detail/article_detail_page.dart';
import '../search/article_search_page.dart';
import 'feed_reactions_store.dart';

class ArticleFeedPage extends StatefulWidget {
  final SavedArticlesController saved;

  const ArticleFeedPage({super.key, required this.saved});
  @override
  State<ArticleFeedPage> createState() => ArticleFeedPageState();
}

class ArticleFeedPageState extends State<ArticleFeedPage> {
  final _pageController = PageController();
  late final PublishedArticleListCubit _cubit;
  late final FeedReactionsStore _reactions;
  late final DeviceIdService _deviceIdService;
  late final String _deviceId;

  final Map<String, Future<String>> _urlFutures = {};

  @override
  void initState() {
    super.initState();
    _cubit = sl<PublishedArticleListCubit>()..start();
    _deviceIdService = sl<DeviceIdService>();
    _deviceId = _deviceIdService.getOrCreate();

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      // En teoría no pasa porque AuthGate no deja entrar,
      // pero por seguridad evitamos crash.
      _reactions = FeedReactionsStore(
        sl<IsArticleLikedUseCase>(),
        sl<ToggleArticleLikeUseCase>(),
        'unknown',
      );
    } else {
      _reactions = FeedReactionsStore(
        sl<IsArticleLikedUseCase>(),
        sl<ToggleArticleLikeUseCase>(),
        uid,
      );
    }
  }

  void scrollToTop() {
    if (!_pageController.hasClients) return;
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _reactions.dispose();
    _cubit.close();
    super.dispose();
  }

  Future<String> _getDownloadUrlCached(String path) {
    return _urlFutures.putIfAbsent(
      path,
      () => FirebaseStorage.instance.ref(path).getDownloadURL(),
    );
  }

  Future<void> _prefetchNextImage(
    BuildContext context,
    JournalistArticleEntity article,
  ) async {
    if (!mounted) return;

    try {
      final url = await _getDownloadUrlCached(article.thumbnailPath);
      if (!mounted) return;

      await precacheImage(CachedNetworkImageProvider(url), this.context);
    } catch (_) {}
  }

  Future<void> _openCommentsFirestore(JournalistArticleEntity article) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF111111),
      showDragHandle: true,
      builder: (_) {
        return CommentsFirestoreSheet(
          article: article,
          watchComments: sl<WatchCommentsUseCase>(),
          addComment: sl<AddCommentUseCase>(),
          deviceId: _deviceId,
          onCommentSent: () {},
        );
      },
    );
  }

  Future<void> _share(JournalistArticleEntity article) async {
    final text =
        '${article.title}\n@${article.authorName}\n\n${article.content}';

    try {
      await Share.share(text);
    } catch (_) {
      if (!mounted) return;
      AppToast.showError(context, 'No se pudo compartir.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: BlocBuilder<PublishedArticleListCubit, ArticleListState>(
          builder: (context, state) {
            if (state is ArticleListLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is ArticleListError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        state.message,
                        style: const TextStyle(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => _cubit.start(),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state is ArticleListLoaded) {
              if (state.articles.isEmpty) return const _EmptyFeed();

              return Stack(
                fit: StackFit.expand,
                children: [
                  ScrollConfiguration(
                    behavior: const _NoGlowScrollBehavior(),
                    child: PageView.builder(
                      controller: _pageController,
                      scrollDirection: Axis.vertical,
                      physics: const ClampingScrollPhysics(),
                      itemCount: state.articles.length,
                      onPageChanged: (index) {
                        if (index + 1 < state.articles.length) {
                          unawaited(
                            _prefetchNextImage(
                              context,
                              state.articles[index + 1],
                            ),
                          );
                        }
                      },
                      itemBuilder: (context, index) {
                        final article = state.articles[index];

                        _reactions.seedLikeCount(article.id, article.likeCount);
                        unawaited(
                          _reactions.prime([
                            article.id,
                            if (index + 1 < state.articles.length)
                              state.articles[index + 1].id,
                          ]),
                        );

                        return AnimatedBuilder(
                          animation: _reactions,
                          builder: (context, _) {
                            final isLiked = _reactions.isLiked(
                              article.id,
                              fallback: false,
                            );
                            final likeCount = _reactions.likeCount(
                              article.id,
                              fallback: article.likeCount,
                            );

                            return FeedCard(
                              article: article,
                              getUrl: _getDownloadUrlCached,
                              isLiked: isLiked,
                              likeCount: likeCount,
                              commentCount: article.commentCount,
                              onLike: () =>
                                  _reactions.toggleLike(articleId: article.id),
                              onComment: () async =>
                                  _openCommentsFirestore(article),
                              onShare: () => _share(article),
                              onReadMore: () async {
                                final url = await _getDownloadUrlCached(
                                  article.thumbnailPath,
                                );
                                if (!context.mounted) return;

                                Navigator.of(context).push(
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
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: FeedTopBar(
                      onSearch: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ArticleSearchPage(
                              saved: widget.saved,
                              reactions: _reactions,
                              publishedArticles: state.articles,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            }

            return const SizedBox();
          },
        ),
      ),
    );
  }
}

class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(18),
        child: Text(
          'Aún no hay artículos publicados.\nVe a Perfil → Mis artículos y publica uno.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70),
        ),
      ),
    );
  }
}

class _NoGlowScrollBehavior extends ScrollBehavior {
  const _NoGlowScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

class _BigLikeOverlay extends StatefulWidget {
  final int pulse;

  const _BigLikeOverlay({required this.pulse});

  @override
  State<_BigLikeOverlay> createState() => _BigLikeOverlayState();
}

class _BigLikeOverlayState extends State<_BigLikeOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
  }

  @override
  void didUpdateWidget(covariant _BigLikeOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pulse != widget.pulse) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.6,
          end: 1.2,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.2,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 40,
      ),
    ]).animate(_controller);

    final opacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 65,
      ),
    ]).animate(_controller);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Opacity(
          opacity: opacity.value,
          child: Transform.scale(
            scale: scale.value,
            child: const Icon(Icons.favorite, size: 110, color: Colors.white),
          ),
        );
      },
    );
  }
}

class _Comment {
  final String author;
  final String text;
  final DateTime createdAt;

  _Comment({required this.author, required this.text, required this.createdAt});
}

class _CommentsSheet extends StatefulWidget {
  final String articleTitle;
  final List<_Comment> comments;
  final void Function(String text) onAdd;

  const _CommentsSheet({
    required this.articleTitle,
    required this.comments,
    required this.onAdd,
  });

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onAdd(text);
    _controller.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Text(
                widget.articleTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Colors.white),
              ),
            ),
            const Divider(height: 1, color: Colors.white12),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: widget.comments.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final c = widget.comments[i];
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CircleAvatar(
                        radius: 14,
                        child: Icon(Icons.person, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.author,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                c.text,
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const Divider(height: 1, color: Colors.white12),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        hintStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.06),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _submit(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _submit,
                    icon: const Icon(Icons.send, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
