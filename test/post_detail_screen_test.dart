// Covers the post detail screen against the seeded MockPostRepository.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:inkflow/data/repositories/post_repository.dart';
import 'package:inkflow/ui/features/post_detail/view_models/post_detail_view_model.dart';
import 'package:inkflow/ui/features/post_detail/views/post_detail_screen.dart';

/// Comfortably longer than the repository's simulated 250–500ms latency.
const Duration _pastLatency = Duration(seconds: 1);

Widget _harness(String postId) {
  return ChangeNotifierProvider(
    create: (_) => PostDetailViewModel(MockPostRepository(), postId),
    child: MaterialApp(home: const PostDetailScreen()),
  );
}

/// The screen loads the post and then its comments, each with its own latency.
///
/// The article lives in a `ListView`, which only builds the children inside its
/// viewport -- so the surface is made tall enough that the comments and the
/// composer below the fold are built and findable.
Future<void> _pumpLoaded(WidgetTester tester, String postId) async {
  tester.view.physicalSize = const Size(800, 2600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(_harness(postId));
  await tester.pump(_pastLatency);
  await tester.pump(_pastLatency);
  await tester.pump();
}

void main() {
  testWidgets('renders the post title and its seeded comments',
      (WidgetTester tester) async {
    await _pumpLoaded(tester, '1');

    // Exactly once: the body's leading H1 repeats the title and is dropped.
    expect(find.text('Designing with Material 3'), findsOneWidget);
    expect(find.text('Comments (2)'), findsOneWidget);

    expect(
      find.text('The tonal surface guidance finally made elevation click for me.'),
      findsOneWidget,
    );
    expect(
      find.text('Dynamic color on Android 12+ is such a nice touch.'),
      findsOneWidget,
    );
    expect(find.text('Grace Hopper'), findsOneWidget);
  });

  testWidgets('adding a comment appends it to the list',
      (WidgetTester tester) async {
    await _pumpLoaded(tester, '1');

    await tester.enterText(find.byType(TextField), 'Great write-up!');

    // The composer sits below the article, so scroll it into view to tap it.
    final sendButton = find.byKey(const ValueKey('send-comment-button'));
    await tester.ensureVisible(sendButton);
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(sendButton);
    await tester.pump();

    // The button is disabled and shows a spinner while the comment is in flight.
    expect(
      tester.widget<IconButton>(sendButton).onPressed,
      isNull,
      reason: 'send button should be disabled while sending',
    );

    await tester.pump(_pastLatency);

    expect(find.text('Great write-up!'), findsOneWidget);
    expect(find.text('Comments (3)'), findsOneWidget);
    expect(tester.widget<IconButton>(sendButton).onPressed, isNotNull);
  });

  testWidgets('a missing post renders the not-found state',
      (WidgetTester tester) async {
    await _pumpLoaded(tester, 'does-not-exist');

    expect(find.text('Post not found'), findsOneWidget);
  });
}
