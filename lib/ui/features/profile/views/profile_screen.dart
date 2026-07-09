import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../data/repositories/post_repository.dart';
import '../view_models/profile_view_model.dart';

/// Profile tab. Shows the signed-in [Author], driven by [ProfileViewModel].
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) =>
          ProfileViewModel(context.read<PostRepository>()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          actions: [
            IconButton(
              tooltip: 'Log out',
              icon: const Icon(Icons.logout),
              onPressed: () => context.go('/login'),
            ),
          ],
        ),
        body: Consumer<ProfileViewModel>(
          builder: (context, viewModel, _) {
            if (viewModel.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final author = viewModel.author;
            if (author == null) {
              return const Center(child: Text('No profile'));
            }

            final theme = Theme.of(context);
            final avatarUrl = author.avatarUrl;
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 48,
                    backgroundImage: avatarUrl != null
                        ? CachedNetworkImageProvider(avatarUrl)
                        : null,
                    child: avatarUrl == null
                        ? Text(
                            author.displayName.characters.first,
                            style: theme.textTheme.headlineMedium,
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    author.displayName,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: 16),
                Text(author.bio, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.article_outlined),
                    title: const Text('Published posts'),
                    trailing: Text('${viewModel.postCount}'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
