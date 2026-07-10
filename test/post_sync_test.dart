// The feed holds its own snapshot of the posts, so changes made elsewhere
// reach it through the repository's postChanges broadcast rather than a
// re-fetch. Without this, liking a post and going back shows a stale count.

import 'package:flutter_test/flutter_test.dart';

import 'package:inkflow/data/repositories/post_repository.dart';
import 'package:inkflow/domain/models/post.dart';
import 'package:inkflow/ui/features/editor/view_models/editor_view_model.dart';
import 'package:inkflow/ui/features/feed/view_models/feed_view_model.dart';
import 'package:inkflow/ui/features/post_detail/view_models/post_detail_view_model.dart';

/// Outlasts the repository's simulated 250–500ms latency.
Future<void> _settle() => Future<void>.delayed(const Duration(seconds: 1));

/// The repository broadcasts changes on a microtask, so the feed's listener
/// runs just after the awaited call returns.
Future<void> _flush() => Future<void>.delayed(Duration.zero);

Post _postById(FeedViewModel feed, String id) =>
    feed.posts.firstWhere((post) => post.id == id);

void main() {
  late MockPostRepository repository;
  late FeedViewModel feed;

  setUp(() async {
    repository = MockPostRepository();
    feed = FeedViewModel(repository);
    await _settle();
  });

  tearDown(() {
    feed.dispose();
    repository.dispose();
  });

  test('liking a post on the detail screen updates the feed', () async {
    expect(_postById(feed, '6').likeCount, 27);
    expect(_postById(feed, '6').likedByMe, isFalse);

    final detail = PostDetailViewModel(repository, '6');
    await _settle();
    await detail.toggleLike();
    await _flush();

    expect(_postById(feed, '6').likeCount, 28);
    expect(_postById(feed, '6').likedByMe, isTrue);
  });

  test('commenting on the detail screen updates the feed comment count',
      () async {
    expect(_postById(feed, '6').commentCount, 0);

    final detail = PostDetailViewModel(repository, '6');
    await _settle();
    expect(await detail.addComment('Nice post'), isTrue);
    await _flush();

    expect(_postById(feed, '6').commentCount, 1);
  });

  test('publishing from the editor puts the post at the top of the feed',
      () async {
    expect(feed.posts, hasLength(6));

    final editor = EditorViewModel(repository)
      ..updateTitle('Fresh off the press')
      ..updateBody('Hello, world.');
    final post = await editor.publish();
    await _settle();

    expect(post, isNotNull);
    expect(feed.posts, hasLength(7));
    expect(feed.posts.first.id, post!.id);
    expect(feed.posts.first.title, 'Fresh off the press');
  });

  test('a filtered feed leaves placing a new post to the next fetch', () async {
    await feed.selectTag('testing');
    await _settle();
    final filteredLength = feed.posts.length;

    final editor = EditorViewModel(repository)
      ..updateTitle('Unrelated post')
      ..updateBody('Hello, world.');
    await editor.publish();
    await _settle();

    // It carries no 'testing' tag, so it must not appear in the filtered feed.
    expect(feed.posts, hasLength(filteredLength));
  });
}
