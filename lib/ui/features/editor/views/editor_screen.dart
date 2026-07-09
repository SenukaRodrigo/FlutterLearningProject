import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../view_models/editor_view_model.dart';

/// Write tab: a simple Markdown post editor. Placeholder for now.
class EditorScreen extends StatelessWidget {
  const EditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => EditorViewModel(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('New post'),
          actions: [
            Consumer<EditorViewModel>(
              builder: (context, viewModel, _) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilledButton(
                  onPressed: viewModel.canPublish
                      ? () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Publishing is coming soon'),
                            ),
                          );
                        }
                      : null,
                  child: const Text('Publish'),
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
