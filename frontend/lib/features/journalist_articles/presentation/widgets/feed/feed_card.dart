import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/utils/markdown_excerpt.dart';
import '../../../../../core/utils/time_ago.dart';

import '../../../domain/entities/journalist_article.dart';
import 'storage_image.dart';

class FeedCard extends StatefulWidget {
  final JournalistArticleEntity article;
  final Future<String> Function(String path) getUrl;

  final bool isLiked;
  final int likeCount;
  final int commentCount;

  final VoidCallback onReadMore;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;

  const FeedCard({
    super.key,
    required this.article,
    required this.getUrl,
    required this.isLiked,
    required this.likeCount,
    required this.commentCount,
    required this.onLike,
    required this.onReadMore,
    required this.onComment,
    required this.onShare,
  });

  @override
  State<FeedCard> createState() => _FeedCardState();
}

class _FeedCardState extends State<FeedCard> {
  int _pulse = 0;

  void _handleDoubleTap() {
    HapticFeedback.lightImpact();
    setState(() => _pulse++);

    if (!widget.isLiked) widget.onLike();
  }

  @override
  Widget build(BuildContext context) {
    final dt = widget.article.publishedAt ?? widget.article.createdAt;
    final timeLabel = timeAgo(dt);
    final excerpt = stripMarkdown(widget.article.content);

    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onDoubleTap: _handleDoubleTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: StorageImage(
                  path: widget.article.thumbnailPath,
                  getUrl: widget.getUrl,
                ),
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
            ],
          ),
        ),

        IgnorePointer(
          child: Center(child: _BigLikeOverlay(pulse: _pulse)),
        ),

        Align(
          alignment: Alignment.bottomLeft,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 84, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                  const SizedBox(height: 8),
                  Text(
                    widget.article.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    excerpt,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        '@${widget.article.authorName}',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.white60),
                      ),
                      if (timeLabel != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '• $timeLabel',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.white54),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.tonal(
                      onPressed: widget.onReadMore,
                      child: const Text('Leer noticia completa'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        Align(
          alignment: Alignment.bottomRight,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(right: 12, bottom: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _LikeButton(
                    isLiked: widget.isLiked,
                    count: widget.likeCount,
                    onTap: widget.onLike,
                  ),
                  const SizedBox(height: 14),
                  _Action(
                    icon: Icons.mode_comment_outlined,
                    label: '${widget.commentCount}',
                    onTap: widget.onComment,
                  ),
                  const SizedBox(height: 14),
                  _Action(
                    icon: Icons.share_outlined,
                    label: 'Share',
                    onTap: widget.onShare,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Action extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _Action({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 30),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _LikeButton extends StatefulWidget {
  final bool isLiked;
  final int count;
  final VoidCallback onTap;

  const _LikeButton({
    required this.isLiked,
    required this.count,
    required this.onTap,
  });

  @override
  State<_LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<_LikeButton> {
  double _scale = 1;

  Future<void> _animate() async {
    setState(() => _scale = 1.18);
    await Future<void>.delayed(const Duration(milliseconds: 90));
    if (!mounted) return;
    setState(() => _scale = 1);
  }

  @override
  Widget build(BuildContext context) {
    final icon = widget.isLiked ? Icons.favorite : Icons.favorite_border;
    final color = widget.isLiked ? Colors.redAccent : Colors.white;

    return InkResponse(
      onTap: () {
        widget.onTap();
        unawaited(_animate());
      },
      child: Column(
        children: [
          AnimatedScale(
            scale: _scale,
            duration: const Duration(milliseconds: 90),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 4),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 140),
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: Text(
              '${widget.count}',
              key: ValueKey(widget.count),
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
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
    if (oldWidget.pulse != widget.pulse) _controller.forward(from: 0);
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
