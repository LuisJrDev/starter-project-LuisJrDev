import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/constants/article_categories.dart';
import '../../../../../core/widgets/app_loading_overlay.dart';
import '../../../../../core/widgets/app_toast.dart';
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

  Future<void> _loadAuthorFromLoggedUser() async {
    if (widget.editArticle != null) return;

    final user = FirebaseAuth.instance.currentUser;
    final fallback = user?.displayName ?? user?.email ?? 'Usuario';

    if (user == null) {
      _authorController.text = fallback;
      return;
    }

    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = snap.data();
      final name = (data?['name'] as String?)?.trim();

      _authorController.text = (name != null && name.isNotEmpty)
          ? name
          : fallback;
    } catch (_) {
      _authorController.text = fallback;
    }
  }

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
      _category = 'General';
    });
  }

  bool _validateForm(BuildContext context) {
    final valid = _formKey.currentState?.validate() ?? false;

    if (!valid) {
      AppToast.showError(context, 'Por favor, corrige los campos resaltados.');
      return false;
    }

    final editing = widget.editArticle != null;
    final hasExistingThumb =
        (widget.editArticle?.thumbnailPath.isNotEmpty ?? false);
    final hasNewThumb =
        _thumbnailBytes != null && _thumbnailContentType != null;

    if (!editing && !hasNewThumb) {
      AppToast.showError(context, 'Selecciona una miniatura.');
      return false;
    }

    if (editing && !(hasExistingThumb || hasNewThumb)) {
      AppToast.showError(context, 'Selecciona una miniatura.');
      return false;
    }

    return true;
  }

  void _submit({required BuildContext context, required bool publishNow}) {
    if (!_validateForm(context)) return;

    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    _pendingResult = publishNow
        ? AddArticleResult.published
        : AddArticleResult.draftSaved;

    final editing = widget.editArticle != null;

    if (editing) {
      context.read<CreateArticleCubit>().submitEdit(
        existing: widget.editArticle!,
        title: title,
        content: content,
        thumbnailBytes: _thumbnailBytes,
        thumbnailContentType: _thumbnailContentType,
        publishNow: publishNow,
      );
      return;
    }

    context.read<CreateArticleCubit>().submit(
      title: title,
      content: content,
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
      _insertIntoContent('$left$textPlaceholder$right');
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

  static const textPlaceholder = 'texto';

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
    } else {
      _loadAuthorFromLoggedUser();
    }

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

    return BlocListener<CreateArticleCubit, CreateArticleState>(
      listener: (context, state) {
        if (!context.mounted) return;

        if (state is CreateArticleLoading) {
          AppLoadingOverlay.show(
            context,
            message: editing ? 'Guardando cambios…' : 'Creando artículo…',
          );
          return;
        }

        // cualquier estado distinto a loading
        AppLoadingOverlay.hide(context);

        if (state is CreateArticleError) {
          AppToast.showError(context, state.message);
          _pendingResult = null;
          return;
        }

        if (state is CreateArticleSuccess) {
          final result = _pendingResult ?? AddArticleResult.draftSaved;

          AppToast.showSuccess(
            context,
            result == AddArticleResult.published
                ? 'Artículo publicado'
                : 'Borrador guardado',
          );

          _pendingResult = null;

          if (editing) {
            Navigator.of(context).pop(result);
            return;
          }

          _resetForm();
          widget.onResult?.call(result);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(editing ? 'Editar borrador' : 'Crear artículo'),
        ),
        body: BlocBuilder<CreateArticleCubit, CreateArticleState>(
          builder: (context, state) {
            final loading = state is CreateArticleLoading;
            final progress = _completionProgress();

            return AbsorbPointer(
              absorbing: loading,
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                  children: [
                    _CreateHeader(
                      title: editing ? 'Editar borrador' : 'Crear artículo',
                      progress: progress,
                    ),
                    const SizedBox(height: 14),
                    _SectionCard(
                      title: 'Imagen',
                      subtitle: 'Portada (16:9)',
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
                    _SectionCard(
                      title: 'Detalles',
                      subtitle: 'Título, autor y categoría',
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _titleController,
                            maxLength: 120,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Título',
                              hintText: 'Ingresa el título del artículo',
                            ),
                            validator: (v) {
                              final value = (v ?? '').trim();
                              if (value.length < 5) {
                                return 'Título muy corto (mínimo 5 caracteres)';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          if (editing) ...[
                            TextFormField(
                              controller: _authorController,
                              readOnly: true,
                              maxLength: 40,
                              decoration: const InputDecoration(
                                labelText: 'Autor',
                                hintText: 'Nombre público',
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          DropdownButtonFormField<String>(
                            value: _category,
                            decoration: const InputDecoration(
                              labelText: 'Categoría',
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
                    _SectionCard(
                      title: 'Contenido',
                      subtitle: 'Escribe el artículo completo',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _MarkdownToolbar(
                            onBold: () => _wrapSelectionInContent(
                              left: '**',
                              right: '**',
                            ),
                            onH2: () => _insertIntoContent('\n## Subtítulo\n'),
                            onBullets: () =>
                                _insertIntoContent('\n- Ítem 1\n- Ítem 2\n'),
                            onQuote: () => _insertIntoContent('\n> Cita\n'),
                            onCode: () =>
                                _wrapSelectionInContent(left: '`', right: '`'),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _contentController,
                            maxLength: 10000,
                            minLines: 10,
                            maxLines: 18,
                            textInputAction: TextInputAction.newline,
                            decoration: const InputDecoration(
                              labelText: 'Contenido (Markdown)',
                              hintText:
                                  'Usa **negrita**, ## subtítulos, - listas…',
                              alignLabelWithHint: true,
                            ),
                            validator: (v) {
                              final value = (v ?? '').trim();
                              if (value.length < 20) {
                                return 'Contenido muy corto (mínimo 20 caracteres)';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
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
                      'Tu artículo se verá así en el feed',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: BlocBuilder<CreateArticleCubit, CreateArticleState>(
              builder: (context, state) {
                final loading = state is CreateArticleLoading;
                final progress = _completionProgress();

                return _BottomActionBarModern(
                  loading: loading,
                  progress: progress,
                  editing: editing,
                  onSaveDraft: () =>
                      _submit(context: context, publishNow: false),
                  onPublish: () => _submit(context: context, publishNow: true),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _CreateHeader extends StatelessWidget {
  final String title;
  final double progress;

  const _CreateHeader({required this.title, required this.progress});

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
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Añade una miniatura, título, autor, categoría y contenido.',
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
  final Future<String>? existingUrlFuture;
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
                          'Seleccionar miniatura',
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
                              ? 'Seleccionar'
                              : 'Cambiar',
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
  final bool editing;
  final VoidCallback onSaveDraft;
  final VoidCallback onPublish;

  const _BottomActionBarModern({
    required this.loading,
    required this.progress,
    required this.editing,
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
                label: Text(
                  editing ? 'Actualizar borrador' : 'Guardar borrador',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: loading
                    ? null
                    : () {
                        if (!ready) {
                          FocusManager.instance.primaryFocus?.unfocus();
                        }
                        onPublish();
                      },
                icon: const Icon(Icons.publish_outlined),
                label: const Text('Publicar'),
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
    final t = title.isEmpty ? 'Tu título aparecerá aquí' : title;
    final a = author.isEmpty ? 'autor' : author;

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
          _ToolChip(label: '• Lista', onTap: onBullets),
          const SizedBox(width: 8),
          _ToolChip(label: 'Cita', onTap: onQuote),
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
