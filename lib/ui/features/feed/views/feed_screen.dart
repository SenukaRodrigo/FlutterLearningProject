import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../domain/models/post.dart';
import '../../../core/author_avatar.dart';
import '../../../core/theme_controller.dart';
import '../view_models/feed_view_model.dart';

/// Above this width the feed lays posts out as a grid instead of a single
/// column. Measured against the feed's own constraints, not the device, so a
/// resized desktop window or a split-screen tablet reflows correctly.
const double _wideLayoutMinWidth = 720;

/// Cards stop growing past this width; wider viewports gain columns instead.
const double _maxCardWidth = 520;

/// Height of a grid tile. Card content is bounded (the title and excerpt are
/// both capped), so a fixed extent is enough for every card to fit.
const double _gridTileExtent = 460;

/// Feed tab: a searchable, tag-filterable list of blog posts.
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounce;
  bool _isSearching = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// Waits for a pause in typing so each keystroke doesn't fire a fetch.
  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) context.read<FeedViewModel>().search(value);
    });
  }

  void _toggleSearch() {
    setState(() => _isSearching = !_isSearching);
    if (_isSearching) {
      _searchFocusNode.requestFocus();
      return;
    }
    _debounce?.cancel();
    _searchController.clear();
    context.read<FeedViewModel>().search('');
  }

  void _clearFilters() {
    _debounce?.cancel();
    _searchController.clear();
    setState(() => _isSearching = false);
    context.read<FeedViewModel>().clearFilters();
  }

  Future<void> _refresh() async {
    final viewModel = context.read<FeedViewModel>();
    await viewModel.refresh();
    if (!mounted) return;

    // The stale posts stayed on screen, so the failure needs its own channel.
    final message = viewModel.errorMessage;
    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<FeedViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: _onQueryChanged,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  filled: false,
                  border: InputBorder.none,
                  hintText: 'Search posts…',
                ),
              )
            : const Text('InkFlow'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            tooltip: _isSearching ? 'Close search' : 'Search',
            onPressed: _toggleSearch,
          ),
          const _ThemeToggle(),
        ],
        bottom: viewModel.allTags.isEmpty
            ? null
            : _TagFilterBar(
                tags: viewModel.allTags,
                activeTag: viewModel.activeTag,
                onSelected: viewModel.selectTag,
              ),
      ),
      body: switch (viewModel.status) {
        FeedStatus.loading => const Center(child: CircularProgressIndicator()),
        FeedStatus.error => _ErrorView(
            message: viewModel.errorMessage ?? "Couldn't load the feed.",
            onRetry: viewModel.load,
          ),
        FeedStatus.ready => RefreshIndicator(
            onRefresh: _refresh,
            child: viewModel.isEmpty
                ? _EmptyView(
                    hasFilters: viewModel.hasFilters,
                    onClearFilters: _clearFilters,
                  )
                : _PostList(posts: viewModel.posts),
          ),
      },
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ThemeController>();
    final isDark = controller.isDark(context);

    return IconButton(
      key: const ValueKey('theme-toggle'),
      icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
      tooltip: isDark ? 'Switch to light theme' : 'Switch to dark theme',
      onPressed: () => controller.toggle(context),
    );
  }
}

/// Switches between one column and a max-extent grid based on available width.
class _PostList extends StatelessWidget {
  const _PostList({required this.posts});

  final List<Post> posts;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= _wideLayoutMinWidth) {
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: posts.length,
            itemBuilder: (context, index) => _PostCard(post: posts[index]),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: _maxCardWidth,
            mainAxisExtent: _gridTileExtent,
          ),
          itemCount: posts.length,
          // Tiles are a fixed height, so the card fills them and pins its
          // footer to the bottom rather than floating mid-tile.
          itemBuilder: (context, index) =>
              _PostCard(post: posts[index], fillHeight: true),
        );
      },
    );
  }
}

class _TagFilterBar extends StatelessWidget implements PreferredSizeWidget {
  const _TagFilterBar({
    required this.tags,
    required this.activeTag,
    required this.onSelected,
  });

  final List<String> tags;
  final String? activeTag;
  final ValueChanged<String> onSelected;

  @override
  Size get preferredSize => const Size.fromHeight(52);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: preferredSize.height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: tags.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final tag = tags[index];
          return FilterChip(
            label: Text('#$tag'),
            selected: tag == activeTag,
            onSelected: (_) => onSelected(tag),
          );
        },
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post, this.fillHeight = false});

  final Post post;

  /// Whether the card is in a height-bounded slot (a grid tile).
  final bool fillHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final coverUrl = post.coverImageUrl;

    final excerpt = Text(
      post.excerpt,
      style: theme.textTheme.bodyMedium
          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );

    final content = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _AuthorLine(post: post),
          const SizedBox(height: 12),
          Text(
            post.title,
            style: theme.textTheme.titleLarge,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          // In a grid the excerpt absorbs the tile's slack so the footer sits
          // at the bottom edge of every card. A list child has an unbounded
          // height, where Expanded would assert.
          if (fillHeight)
            Expanded(
              child: Align(alignment: Alignment.topLeft, child: excerpt),
            )
          else
            excerpt,
          const SizedBox(height: 12),
          if (post.tags.isNotEmpty) ...[
            _TagRow(tags: post.tags),
            const SizedBox(height: 12),
          ],
          _PostCardFooter(post: post),
        ],
      ),
    );

    return Card(
      child: InkWell(
        onTap: () => context.push('/post/${post.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (coverUrl != null)
              SizedBox(
                height: 140,
                width: double.infinity,
                child: _CoverImage(url: coverUrl),
              ),
            if (fillHeight) Expanded(child: content) else content,
          ],
        ),
      ),
    );
  }
}

class _CoverImage extends StatelessWidget {
  const _CoverImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    // Tonal surface rather than a hardcoded black wash, which washed out the
    // card in dark mode.
    final placeholderColor = Theme.of(context).colorScheme.surfaceContainerHighest;
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (context, url) => ColoredBox(color: placeholderColor),
      errorWidget: (context, url, error) => ColoredBox(
        color: placeholderColor,
        child: Icon(
          Icons.image_not_supported_outlined,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _AuthorLine extends StatelessWidget {
  const _AuthorLine({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        AuthorAvatar(author: post.author),
        const SizedBox(width: 10),
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
                post.shortDate,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TagRow extends StatelessWidget {
  const _TagRow({required this.tags});

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        for (final tag in tags.take(2))
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '#$tag',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.onSecondaryContainer),
              ),
            ),
          ),
      ],
    );
  }
}

class _PostCardFooter extends StatelessWidget {
  const _PostCardFooter({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Row(
      children: [
        IconButton(
          key: ValueKey('like-button-${post.id}'),
          onPressed: () => context.read<FeedViewModel>().toggleLike(post.id),
          tooltip: post.likedByMe ? 'Unlike' : 'Like',
          iconSize: 20,
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          icon: Icon(
            post.likedByMe ? Icons.favorite : Icons.favorite_border,
            color: post.likedByMe ? theme.colorScheme.primary : muted,
          ),
        ),
        Text('${post.likeCount}', style: theme.textTheme.labelMedium),
        const SizedBox(width: 16),
        Icon(Icons.mode_comment_outlined, size: 18, color: muted),
        const SizedBox(width: 6),
        Text('${post.commentCount}', style: theme.textTheme.labelMedium),
        const Spacer(),
        Flexible(
          child: Text(
            '${post.readMinutes} min read',
            style: theme.textTheme.labelMedium?.copyWith(color: muted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
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
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
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

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.hasFilters, required this.onClearFilters});

  final bool hasFilters;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      // Keeps the pull-to-refresh gesture alive on a screen with no content.
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 96),
      children: [
        Icon(Icons.article_outlined,
            size: 48, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(height: 16),
        Text(
          hasFilters ? 'No posts match your filters' : 'No posts yet',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          hasFilters
              ? 'Try a different tag or search term.'
              : 'Posts you publish will show up here.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        if (hasFilters) ...[
          const SizedBox(height: 24),
          Center(
            child: OutlinedButton(
              onPressed: onClearFilters,
              child: const Text('Clear filters'),
            ),
          ),
        ],
      ],
    );
  }
}
