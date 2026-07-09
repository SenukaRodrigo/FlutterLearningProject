import '../../domain/models/post.dart';

/// Single source of truth for blog posts.
///
/// Backed by in-memory sample data for now. Swap this implementation for one
/// that calls a remote service/local database without touching the UI layer.
class PostRepository {
  final List<Post> _posts = [
    Post(
      id: '1',
      title: 'Designing with Material 3',
      author: 'Ada Lovelace',
      excerpt:
          'A tour of dynamic color, tonal surfaces, and how to make them feel '
          'at home on every platform.',
      body: '# Designing with Material 3\n\n'
          'Material 3 leans on **dynamic color** and tonal surfaces to create '
          'depth without heavy shadows.\n\n'
          '## Key ideas\n\n'
          '- Seed a full palette from a single color\n'
          '- Use surface containers for elevation\n'
          '- Keep shapes soft and consistent\n\n'
          '> Good design is as little design as possible.',
      coverImageUrl: 'https://picsum.photos/seed/inkflow-m3/800/400',
      publishedAt: DateTime(2026, 6, 28),
      readMinutes: 4,
    ),
    Post(
      id: '2',
      title: 'A gentle intro to go_router',
      author: 'Grace Hopper',
      excerpt:
          'Declarative navigation, deep links, and a bottom-nav shell that '
          'keeps its state across tabs.',
      body: '# A gentle intro to go_router\n\n'
          'Declarative routing maps URLs to screens, which makes deep linking '
          'and the browser back button just work.\n\n'
          '## Why a StatefulShellRoute?\n\n'
          'It preserves the navigation state of each tab, so switching between '
          'Feed and Profile never loses your place.',
      coverImageUrl: 'https://picsum.photos/seed/inkflow-router/800/400',
      publishedAt: DateTime(2026, 7, 2),
      readMinutes: 5,
    ),
    Post(
      id: '3',
      title: 'Writing in Markdown',
      author: 'Alan Turing',
      excerpt:
          'Why Markdown is the perfect format for a blog editor, and how '
          'Inkflow renders it.',
      body: '# Writing in Markdown\n\n'
          'Markdown keeps the writing experience focused on *content*, not '
          'formatting toolbars.\n\n'
          '```dart\n'
          "MarkdownBody(data: post.body);\n"
          '```\n\n'
          'That single widget turns your prose into a beautiful article.',
      coverImageUrl: 'https://picsum.photos/seed/inkflow-md/800/400',
      publishedAt: DateTime(2026, 7, 6),
      readMinutes: 3,
    ),
  ];

  /// Returns the posts that make up the feed, newest first.
  Future<List<Post>> fetchFeed() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final sorted = [..._posts]
      ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    return List.unmodifiable(sorted);
  }

  /// Returns a single post by id, or `null` if it does not exist.
  Future<Post?> fetchById(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    for (final post in _posts) {
      if (post.id == id) return post;
    }
    return null;
  }
}
