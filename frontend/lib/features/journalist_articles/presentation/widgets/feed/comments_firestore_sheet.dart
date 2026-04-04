import 'package:flutter/material.dart';

import '../../../../../core/widgets/app_loading_overlay.dart';
import '../../../../../core/widgets/app_toast.dart';
import '../../../../../injection_container.dart';
import '../../../domain/entities/journalist_article.dart';
import '../../../domain/usecases/add_comment.dart';
import '../../../domain/usecases/resolve_author_name.dart';
import '../../../domain/usecases/watch_comments.dart';

class CommentsFirestoreSheet extends StatefulWidget {
  final JournalistArticleEntity article;

  final WatchCommentsUseCase watchComments;
  final AddCommentUseCase addComment;

  final String deviceId;
  final VoidCallback? onCommentSent;

  const CommentsFirestoreSheet({
    super.key,
    required this.article,
    required this.watchComments,
    required this.addComment,
    required this.deviceId,
    this.onCommentSent,
  });

  @override
  State<CommentsFirestoreSheet> createState() => _CommentsFirestoreSheetState();
}

class _CommentsFirestoreSheetState extends State<CommentsFirestoreSheet> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_sending) return;

    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _sending = true;
    FocusManager.instance.primaryFocus?.unfocus();

    AppLoadingOverlay.show(context, message: 'Enviando comentario…');

    try {
      final resolveAuthor = sl<ResolveAuthorNameUseCase>();
      final (uid, authorName) = await resolveAuthor();

      _controller.clear();

      await widget.addComment(
        params: AddCommentParams(
          articleId: widget.article.id,
          deviceId: widget.deviceId,
          uid: uid,
          authorName: authorName,
          text: text,
        ),
      );

      if (!mounted) return;

      AppToast.showSuccess(context, 'Comentario enviado');
      widget.onCommentSent?.call();
    } catch (e) {
      if (!mounted) return;
      AppToast.showError(
        context,
        'No se pudo enviar el comentario. Intenta nuevamente.',
      );
    } finally {
      if (mounted) {
        AppLoadingOverlay.hide(context);
      }
      _sending = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bottom = media.viewInsets.bottom + media.viewPadding.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottom),
      child: SizedBox(
        height: media.size.height * 0.75,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Text(
                widget.article.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Colors.white),
              ),
            ),
            const Divider(height: 1, color: Colors.white12),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: widget.watchComments(widget.article.id),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text(
                        'No se pudieron cargar los comentarios.',
                        style: TextStyle(color: Colors.white54),
                      ),
                    );
                  }

                  final items = snapshot.data ?? const <Map<String, dynamic>>[];

                  if (items.isEmpty) {
                    return const Center(
                      child: Text(
                        'Aún no hay comentarios',
                        style: TextStyle(color: Colors.white54),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final c = items[i];
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
                                color: Colors.white.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    (c['authorName'] as String?) ?? 'Anónimo',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    (c['text'] as String?) ?? '',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1, color: Colors.white12),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        enabled: !_sending,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Escribe un comentario…',
                          hintStyle: const TextStyle(color: Colors.white54),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.06),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Enviar',
                      onPressed: _sending ? null : _send,
                      icon: const Icon(Icons.send, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
