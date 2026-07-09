import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../data/repositories/user_repository.dart';
import '../view_models/profile_view_model.dart';

/// Profile tab. Placeholder content driven by [ProfileViewModel].
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ProfileViewModel(context.read<UserRepository>()),
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

            final user = viewModel.user;
            if (user == null) {
              return const Center(child: Text('No profile'));
            }

            final theme = Theme.of(context);
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 48,
                    backgroundImage:
                        CachedNetworkImageProvider(user.avatarUrl),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(user.name, style: theme.textTheme.titleLarge),
                ),
                Center(
                  child: Text(
                    user.handle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(user.bio, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.article_outlined),
                    title: const Text('Published posts'),
                    trailing: Text('${user.postCount}'),
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
