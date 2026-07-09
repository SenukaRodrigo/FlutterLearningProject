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
  test('excerpt drops a leading markdown heading', () {
    final post = _postWithBody(
      '# Designing with Material 3\n\nMaterial 3 leans on dynamic color.',
    );

    expect(post.excerpt, 'Material 3 leans on dynamic color.');
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
}
