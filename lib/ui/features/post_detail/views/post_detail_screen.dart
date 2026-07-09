import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:provider/provider.dart';

import '../../../../data/repositories/post_repository.dart';
import '../../../../domain/models/post.dart';
import '../view_models/post_detail_view_model.dart';

/// Deep-linkable article screen for `/post/:id`.
class PostDetailScreen extends StatelessWidget {
  const PostDetailScreen({super.key, required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => PostDetailViewModel(
        context.read<PostRepository>(),
        postId,
      ),
      child: Consumer<PostDetailViewModel>(
        builder: (context, viewModel, _) {
          final post = viewModel.post;
          return Scaffold(
            appBar: AppBar(
              actions: [
                if (post != null)
                  TextButton.icon(
                    onPressed: viewModel.toggleLike,
                    icon: Icon(
                      post.likedByMe ? Icons.favorite : Icons.favorite_border,
                      color: post.likedByMe
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    label: Text('${post.likeCount}'),
                  ),
              ],
            ),
            body: Builder(
              builder: (context) {
                if (viewModel.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (post == null) {
                  return const Center(child: Text('Post not found'));
                }
                return _PostBody(viewModel: viewModel, post: post);
              },
            ),
          );
        },
      ),
    );
  }
}

class _PostBody extends StatelessWidget {
  const _PostBody({required this.viewModel, required this.post});

  final PostDetailViewModel viewModel;
  final Post post;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final coverUrl = post.coverImageUrl;
    return ListView(
      children: [
        if (coverUrl != null)
          AspectRatio(
            aspectRatio: 16 / 9,
            child: CachedNetworkImage(
              imageUrl: coverUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) =>
                  const ColoredBox(color: Colors.black12),
              errorWidget: (context, url, error) =>
                  const ColoredBox(color: Colors.black12),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(post.title, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                '${post.author.displayName}  ·  ${post.formattedDate}  ·  '
                '${post.readMinutes} min read',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: MarkdownBody(data: post.body),
        ),
        if (post.tags.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in post.tags) Chip(label: Text('#$tag')),
              ],
            ),
          ),
        const Divider(height: 40, indent: 20, endIndent: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Comments (${post.commentCount})',
            style: theme.textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 8),
        _CommentComposer(onSubmit: viewModel.addComment),
        for (final comment in viewModel.comments)
          ListTile(
            leading: CircleAvatar(
              backgroundImage: comment.author.avatarUrl != null
                  ? CachedNetworkImageProvider(comment.author.avatarUrl!)
                  : null,
              child: comment.author.avatarUrl == null
                  ? Text(comment.author.displayName.characters.first)
                  : null,
            ),
            title: Text(comment.author.displayName),
            subtitle: Text(comment.text),
            trailing: Text(
              comment.formattedDate,
              style: theme.textTheme.labelSmall,
            ),
            isThreeLine: true,
          ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _CommentComposer extends StatefulWidget {
  const _CommentComposer({required this.onSubmit});

  final Future<void> Function(String text) onSubmit;

  @override
  State<_CommentComposer> createState() => _CommentComposerState();
}

class _CommentComposerState extends State<_CommentComposer> {
  final TextEditingController _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    await widget.onSubmit(text);
    if (!mounted) return;
    _controller.clear();
    setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _submit(),
              decoration: const InputDecoration(hintText: 'Add a comment…'),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: _sending ? null : _submit,
            icon: _sending
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}
