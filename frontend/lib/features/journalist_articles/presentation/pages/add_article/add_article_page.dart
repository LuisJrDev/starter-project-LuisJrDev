import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/constants/article_categories.dart';
import '../../../../../injection_container.dart';
import '../../../domain/entities/journalist_article.dart';
import '../../bloc/journalist_article/create/create_article_cubit.dart';
import '../../bloc/journalist_article/create/create_article_state.dart';

enum AddArticleResult { draftSaved, published }

class AddArticlePage extends StatefulWidget {
  final void Function(AddArticleResult result)? onResult;
  final JournalistArticleEntity? editArticle;
  final Future<String>? thumbnailUrlFuture;

  const AddArticlePage({
    super.key,
    this.onResult,
    this.editArticle,
    this.thumbnailUrlFuture,
  });

  const AddArticlePage.edit({
    super.key,
    required JournalistArticleEntity article,
    required Future<String> thumbnailUrlFuture,
    this.onResult,
  }) : editArticle = article,
       thumbnailUrlFuture = thumbnailUrlFuture;

  @override
  State<AddArticlePage> createState() => _AddArticlePageState();
}

class _AddArticlePageState extends State<AddArticlePage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _authorController = TextEditingController();

  AddArticleResult? _pendingResult;
  String _category = 'General';

  Uint8List? _thumbnailBytes;
  String? _thumbnailContentType;
  bool _pickingImage = false;

  final _formKey = GlobalKey<FormState>();

  Future<void> _pickThumbnail() async {
    if (_pickingImage) return;

    _pickingImage = true;
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (file == null) return;

      final bytes = await file.readAsBytes();
      if (!mounted) return;

      setState(() {
        _thumbnailBytes = bytes;
        _thumbnailContentType =
            'image/${file.name.split('.').last.toLowerCase()}';
        if (_thumbnailContentType == 'image/jpg') {
          _thumbnailContentType = 'image/jpeg';
        }
      });
    } finally {
      _pickingImage = false;
    }
  }

  void _removeThumbnail() {
    setState(() {
      _thumbnailBytes = null;
      _thumbnailContentType = null;
    });
  }

  void _resetForm() {
    _titleController.clear();
    _contentController.clear();
    _authorController.clear();
    setState(() {
      _thumbnailBytes = null;
      _thumbnailContentType = null;
    });
  }

  bool _validateForm(BuildContext context) {
    final valid = _formKey.currentState?.validate() ?? false;

    if (!valid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix the highlighted fields')),
      );
      return false;
    }

    final editing = widget.editArticle != null;
    final hasExistingThumb =
        (widget.editArticle?.thumbnailPath.isNotEmpty ?? false);
    final hasNewThumb =
        _thumbnailBytes != null && _thumbnailContentType != null;

    // Create: obligar thumbnail nuevo
    if (!editing && !hasNewThumb) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pick a thumbnail')));
      return false;
    }

    // Edit: permitir thumb existente o nuevo
    if (editing && !(hasExistingThumb || hasNewThumb)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pick a thumbnail')));
      return false;
    }

    return true;
  }

  void _submit({required BuildContext context, required bool publishNow}) {
    if (!_validateForm(context)) return;

    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    final author = _authorController.text.trim();

    _pendingResult = publishNow
        ? AddArticleResult.published
        : AddArticleResult.draftSaved;

    final editing = widget.editArticle != null;

    if (editing) {
      context.read<CreateArticleCubit>().submitEdit(
        existing: widget.editArticle!,
        title: title,
        content: content,
        authorName: author,
        thumbnailBytes: _thumbnailBytes, // puede ser null si mantiene imagen
        thumbnailContentType: _thumbnailContentType, // puede ser null
        publishNow: publishNow,
      );
      return;
    }

    // Create (igual que antes)
    context.read<CreateArticleCubit>().submit(
      title: title,
      content: content,
      authorName: author,
      category: _category,
      thumbnailBytes: _thumbnailBytes!,
      thumbnailContentType: _thumbnailContentType!,
      publishNow: publishNow,
    );
  }

  void _insertIntoContent(String insert) {
    final c = _contentController;
    final sel = c.selection;

    final text = c.text;
    final start = sel.isValid ? sel.start : text.length;
    final end = sel.isValid ? sel.end : text.length;

    final newText = text.replaceRange(start, end, insert);

    c.value = c.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: start + insert.length),
      composing: TextRange.empty,
    );
  }

  void _wrapSelectionInContent({required String left, required String right}) {
    final c = _contentController;
    final sel = c.selection;

    if (!sel.isValid || sel.isCollapsed) {
      // si no hay selección, inserta placeholder
      _insertIntoContent('$left$textPlaceholder$right');
      // mueve cursor para seleccionar "text"
      final idx = c.text.indexOf(textPlaceholder);
      if (idx >= 0) {
        c.selection = TextSelection(
          baseOffset: idx,
          extentOffset: idx + textPlaceholder.length,
        );
      }
      return;
    }

    final text = c.text;
    final selected = text.substring(sel.start, sel.end);
    final wrapped = '$left$selected$right';

    final newText = text.replaceRange(sel.start, sel.end, wrapped);
    c.value = c.value.copyWith(
      text: newText,
      selection: TextSelection(
        baseOffset: sel.start,
        extentOffset: sel.start + wrapped.length,
      ),
      composing: TextRange.empty,
    );
  }

  static const textPlaceholder = 'text';

  double _completionProgress() {
    int done = 0;

    final editing = widget.editArticle != null;
    final hasExistingThumb =
        (widget.editArticle?.thumbnailPath.isNotEmpty ?? false);
    final hasAnyThumb =
        (_thumbnailBytes != null) || (editing && hasExistingThumb);

    if (hasAnyThumb) done++;
    if (_titleController.text.trim().length >= 5) done++;
    if (_authorController.text.trim().isNotEmpty) done++;
    if (_contentController.text.trim().length >= 20) done++;

    return done / 4.0;
  }

  @override
  void initState() {
    super.initState();
    final a = widget.editArticle;
    if (a != null) {
      _titleController.text = a.title;
      _authorController.text = a.authorName;
      _contentController.text = a.content;
      _category = a.category;
      // thumbnailBytes no lo tienes aquí, solo url.
    }

    // Para actualizar progress en tiempo real
    _titleController.addListener(() => setState(() {}));
    _authorController.addListener(() => setState(() {}));
    _contentController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final editing = widget.editArticle != null;

    return BlocProvider(
      create: (_) => sl<CreateArticleCubit>(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.editArticle == null ? 'Create' : 'Edit draft'),
        ),
        body: BlocConsumer<CreateArticleCubit, CreateArticleState>(
          listener: (context, state) {
            if (state is CreateArticleSuccess) {
              final result = _pendingResult ?? AddArticleResult.draftSaved;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    result == AddArticleResult.published
                        ? 'Article published'
                        : 'Draft saved',
                  ),
                ),
              );

              final editing = widget.editArticle != null;

              _pendingResult = null;

              if (editing) {
                // En edición: vuelve atrás (listado de drafts/published)
                Navigator.of(context).pop(result);
                return;
              }

              // En create: limpia y notifica
              _resetForm();
              widget.onResult?.call(result);
            }

            if (state is CreateArticleError) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          builder: (context, state) {
            final loading = state is CreateArticleLoading;
            final progress = _completionProgress();

            return Stack(
              children: [
                AbsorbPointer(
                  absorbing: loading,
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                      children: [
                        _CreateHeader(progress: progress),
                        const SizedBox(height: 14),

                        // MEDIA
                        _SectionCard(
                          title: 'Media',
                          subtitle: 'Thumbnail (16:9)',
                          child: _ThumbnailPickerModern(
                            bytes: _thumbnailBytes,
                            existingUrlFuture:
                                (widget.editArticle != null &&
                                    _thumbnailBytes == null)
                                ? widget.thumbnailUrlFuture
                                : null,
                            onPick: _pickThumbnail,
                            onRemove: (_thumbnailBytes == null)
                                ? null
                                : _removeThumbnail,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // DETAILS
                        _SectionCard(
                          title: 'Details',
                          subtitle: 'How it will appear in the feed',
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _titleController,
                                maxLength: 120,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Title',
                                  hintText: 'Catchy, short and clear…',
                                ),
                                validator: (v) {
                                  final value = (v ?? '').trim();
                                  if (value.length < 5)
                                    return 'Title too short';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _authorController,
                                maxLength: 40,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Author',
                                  hintText: 'Public name',
                                ),
                                validator: (v) {
                                  final value = (v ?? '').trim();
                                  if (value.isEmpty)
                                    return 'Author is required';
                                  if (value.length < 2)
                                    return 'Author too short';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                value: _category,
                                decoration: const InputDecoration(
                                  labelText: 'Category',
                                ),
                                items: kArticleCategories
                                    .map(
                                      (c) => DropdownMenuItem(
                                        value: c,
                                        child: Text(c),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _category = v ?? 'General'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // STORY
                        _SectionCard(
                          title: 'Story',
                          subtitle: 'Write the full article',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _MarkdownToolbar(
                                onBold: () => _wrapSelectionInContent(
                                  left: '**',
                                  right: '**',
                                ),
                                onH2: () =>
                                    _insertIntoContent('\n## Subtitle\n'),
                                onBullets: () => _insertIntoContent(
                                  '\n- Item 1\n- Item 2\n',
                                ),
                                onQuote: () =>
                                    _insertIntoContent('\n> Quote\n'),
                                onCode: () => _wrapSelectionInContent(
                                  left: '`',
                                  right: '`',
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _contentController,
                                maxLength: 10000,
                                minLines: 10,
                                maxLines: 18,
                                textInputAction: TextInputAction.newline,
                                decoration: const InputDecoration(
                                  labelText: 'Content (Markdown)',
                                  hintText:
                                      'Use **bold**, ## subtitles, - lists…',
                                  alignLabelWithHint: true,
                                ),
                                validator: (v) {
                                  final value = (v ?? '').trim();
                                  if (value.length < 20) {
                                    return 'Content too short (min 20 chars)';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // preview (mini)
                        _MiniFeedPreview(
                          title: _titleController.text.trim(),
                          author: _authorController.text.trim(),
                          hasImage:
                              _thumbnailBytes != null ||
                              (widget.editArticle?.thumbnailPath.isNotEmpty ??
                                  false),
                        ),

                        const SizedBox(height: 20),
                        Text(
                          'Tip: Save draft while you write, publish when ready.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ),

                Align(
                  alignment: Alignment.bottomCenter,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                      child: _BottomActionBarModern(
                        loading: loading,
                        progress: progress,
                        editing: editing, // <-- nuevo
                        onSaveDraft: () =>
                            _submit(context: context, publishNow: false),
                        onPublish: () =>
                            _submit(context: context, publishNow: true),
                      ),
                    ),
                  ),
                ),
                if (loading)
                  _PublishingOverlay(
                    text: (_pendingResult == AddArticleResult.published)
                        ? 'Publishing…'
                        : 'Saving draft…',
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CreateHeader extends StatelessWidget {
  final double progress;

  const _CreateHeader({required this.progress});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create article',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Add a thumbnail, title, author, category and content.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(value: progress, minHeight: 8),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _ThumbnailPickerModern extends StatelessWidget {
  final Uint8List? bytes;
  final Future<String>? existingUrlFuture; // NUEVO
  final VoidCallback onPick;
  final VoidCallback? onRemove;

  const _ThumbnailPickerModern({
    required this.bytes,
    required this.existingUrlFuture,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Material(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        child: InkWell(
          onTap: onPick,
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (bytes != null)
                  Image.memory(bytes!, fit: BoxFit.cover)
                else if (existingUrlFuture != null)
                  FutureBuilder<String>(
                    future: existingUrlFuture,
                    builder: (context, snap) {
                      if (!snap.hasData) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            strokeWidth: 2,
                          ),
                        );
                      }
                      return Image.network(snap.data!, fit: BoxFit.cover);
                    },
                  )
                else
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.image_outlined,
                          size: 34,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Pick thumbnail',
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),

                Positioned(
                  top: 10,
                  right: 10,
                  child: Row(
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: onPick,
                        icon: const Icon(
                          Icons.photo_library_outlined,
                          size: 18,
                        ),
                        label: Text(
                          (bytes == null && existingUrlFuture == null)
                              ? 'Pick'
                              : 'Change',
                        ),
                      ),
                      if (onRemove != null) ...[
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          onPressed: onRemove,
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomActionBarModern extends StatelessWidget {
  final bool loading;
  final double progress;
  final bool editing; // <-- nuevo
  final VoidCallback onSaveDraft;
  final VoidCallback onPublish;

  const _BottomActionBarModern({
    required this.loading,
    required this.progress,
    required this.editing, // <-- nuevo
    required this.onSaveDraft,
    required this.onPublish,
  });

  @override
  Widget build(BuildContext context) {
    final ready = progress >= 1.0;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: loading ? null : onSaveDraft,
                icon: const Icon(Icons.save_outlined),
                label: Text(editing ? 'Update draft' : 'Save draft'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: loading
                    ? null
                    : () {
                        // Si falta algo, dispara validación visible
                        if (!ready) {
                          FocusManager.instance.primaryFocus?.unfocus();
                        }
                        onPublish();
                      },
                icon: const Icon(Icons.publish_outlined),
                label: Text(
                  editing ? 'Publish' : (ready ? 'Publish' : 'Complete'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniFeedPreview extends StatelessWidget {
  final String title;
  final String author;
  final bool hasImage;

  const _MiniFeedPreview({
    required this.title,
    required this.author,
    required this.hasImage,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = title.isEmpty ? 'Your title will appear here' : title;
    final a = author.isEmpty ? 'author' : author;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 84,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
              ),
              child: Icon(
                hasImage ? Icons.check_circle_outline : Icons.image_outlined,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '@$a',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
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

class _PublishingOverlay extends StatelessWidget {
  final String text;

  const _PublishingOverlay({required this.text});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AbsorbPointer(
        absorbing: true,
        child: Container(
          color: Colors.black.withValues(alpha: 0.55),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF111113),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MarkdownToolbar extends StatelessWidget {
  final VoidCallback onBold;
  final VoidCallback onH2;
  final VoidCallback onBullets;
  final VoidCallback onQuote;
  final VoidCallback onCode;

  const _MarkdownToolbar({
    required this.onBold,
    required this.onH2,
    required this.onBullets,
    required this.onQuote,
    required this.onCode,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _ToolChip(label: 'B', onTap: onBold),
          const SizedBox(width: 8),
          _ToolChip(label: 'H2', onTap: onH2),
          const SizedBox(width: 8),
          _ToolChip(label: '• List', onTap: onBullets),
          const SizedBox(width: 8),
          _ToolChip(label: 'Quote', onTap: onQuote),
          const SizedBox(width: 8),
          _ToolChip(label: '</>', onTap: onCode),
        ],
      ),
    );
  }
}

class _ToolChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ToolChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      onPressed: onTap,
    );
  }
}
