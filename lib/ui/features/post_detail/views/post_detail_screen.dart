import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:provider/provider.dart';

import '../../../../domain/models/post.dart';
import '../../../core/author_avatar.dart';
import '../../../core/readable_width.dart';
import '../view_models/post_detail_view_model.dart';

/// Deep-linkable article screen for `/post/:id`.
///
/// Its [PostDetailViewModel] is provided per route by the router, so each post
/// gets a fresh instance.
class PostDetailScreen extends StatelessWidget {
  const PostDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PostDetailViewModel>();

    return Scaffold(
      appBar: AppBar(),
      body: switch (viewModel.status) {
        PostDetailStatus.loading => const Center(child: CircularProgressIndicator()),
        PostDetailStatus.notFound => const _Message(
            icon: Icons.search_off,
            text: 'Post not found',
          ),
        PostDetailStatus.error => _Message(
            icon: Icons.cloud_off_outlined,
            text: viewModel.errorMessage ?? "Couldn't load this post.",
            onRetry: viewModel.load,
          ),
        PostDetailStatus.ready => _Article(viewModel: viewModel),
      },
    );
  }
}

class _Article extends StatelessWidget {
  const _Article({required this.viewModel});

  final PostDetailViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final post = viewModel.post!;
    final coverUrl = post.coverImageUrl;

    return ReadableWidth(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          if (coverUrl != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedNetworkImage(
                  imageUrl: coverUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      ColoredBox(color: theme.colorScheme.surfaceContainerHighest),
                  errorWidget: (context, url, error) =>
                      ColoredBox(color: theme.colorScheme.surfaceContainerHighest),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(post.title, style: theme.textTheme.headlineMedium),
                const SizedBox(height: 20),
                _AuthorRow(post: post),
                const SizedBox(height: 24),
                // The title is rendered above; drop the body's copy of it.
                MarkdownBody(data: post.bodyWithoutLeadingTitle, selectable: true),
                if (post.tags.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final tag in post.tags) Chip(label: Text('#$tag')),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                _LikeButton(post: post, onPressed: viewModel.toggleLike),
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
          const _CommentComposer(),
          if (viewModel.comments.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Text(
                'No comments yet. Start the conversation.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            )
          else
            for (final comment in viewModel.comments)
              _CommentTile(comment: comment),
        ],
      ),
    );
  }
}

class _AuthorRow extends StatelessWidget {
  const _AuthorRow({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        AuthorAvatar(author: post.author, size: 44),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                post.author.displayName,
                style: theme.textTheme.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${post.formattedDate} · ${post.readMinutes} min read',
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LikeButton extends StatelessWidget {
  const _LikeButton({required this.post, required this.onPressed});

  final Post post;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: FilledButton.tonalIcon(
        key: const ValueKey('detail-like-button'),
        onPressed: onPressed,
        icon: Icon(post.likedByMe ? Icons.favorite : Icons.favorite_border),
        label: Text('${post.likeCount}'),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment});

  final Comment comment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AuthorAvatar(author: comment.author),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        comment.author.displayName,
                        style: theme.textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      comment.formattedDate,
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(comment.text, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentComposer extends StatefulWidget {
  const _CommentComposer();

  @override
  State<_CommentComposer> createState() => _CommentComposerState();
}

class _CommentComposerState extends State<_CommentComposer> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final viewModel = context.read<PostDetailViewModel>();
    if (await viewModel.addComment(_controller.text) && mounted) {
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSending =
        context.select<PostDetailViewModel, bool>((vm) => vm.isSendingComment);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              minLines: 1,
              maxLines: 4,
              enabled: !isSending,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _submit(),
              decoration: const InputDecoration(hintText: 'Add a comment…'),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            key: const ValueKey('send-comment-button'),
            onPressed: isSending ? null : _submit,
            icon: isSending
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, this.onRetry});

  final IconData icon;
  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(text, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
