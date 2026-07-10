import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../data/repositories/post_repository.dart';
import '../../../core/readable_width.dart';
import '../view_models/editor_view_model.dart';

/// Write tab: a Markdown post editor with a live preview.
class EditorScreen extends StatelessWidget {
  const EditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => EditorViewModel(context.read<PostRepository>()),
      child: const _EditorView(),
    );
  }
}

class _EditorView extends StatefulWidget {
  const _EditorView();

  @override
  State<_EditorView> createState() => _EditorViewState();
}

class _EditorViewState extends State<_EditorView> {
  // The body field is torn down while previewing, so its text lives here
  // rather than in the field's own internal controller.
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  bool _isPreviewing = false;

  @override
  void dispose() {
    _titleController.dispose();
    _tagsController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    final viewModel = context.read<EditorViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    final error = viewModel.validationError;
    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    final post = await viewModel.publish();
    if (!mounted) return;
    if (post == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text("Couldn't publish your post.")),
      );
      return;
    }

    messenger.showSnackBar(SnackBar(content: Text('Published "${post.title}"')));
    _titleController.clear();
    _tagsController.clear();
    _bodyController.clear();
    setState(() => _isPreviewing = false);
    viewModel.reset();
    router.push('/post/${post.id}');
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<EditorViewModel>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New post'),
        actions: [
          IconButton(
            key: const ValueKey('preview-toggle'),
            onPressed: () => setState(() => _isPreviewing = !_isPreviewing),
            tooltip: _isPreviewing ? 'Edit' : 'Preview',
            icon: Icon(_isPreviewing
                ? Icons.edit_outlined
                : Icons.visibility_outlined),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4, right: 8),
            child: FilledButton(
              key: const ValueKey('publish-button'),
              onPressed: viewModel.isPublishing ? null : _publish,
              child: viewModel.isPublishing
                  ? const _PublishingLabel()
                  : const Text('Publish'),
            ),
          ),
        ],
      ),
      body: ReadableWidth(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _titleController,
              onChanged: viewModel.updateTitle,
              textCapitalization: TextCapitalization.sentences,
              style: theme.textTheme.headlineSmall,
              decoration: const InputDecoration(hintText: 'Title'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _tagsController,
              onChanged: viewModel.updateTags,
              decoration: const InputDecoration(
                labelText: 'Tags',
                hintText: 'flutter, design, tips',
              ),
            ),
            const SizedBox(height: 16),
            if (_isPreviewing)
              _BodyPreview(body: viewModel.body)
            else
              TextField(
                controller: _bodyController,
                onChanged: viewModel.updateBody,
                minLines: 10,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Write your story in Markdown…',
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PublishingLabel extends StatelessWidget {
  const _PublishingLabel();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox.square(
          dimension: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            // The button is disabled while publishing, so it sits on the
            // disabled grey rather than the primary fill.
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 8),
        const Text('Publishing…'),
      ],
    );
  }
}

class _BodyPreview extends StatelessWidget {
  const _BodyPreview({required this.body});

  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 240),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: body.trim().isEmpty
          ? Text(
              'Nothing to preview yet.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            )
          : MarkdownBody(data: body, selectable: true),
    );
  }
}
