import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../injection_container.dart';
import '../../bloc/journalist_article/create/create_article_cubit.dart';
import '../../bloc/journalist_article/create/create_article_state.dart';

class AddArticlePage extends StatefulWidget {
  const AddArticlePage({super.key});

  @override
  State<AddArticlePage> createState() => _AddArticlePageState();
}

class _AddArticlePageState extends State<AddArticlePage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _authorController = TextEditingController(text: 'Juan');

  Uint8List? _thumbnailBytes;
  String? _thumbnailContentType;

  Future<void> _pickThumbnail() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();

    setState(() {
      _thumbnailBytes = bytes;
      _thumbnailContentType =
          'image/${file.name.split('.').last.toLowerCase()}';
      if (_thumbnailContentType == 'image/jpg') {
        _thumbnailContentType = 'image/jpeg';
      }
    });
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
    return BlocProvider(
      create: (_) => sl<CreateArticleCubit>(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Add Article')),
        body: BlocConsumer<CreateArticleCubit, CreateArticleState>(
          listener: (context, state) {
            if (state is CreateArticleSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Created: ${state.articleId}')),
              );
              Navigator.pop(context);
            }
            if (state is CreateArticleError) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          builder: (context, state) {
            final loading = state is CreateArticleLoading;

            return AbsorbPointer(
              absorbing: loading,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _authorController,
                    decoration: const InputDecoration(labelText: 'Author Name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _contentController,
                    decoration: const InputDecoration(labelText: 'Content'),
                    minLines: 4,
                    maxLines: 10,
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: _pickThumbnail,
                    child: Text(
                      _thumbnailBytes == null
                          ? 'Pick thumbnail'
                          : 'Thumbnail selected (${_thumbnailBytes!.lengthInBytes} bytes)',
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      final title = _titleController.text;
                      final content = _contentController.text;
                      final author = _authorController.text;

                      if (title.trim().length < 5) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Title too short')),
                        );
                        return;
                      }
                      if (content.trim().length < 5) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Content too short')),
                        );
                        return;
                      }
                      if (_thumbnailBytes == null ||
                          _thumbnailContentType == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Pick a thumbnail')),
                        );
                        return;
                      }

                      context.read<CreateArticleCubit>().submit(
                        title: title,
                        content: content,
                        authorName: author,
                        thumbnailBytes: _thumbnailBytes!,
                        thumbnailContentType: _thumbnailContentType!,
                      );
                    },
                    child: loading
                        ? const CircularProgressIndicator()
                        : const Text('Save (draft)'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
