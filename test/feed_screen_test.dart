// Covers the feed screen against the seeded MockPostRepository: posts render
// once the load settles, and liking a post updates its count.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:inkflow/data/repositories/post_repository.dart';
import 'package:inkflow/ui/features/feed/view_models/feed_view_model.dart';
import 'package:inkflow/ui/features/feed/views/feed_screen.dart';

/// Comfortably longer than the repository's simulated 250–500ms latency.
const Duration _pastLatency = Duration(seconds: 1);

Widget _harness() {
  final repository = MockPostRepository();
  return MultiProvider(
    providers: [
      Provider<PostRepository>.value(value: repository),
      ChangeNotifierProvider<FeedViewModel>(
        create: (_) => FeedViewModel(repository),
      ),
    ],
    child: const MaterialApp(home: FeedScreen()),
  );
}

/// Renders the loaded feed into a viewport of exactly [size] logical pixels.
Future<void> _pumpLoadedFeedAt(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(_harness());
  await tester.pump(_pastLatency);
  await tester.pump();
}

void main() {
  testWidgets('feed shows seeded post titles after load',
      (WidgetTester tester) async {
    await tester.pumpWidget(_harness());

    // The feed starts in its loading state.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(_pastLatency);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);

    // Posts are sorted newest-first, so these two lead the feed.
    expect(find.text('Shipping Flutter to the web'), findsOneWidget);
    expect(find.text('Testing Flutter apps with confidence'), findsOneWidget);
  });

  testWidgets('tapping like updates the count', (WidgetTester tester) async {
    await tester.pumpWidget(_harness());
    await tester.pump(_pastLatency);
    await tester.pump();

    // Post 6 ("Shipping Flutter to the web") is seeded unliked with 27 likes.
    expect(find.text('27'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('like-button-6')));
    await tester.pump();

    // The optimistic update lands before the repository confirms.
    expect(find.text('28'), findsOneWidget);
    expect(find.text('27'), findsNothing);

    // ...and survives reconciliation with the repository's own count.
    await tester.pump(_pastLatency);
    expect(find.text('28'), findsOneWidget);
  });

  // A RenderFlex overflow raises a FlutterError during layout, which the
  // tester surfaces as a thrown exception -- so these double as a guard
  // against cards overflowing at either end of the breakpoint.
  testWidgets('phone width lays the feed out in a single column',
      (WidgetTester tester) async {
    await _pumpLoadedFeedAt(tester, const Size(390, 844));

    expect(find.byType(GridView), findsNothing);
    expect(find.text('Shipping Flutter to the web'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop width lays the feed out as a grid',
      (WidgetTester tester) async {
    await _pumpLoadedFeedAt(tester, const Size(1440, 900));

    expect(find.byType(GridView), findsOneWidget);
    expect(find.text('Shipping Flutter to the web'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
