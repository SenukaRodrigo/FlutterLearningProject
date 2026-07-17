import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/post_repository.dart';
import '../../../../domain/models/post.dart';
import '../../../core/author_avatar.dart';
import '../../../core/readable_width.dart';
import '../view_models/profile_view_model.dart';

/// Profile tab: the signed-in author and the posts they have published.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ProfileViewModel(context.read<PostRepository>()),
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ProfileViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            key: const ValueKey('sign-out-button'),
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            // No navigation here: signing out changes auth state, and the
            // router's redirect takes it from there.
            onPressed: () => context.read<AuthRepository>().signOut(),
          ),
        ],
      ),
      body: switch (viewModel.status) {
        ProfileStatus.loading => const Center(child: CircularProgressIndicator()),
        ProfileStatus.error => _ErrorView(onRetry: viewModel.load),
        ProfileStatus.ready => ReadableWidth(
            child: RefreshIndicator(
              onRefresh: viewModel.load,
              child: _ProfileBody(viewModel: viewModel),
            ),
          ),
      },
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({required this.viewModel});

  final ProfileViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final author = viewModel.author;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        Center(child: AuthorAvatar(author: author, size: 96)),
        const SizedBox(height: 16),
        Text(
          author.displayName,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          author.bio,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Stat(value: '${viewModel.postCount}', label: 'Posts'),
            const SizedBox(width: 32),
            _Stat(value: '${viewModel.likeCount}', label: 'Likes'),
          ],
        ),
        const Divider(height: 40),
        Text('Published posts', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (viewModel.posts.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              "You haven't published anything yet.",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          )
        else
          for (final post in viewModel.posts) _PostTile(post: post),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: theme.textTheme.headlineSmall),
        Text(
          label,
          style: theme.textTheme.labelMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _PostTile extends StatelessWidget {
  const _PostTile({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        key: ValueKey('profile-post-${post.id}'),
        onTap: () => context.push('/post/${post.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.title,
                style: theme.textTheme.titleMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    post.shortDate,
                    style: theme.textTheme.labelMedium?.copyWith(color: muted),
                  ),
                  const Spacer(),
                  Icon(
                    post.likedByMe ? Icons.favorite : Icons.favorite_border,
                    size: 16,
                    color: post.likedByMe ? theme.colorScheme.primary : muted,
                  ),
                  const SizedBox(width: 4),
                  Text('${post.likeCount}',
                      style: theme.textTheme.labelMedium),
                  const SizedBox(width: 16),
                  Icon(Icons.mode_comment_outlined, size: 16, color: muted),
                  const SizedBox(width: 4),
                  Text('${post.commentCount}',
                      style: theme.textTheme.labelMedium),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined,
                size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text("Couldn't load your profile.",
                style: theme.textTheme.bodyLarge),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
