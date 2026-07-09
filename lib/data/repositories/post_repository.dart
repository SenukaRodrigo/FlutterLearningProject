import 'dart:math';

import '../../domain/models/post.dart';

/// Contract for reading and mutating blog posts and their comments.
///
/// The UI depends only on this abstraction; swap [MockPostRepository] for a
/// Firestore-backed implementation without touching the presentation layer.
abstract class PostRepository {
  /// Posts for the feed, newest first. Optionally filtered by [tag] and/or a
  /// free-text [query] matched against the title and body.
  Future<List<Post>> fetchFeed({String? tag, String? query});

  /// A single post by [id], or `null` if it does not exist.
  Future<Post?> fetchPost(String id);

  /// Comments for [postId], oldest first.
  Future<List<Comment>> fetchComments(String postId);

  /// Toggles the current user's like on [id] and returns the updated post.
  Future<Post> toggleLike(String id);

  /// Adds [text] as a comment on [postId] and returns the created comment.
  Future<Comment> addComment(String postId, String text);

  /// Creates a new post authored by the current user and returns it.
  Future<Post> createPost({
    required String title,
    required String body,
    List<String> tags,
  });
}

/// In-memory [PostRepository] with seeded data and simulated network latency.
///
/// State lives in memory for the lifetime of the instance: likes, comments, and
/// newly created posts persist across calls but reset when the app restarts.
class MockPostRepository implements PostRepository {
  MockPostRepository() {
    _comments = {
      '1': [
        Comment(
          id: 'c1',
          postId: '1',
          author: _grace,
          text: 'The tonal surface guidance finally made elevation click for me.',
          createdAt: DateTime(2026, 6, 29, 9, 12),
        ),
        Comment(
          id: 'c2',
          postId: '1',
          author: _linus,
          text: 'Dynamic color on Android 12+ is such a nice touch.',
          createdAt: DateTime(2026, 6, 30, 14, 3),
        ),
      ],
      '2': [
        Comment(
          id: 'c3',
          postId: '2',
          author: _ada,
          text: 'StatefulShellRoute saved me from a pile of nav bugs.',
          createdAt: DateTime(2026, 7, 3, 8, 45),
        ),
      ],
      '4': [
        Comment(
          id: 'c4',
          postId: '4',
          author: _margaret,
          text: 'Selector<T> is underrated for avoiding rebuilds.',
          createdAt: DateTime(2026, 7, 5, 19, 20),
        ),
        Comment(
          id: 'c5',
          postId: '4',
          author: _grace,
          text: 'Nice, been meaning to compare this with Riverpod.',
          createdAt: DateTime(2026, 7, 6, 7, 10),
        ),
      ],
    };

    // Intentionally not in chronological order so fetchFeed's sort is exercised.
    _posts = [
      Post(
        id: '2',
        title: 'A gentle intro to go_router',
        body: '# A gentle intro to go_router\n\n'
            'Declarative routing maps URLs to screens, which makes deep linking '
            'and the browser back button just work.\n\n'
            '## Why a StatefulShellRoute?\n\n'
            'It preserves the navigation state of each tab, so switching between '
            'Feed and Profile never loses your place.',
        author: _grace,
        tags: const ['flutter', 'navigation', 'go_router'],
        coverImageUrl: 'https://picsum.photos/seed/inkflow-router/800/400',
        createdAt: DateTime(2026, 7, 2, 10, 30),
        likeCount: 34,
        commentCount: 1,
        likedByMe: true,
      ),
      Post(
        id: '1',
        title: 'Designing with Material 3',
        body: '# Designing with Material 3\n\n'
            'Material 3 leans on **dynamic color** and tonal surfaces to create '
            'depth without heavy shadows.\n\n'
            '## Key ideas\n\n'
            '- Seed a full palette from a single color\n'
            '- Use surface containers for elevation\n'
            '- Keep shapes soft and consistent\n\n'
            '> Good design is as little design as possible.',
        author: _ada,
        tags: const ['flutter', 'design', 'material3'],
        coverImageUrl: 'https://picsum.photos/seed/inkflow-m3/800/400',
        createdAt: DateTime(2026, 6, 28, 16, 0),
        likeCount: 58,
        commentCount: 2,
        likedByMe: false,
      ),
      Post(
        id: '4',
        title: 'State management with Provider',
        body: '# State management with Provider\n\n'
            'Provider keeps state management approachable: expose a '
            '`ChangeNotifier`, then read or watch it from the widget tree.\n\n'
            '```dart\n'
            'final vm = context.watch<FeedViewModel>();\n'
            '```\n\n'
            'Use `context.read` for one-off actions and `context.watch` (or a '
            '`Selector`) when the widget should rebuild on change.',
        author: _margaret,
        tags: const ['flutter', 'state-management', 'provider'],
        coverImageUrl: 'https://picsum.photos/seed/inkflow-provider/800/400',
        createdAt: DateTime(2026, 7, 5, 11, 15),
        likeCount: 21,
        commentCount: 2,
        likedByMe: false,
      ),
      Post(
        id: '3',
        title: 'Writing in Markdown',
        body: '# Writing in Markdown\n\n'
            'Markdown keeps the writing experience focused on *content*, not '
            'formatting toolbars.\n\n'
            '```dart\n'
            "MarkdownBody(data: post.body);\n"
            '```\n\n'
            'That single widget turns your prose into a beautiful article.',
        author: _alan,
        tags: const ['writing', 'markdown'],
        coverImageUrl: 'https://picsum.photos/seed/inkflow-md/800/400',
        createdAt: DateTime(2026, 7, 6, 20, 5),
        likeCount: 12,
        commentCount: 0,
        likedByMe: true,
      ),
      Post(
        id: '5',
        title: 'Testing Flutter apps with confidence',
        body: '# Testing Flutter apps with confidence\n\n'
            'A healthy suite mixes three layers:\n\n'
            '1. **Unit tests** for pure logic and repositories\n'
            '2. **Widget tests** for individual screens\n'
            '3. **Integration tests** for full user flows\n\n'
            'Fake your data layer behind an interface and most of your app '
            'becomes trivially testable.',
        author: _grace,
        tags: const ['flutter', 'testing'],
        coverImageUrl: null,
        createdAt: DateTime(2026, 7, 7, 9, 40),
        likeCount: 45,
        commentCount: 0,
        likedByMe: false,
      ),
      Post(
        id: '6',
        title: 'Shipping Flutter to the web',
        body: '# Shipping Flutter to the web\n\n'
            'The web target has matured: use `usePathUrlStrategy()` for clean '
            'URLs, lazy-load heavy routes, and prefer `CanvasKit` for '
            'pixel-perfect rendering.\n\n'
            'Measure with Lighthouse and keep your initial bundle lean.',
        author: _linus,
        tags: const ['flutter', 'web', 'performance'],
        coverImageUrl: 'https://picsum.photos/seed/inkflow-web/800/400',
        createdAt: DateTime(2026, 7, 8, 13, 25),
        likeCount: 27,
        commentCount: 0,
        likedByMe: false,
      ),
    ];
  }

  final Random _random = Random();
  late final List<Post> _posts;
  late final Map<String, List<Comment>> _comments;

  int _postSeq = 7;
  int _commentSeq = 6;

  // --- Seeded authors -------------------------------------------------------

  static const Author _ada = Author(
    id: 'u_ada',
    displayName: 'Ada Lovelace',
    bio: 'Writing about design systems and the poetry of code.',
    avatarUrl: 'https://picsum.photos/seed/inkflow-ada/200/200',
  );
  static const Author _grace = Author(
    id: 'u_grace',
    displayName: 'Grace Hopper',
    bio: 'Compilers, navigation, and shipping software that lasts.',
    avatarUrl: 'https://picsum.photos/seed/inkflow-grace/200/200',
  );
  static const Author _alan = Author(
    id: 'u_alan',
    displayName: 'Alan Turing',
    bio: 'Thinking machines and thoughtful writing.',
    avatarUrl: 'https://picsum.photos/seed/inkflow-alan/200/200',
  );
  static const Author _margaret = Author(
    id: 'u_margaret',
    displayName: 'Margaret Hamilton',
    bio: 'State machines, reliability, and clean architecture.',
    avatarUrl: 'https://picsum.photos/seed/inkflow-margaret/200/200',
  );
  static const Author _linus = Author(
    id: 'u_linus',
    displayName: 'Linus Torvalds',
    bio: 'Performance nerd. Occasionally opinionated.',
    avatarUrl: 'https://picsum.photos/seed/inkflow-linus/200/200',
  );

  /// The signed-in user, used as the author for new posts and comments.
  static const Author _me = Author(
    id: 'u_me',
    displayName: 'Senuka Rodrigo',
    bio: 'Writing about Flutter, design, and the craft of shipping software.',
    avatarUrl: 'https://picsum.photos/seed/inkflow-avatar/200/200',
  );

  /// Simulated network latency of 250–500ms.
  Future<void> _delay() =>
      Future<void>.delayed(Duration(milliseconds: 250 + _random.nextInt(251)));

  @override
  Future<List<Post>> fetchFeed({String? tag, String? query}) async {
    await _delay();
    var result = [..._posts];

    if (tag != null && tag.trim().isNotEmpty) {
      final needle = tag.toLowerCase();
      result = result
          .where((p) => p.tags.any((t) => t.toLowerCase() == needle))
          .toList();
    }

    if (query != null && query.trim().isNotEmpty) {
      final q = query.toLowerCase();
      result = result
          .where((p) =>
              p.title.toLowerCase().contains(q) ||
              p.body.toLowerCase().contains(q))
          .toList();
    }

    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(result);
  }

  @override
  Future<Post?> fetchPost(String id) async {
    await _delay();
    for (final post in _posts) {
      if (post.id == id) return post;
    }
    return null;
  }

  @override
  Future<List<Comment>> fetchComments(String postId) async {
    await _delay();
    final list = _comments[postId] ?? const [];
    final sorted = [...list]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return List.unmodifiable(sorted);
  }

  @override
  Future<Post> toggleLike(String id) async {
    await _delay();
    final index = _posts.indexWhere((p) => p.id == id);
    if (index == -1) throw StateError('Post $id not found');

    final post = _posts[index];
    final updated = post.copyWith(
      likedByMe: !post.likedByMe,
      likeCount: post.likeCount + (post.likedByMe ? -1 : 1),
    );
    _posts[index] = updated;
    return updated;
  }

  @override
  Future<Comment> addComment(String postId, String text) async {
    await _delay();
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1) throw StateError('Post $postId not found');

    final comment = Comment(
      id: 'c${_commentSeq++}',
      postId: postId,
      author: _me,
      text: text,
      createdAt: DateTime.now(),
    );
    (_comments[postId] ??= []).add(comment);
    _posts[index] = _posts[index].copyWith(
      commentCount: _posts[index].commentCount + 1,
    );
    return comment;
  }

  @override
  Future<Post> createPost({
    required String title,
    required String body,
    List<String> tags = const [],
  }) async {
    await _delay();
    final post = Post(
      id: 'p${_postSeq++}',
      title: title,
      body: body,
      author: _me,
      tags: List.unmodifiable(tags),
      createdAt: DateTime.now(),
    );
    _posts.insert(0, post);
    return post;
  }
}
