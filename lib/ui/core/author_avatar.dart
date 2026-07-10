import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../domain/models/post.dart';

/// Circular avatar for an [Author], falling back to their initial while the
/// image loads or if it fails.
class AuthorAvatar extends StatelessWidget {
  const AuthorAvatar({super.key, required this.author, this.size = 36});

  final Author author;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = author.displayName.isEmpty ? '?' : author.displayName[0];
    final fallback = ColoredBox(
      color: theme.colorScheme.primaryContainer,
      child: Center(
        child: Text(
          initial,
          style: theme.textTheme.labelLarge
              ?.copyWith(color: theme.colorScheme.onPrimaryContainer),
        ),
      ),
    );
    final avatarUrl = author.avatarUrl;

    return ClipOval(
      child: SizedBox.square(
        dimension: size,
        child: avatarUrl == null
            ? fallback
            : CachedNetworkImage(
                imageUrl: avatarUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => fallback,
                errorWidget: (context, url, error) => fallback,
              ),
      ),
    );
  }
}
