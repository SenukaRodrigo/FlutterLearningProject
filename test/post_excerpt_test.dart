// Feed cards show the title and the excerpt together, so the excerpt must not
// simply repeat the body's leading H1.

import 'package:flutter_test/flutter_test.dart';

import 'package:inkflow/domain/models/post.dart';

const _author = Author(id: 'u1', displayName: 'Ada', bio: '');

Post _postWithBody(String body) => Post(
      id: '1',
      title: 'Designing with Material 3',
      body: body,
      author: _author,
      tags: const [],
      createdAt: DateTime(2026, 7, 8),
    );

void main() {
  test('a leading heading repeating the title is dropped', () {
    final post = _postWithBody(
      '# Designing with Material 3\n\nMaterial 3 leans on dynamic color.',
    );

    expect(post.bodyWithoutLeadingTitle, 'Material 3 leans on dynamic color.');
    expect(post.excerpt, 'Material 3 leans on dynamic color.');
  });

  test('a leading heading that is not the title is kept', () {
    final post = _postWithBody('## Why it matters\n\nBecause screens differ.');

    expect(post.bodyWithoutLeadingTitle, '## Why it matters\n\nBecause screens differ.');
    expect(post.excerpt, 'Why it matters Because screens differ.');
  });

  test('excerpt keeps body text when there is no leading heading', () {
    final post = _postWithBody('Material 3 leans on dynamic color.');

    expect(post.excerpt, 'Material 3 leans on dynamic color.');
  });

  test('excerpt truncates long bodies with an ellipsis', () {
    final post = _postWithBody('word ' * 100);

    expect(post.excerpt.length, lessThanOrEqualTo(141));
    expect(post.excerpt, endsWith('…'));
  });

  group('markdown stripping', () {
    test('inline code keeps its text and its identifier intact', () {
      final post = _postWithBody('Routing with `go_router` is declarative.');

      expect(post.excerpt, 'Routing with go_router is declarative.');
    });

    test('an intra-word underscore is not read as emphasis', () {
      final post = _postWithBody('Call use_path_url_strategy on startup.');

      expect(post.excerpt, 'Call use_path_url_strategy on startup.');
    });

    test('emphasis unwraps without stranding punctuation', () {
      final post = _postWithBody(
        'Focused on *content*, not **formatting toolbars**.',
      );

      expect(post.excerpt, 'Focused on content, not formatting toolbars.');
    });

    test('links keep their text and drop the target', () {
      final post = _postWithBody('Read the [Flutter docs](https://flutter.dev) first.');

      expect(post.excerpt, 'Read the Flutter docs first.');
    });

    test('images are dropped entirely', () {
      final post = _postWithBody('![a diagram](https://x.dev/a.png)\n\nThe layout.');

      expect(post.excerpt, 'The layout.');
    });

    test('fenced code blocks are dropped', () {
      final post = _postWithBody(
        'Use it like this:\n\n```dart\nfinal x = 1;\n```\n\nThat is all.',
      );

      expect(post.excerpt, 'Use it like this: That is all.');
    });

    test('list markers and blockquotes are stripped', () {
      final post = _postWithBody(
        '> Good design is little design.\n\n- First\n- Second\n1. Third',
      );

      expect(post.excerpt, 'Good design is little design. First Second Third');
    });
  });
}
