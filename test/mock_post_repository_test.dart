import 'package:flutter_test/flutter_test.dart';

import 'package:inkflow/data/repositories/post_repository.dart';

void main() {
  group('MockPostRepository', () {
    late PostRepository repo;

    setUp(() => repo = MockPostRepository());

    test('fetchFeed returns posts sorted newest-first', () async {
      final feed = await repo.fetchFeed();

      expect(feed, isNotEmpty);
      for (var i = 0; i < feed.length - 1; i++) {
        expect(
          feed[i].createdAt.isBefore(feed[i + 1].createdAt),
          isFalse,
          reason: 'feed[$i] should not be older than feed[${i + 1}]',
        );
      }
    });

    test('fetchFeed filters by tag', () async {
      final tagged = await repo.fetchFeed(tag: 'provider');

      expect(tagged, isNotEmpty);
      expect(
        tagged.every((p) => p.tags.contains('provider')),
        isTrue,
      );
    });

    test('toggleLike flips likedByMe and adjusts likeCount', () async {
      final before = (await repo.fetchFeed()).first;

      final liked = await repo.toggleLike(before.id);
      expect(liked.likedByMe, !before.likedByMe);
      expect(liked.likeCount, before.likeCount + (before.likedByMe ? -1 : 1));

      // Toggling again restores the original state.
      final reverted = await repo.toggleLike(before.id);
      expect(reverted.likedByMe, before.likedByMe);
      expect(reverted.likeCount, before.likeCount);
    });

    test('addComment increments commentCount and appears in fetchComments',
        () async {
      final post = (await repo.fetchFeed()).first;
      final beforeCount = post.commentCount;
      final beforeComments = await repo.fetchComments(post.id);

      final comment = await repo.addComment(post.id, 'Great write-up!');
      expect(comment.text, 'Great write-up!');
      expect(comment.postId, post.id);

      final after = await repo.fetchPost(post.id);
      expect(after, isNotNull);
      expect(after!.commentCount, beforeCount + 1);

      final afterComments = await repo.fetchComments(post.id);
      expect(afterComments.length, beforeComments.length + 1);
      expect(afterComments.map((c) => c.id), contains(comment.id));
    });

    test('createPost inserts a retrievable post at the top of the feed',
        () async {
      final created = await repo.createPost(
        title: 'My brand new post',
        body: '# Hello\n\nFirst post!',
        tags: ['intro'],
      );

      final feed = await repo.fetchFeed();
      expect(feed.first.id, created.id);

      final fetched = await repo.fetchPost(created.id);
      expect(fetched, isNotNull);
      expect(fetched!.title, 'My brand new post');
      expect(fetched.tags, ['intro']);
    });
  });
}
