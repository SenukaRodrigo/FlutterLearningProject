import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../data/repositories/post_repository.dart';
import '../view_models/editor_view_model.dart';

/// Write tab: a simple Markdown post editor wired to the data layer.
class EditorScreen extends StatelessWidget {
  const EditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => EditorViewModel(context.read<PostRepository>()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('New post'),
          actions: [
            Consumer<EditorViewModel>(
              builder: (context, viewModel, _) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilledButton(
                  onPressed: viewModel.canPublish
                      ? () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final router = GoRouter.of(context);
                          final post = await viewModel.publish();
                          if (post == null) return;
                          messenger.showSnackBar(
                            SnackBar(content: Text('Published "${post.title}"')),
                          );
                          router.go('/post/${post.id}');
                        }
                      : null,
                  child: viewModel.isPublishing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Publish'),
                ),
              ),
            ),
          ],
        ),
        body: Consumer<EditorViewModel>(
          builder: (context, viewModel, _) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                onChanged: viewModel.updateTitle,
                textCapitalization: TextCapitalization.sentences,
                style: Theme.of(context).textTheme.headlineSmall,
                decoration: const InputDecoration(hintText: 'Title'),
              ),
              const SizedBox(height: 16),
              TextField(
                onChanged: viewModel.updateTags,
                decoration: const InputDecoration(
                  labelText: 'Tags',
                  hintText: 'flutter, design, tips',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
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
      ),
    );
  }
}
