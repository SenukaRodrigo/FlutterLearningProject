import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';

import '../../../../data/repositories/post_repository.dart';
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
      child: Scaffold(
        appBar: AppBar(),
        body: Consumer<PostDetailViewModel>(
          builder: (context, viewModel, _) {
            if (viewModel.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final post = viewModel.post;
            if (post == null) {
              return const Center(child: Text('Post not found'));
            }

            final theme = Theme.of(context);
            return ListView(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: CachedNetworkImage(
                    imageUrl: post.coverImageUrl,
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
                        '${post.author}  ·  ${post.formattedDate}  ·  '
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
                const SizedBox(height: 32),
              ],
            );
          },
        ),
      ),
    );
  }
}
